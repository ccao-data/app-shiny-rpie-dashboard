# TEMPLATE DOCKERFILE FOR CCAO SHINY APPS

# This Dockerfile serves as a minimal template for CCAO shiny applications
# It is used in conjunction with .gitlab-ci.yml to create Docker images
# which are stored in CCAO's GitLab container registry and later deployed to
# shinyproxy. The build here has five general steps:

# 1) SETUP. Create the necessary folders and permissions to run the app
# 2) DEPENDENCIES. Install linux backend libraries needed by certain R libs
# 3) R PACKAGE INSTALL. Download the R packages needed by the application
# 4) COPY CODE. Copy the source code of the app into the appropriate folder(s)
# 5) LABELLING. Create metadata for the container image

# The order of these steps is VERY important for efficient build times
# To avoid "cache busting" or the need to rebuild the entire image, you want
# to order things from least to change (at the top of the script) to most
# like to change (at the bottom of the script)


### SETUP ###

# Use the shiny image as a base
FROM rocker/shiny-verse:4.0.2

# Arguments that get passed to apt to install linux dependencies. Formatted as
# strings with libraries separated by a space. If an app is missing linux
# dependencies, add them to EXTRA_APT_DEPS. APT_DEPS lists the dependencies for
# all database-connected shiny apps
ARG APT_DEPS="libcairo2-dev libcurl4-gnutls-dev libssl-dev libxt-dev tar tdsodbc unixodbc unixodbc-dev wget"
ARG EXTRA_APT_DEPS="libudunits2-dev gdal-bin libgdal-dev"

# Create and set the default working dir for our application. This is where
# code will live and execute from
WORKDIR /app/

# Declare port 3838 as the port for inbound connections to shiny
EXPOSE 3838

# Set the command that runs at startup. This tells our app to run app.R
# when the container is launched
CMD ["Rscript", "--no-environ", "-e", "rmarkdown::run('dashboard.Rmd')"]


### DEPENDENCIES ###

# Install R linux dependencies and utilities. These are needed by some common
# R libraries as backends. You may have to add to this list if certain packages
# require linux libraries (for example, the R package sf requires libgdal-dev)
RUN apt-get update && apt-get install --no-install-recommends -y \
    $(echo $APT_DEPS) \
    $(echo $EXTRA_APT_DEPS) \
    && apt-get clean && apt-get autoremove --purge -y \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Install ODBC drivers for MS SQL. These are used to establish a connection
# to CCAO's existing SQL server
RUN wget --no-verbose https://packages.microsoft.com/debian/9/prod/pool/main/m/msodbcsql17/msodbcsql17_17.4.2.1-1_amd64.deb -O /tmp/msodbc.deb \
    && ACCEPT_EULA=Y apt-get install /tmp/msodbc.deb


### R PACKAGE INSTALL ###

# Copy ONLY the files needed to install dependencies, since these are unlikely
# to change. Copying all of our files would bust the cache if we had updated
# any of our code. Cache will bust when renv.lock (the package manifest) is
# altered, meaning adding new packages requires a full cache rebuild
COPY .Rprofile renv.lock /app/
COPY renv/activate.R /app/renv/activate.R

# Set arrow package build arg to enable snappy compression
ARG ARROW_WITH_SNAPPY=ON

# Install R packages necessary for the reporting scripts
# The renv package is used to version lock to specific R packages
# renv.lock contains a list of all packages needed to run the application,
# and it will install all these packages by running the command renv::restore()
RUN R -e 'renv::restore()'


### COPY CODE ###

# Copy configuration files from our repo to their expected locations. These
# files point ODBC to the correct drivers and ensure that Shiny starts on
# port 3838, respectively.
COPY config/odbcinst.ini /etc/
COPY config/Rprofile.site /usr/local/lib/R/etc/

# Copy default version of Ubuntu 20.04 OpenSSL1.1 conf file with downgraded
# default TLS options. This enables connection to our (old) SQL server, since
# we don't have the ability to upgrade the certificates
# https://askubuntu.com/questions/1233186/ubuntu-20-04-how-to-set-lower-ssl-security-level#
COPY config/openssl.cnf /etc/ssl/openssl.cnf

# Copy all files and subdirectories from our repository into the folder /app/
# This command ignores the files listed in .dockerignore
COPY --chown=shiny:shiny . /app/


### LABELLING ###

# Build arguments used to label the container, these variables are predefined
# as part of GitLab. They get passed to the container as build-args in the
# .gitlab-ci.yml file. These arguments only exist when building the container
ARG VCS_NAME
ARG VCS_URL
ARG VCS_REF
ARG VCS_REF_SHORT
ARG VCS_VER
ARG VCS_ID
ARG VCS_NAMESPACE

# Environmental variables that are passed to the container. These variables
# exist inside each app and can be called from R. They are used to create a
# version number in the application UI as well as link to the GitLab
# Service Desk
ENV VCS_NAME=$VCS_NAME
ENV VCS_URL=$VCS_URL
ENV VCS_REF=$VCS_REF
ENV VCS_REF_SHORT=$VCS_REF_SHORT
ENV VCS_VER=$VCS_VER
ENV VCS_ID=$VCS_ID
ENV VCS_NAMESPACE=$VCS_NAMESPACE

# Create labels for the container. These are standardized labels defined by
# label-schema.org. Many applications look for these labels in order to display
# information about a container
LABEL maintainer "Dan Snow <dsnow@cookcountyassessor.com>"
LABEL com.centurylinklabs.watchtower.enable="true"
LABEL org.opencontainers.image.title=$VCS_NAME
LABEL org.opencontainers.image.source=$VCS_URL
LABEL org.opencontainers.image.revision=$VCS_REF
LABEL org.opencontainers.image.version=$VCS_VER
