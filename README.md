# RPIE Dashboard V2

The RPIE Dashboard was designed to allow CCAO Analysts to consume aggregate data from the RPIE database. Users can filter the data based on geographic boundaries, types of spaces (commercial/residential), and qualities such as free rent and owner occupancy. This data is then able to be downloaded in multiple Excel-friendly formats for further analysis.

## Project Goal

Because RPIE data is still being collected, gaining insights about the quality, quantity, and validity of the data is going to be crucial in determining how to utilize it. This dashboard tool provides a general overview of the data for developing insights.

## How Does it Work?

Users can interact with the map using traditional methods: Click and drag with the mouse to move around the map, scroll or use the on screen interface to zoom in and out, and click on points to view more detailed information about a specific PIN. The tabs below the map can be clicked on to view summary tables or interactive plots for the specified variables. The `Data Table` tab allows the user to view the tabular data displayed in the `Map` tab and download it using the buttons on the top left.

### The Sidebar

All sidebar inputs allow for multiple selections. For example, if the user wants to filter the data down to buildings outside of the city triad they simply need to select "North" and "South" in the triad filter, leaving out "City". The "Types of Spaces" dropdown allows only one value.

The sidebar provides inputs for filtering data. The neighborhood input is responsive to the filtered township. By default it shows all neighborhood codes in the displayed data, and when a township is selected in the input above it shows only neighborhood codes within that township (or townships).

### The Map

When the "Type of Spaces" dropdown is set to "All", the colors of the point values on the map represent the major class of the PINs beneath that building. When "Commercial" or "Residential" are selected, the points are colored based on which quartile they fall into on the distribution of rent per square foot for the selected type of space.

In the RPIE database buildings can be comprised of one or more PINs. Summary statistics and plots in the `Map` tab were written to ensure accuracy by removing duplicate Building entries before calculation.

By providing the downloadable data at the PIN level, analysts will be able to combine RPIE data with other PIN-level data. If, however, there is a need to download building-level information the user can filter out duplicate building values and download the resulting data in the `Data Table` tab. Please note that doing so will remove information about which classes of PINs comprise the building.

Clicking on a point on the map will show a pop-up above the point detailing selected characteristics about the PIN and building. If a value is NA, that means that the data was not provided or is not available for that specific value.

### Visualizations and Tables

Below the map is a set of tabs providing summaries and visualizations of the filtered data. By default a summary table is displayed for expense ratio, rent, and vacancy values. The `Rents` tab displays a series of box plots of residential rents organized by bedroom size. `Expense Ratio` contains a histogram of values, and `Leases` contains a histogram of lease start dates organized by the type of space. All plotted values remove the top and bottom 5% of values to remove outliers.

Hovering the mouse over an element of any of the plots will provide relevant information. For box plots the summary values will be displayed, and when points are hovered it will show an individual rent value. Histograms provide counts for the selected column, though this functionality isn't mirrored in the `Leases` plot.

### Data Table

Depending on the number of rows being loaded, the `Data Table` tab may take a few moments to load. The table displays all columns and rows present in the filtered data. If there are no filters applied, all data from the server will be loaded. The user is able to download the data in multiple formats: copying to their clipboard using "Copy", as a `csv` file using "CSV", and as an `xlsx` file using "Excel". If the user is looking for a specific value within the data they can use the search  input at the top right of the panel.

## Further Development

This project requires access to both the CCAODATA and RPIE SQL servers. You can access the via the CCAO VPN or by using an office computer. Without access you will be unable to download the underlying data and therefore unable to see how changes to the code are reflected in the resulting dashboard.

Some functionalities within this dashboard were inspired by Kyle Walker's [Neighborhood Diversity Dashboard](https://walkerke.shinyapps.io/neighborhood_diversity/). In the future, including interactions between the plots and the maps that allow the user to select points on the map and have their location reflected on the map would provide stronger insights into the data.

The filters can be made to interact with eachother, similar to how the neighborhood filter is responsive to the townships filter.

The code for the dashboard was written entirely in R, and the comments should provide insight to anyone interested in continuing development on this dashboard. The dashboard was built using [flexdashboard](https://pkgs.rstudio.com/flexdashboard/), a shiny framework that allows for quick dashboard development in R. The map was created using [leaflet](https://rstudio.github.io/leaflet/), and the tables were created using [kable](https://cran.r-project.org/web/packages/kableExtra/vignettes/awesome_table_in_html.html) for the `Map` page and [DT](https://rstudio.github.io/DT/) for the `Data Table` page. Plots were made interactive using [plotly](https://plotly.com/r/).
