# a function to clean address from PROPLOCS
# it expects address fields from PROPLOCS to start with PL_
address_clean <- function(x) {

  x <- x %>%
  unite(address, contains("PL_"), sep = " ") %>%

    mutate(address = trimws(
      str_to_title(
        gsub("\\s+", " ", address)
      )
    )) %>%

    mutate(address = gsub("Mcc", "McC", address))

  return(x)

}

# This function is used to find outliers for a given vector
purge_outliers <- function(x, probs = c(.25, .75)) {

  q <- quantile(x, probs = probs, na.rm = T)

  iqr <- IQR(x, na.rm = TRUE)

  limits <- c(q[1] - 1.5 * iqr, q[2] + 1.5 * iqr)

  return(

    replace(x, !dplyr::between(x, limits[1], limits[2]), NA)

    )

}

# raw data needs to be cleaned before it's useful for the analysts to work with
# this function makes a lot of assumptions as to what the data it's given will look like
# and so will need to be adjusted as the report is adjusted
clean_for_output <- function(x) {

  return(

    x %>%
      rename("PIN(s)" = PIN,
             "RPIE Reporting Year" = TaxYear,
             "Project Name" = ProjectName,
             "Filing Name" = FilingName,
             "Submitted Date" = SubmittedDate,
             "User Email" = UserEmail,
             "Building Type" = BuildingTypeCode,
             "Ramp Up Date" = RampUpDate,
             "Entire Building Owned" = IsEntirelyOwned,
             "Building Contains All PINs" = ContainsAllPins,
             "Number of Stories" = NumberStories,
             "Number of Elevators" = NumberElevators,
             "Exterior Walls" = BuildingWallTypeCode,
             "Roof" = BuildingRoofTypeCode,
             "Year Built" = YearBuilt,
             "Effective Age" = EffectiveAge,
             "Residential Units" = ResidentialUnitCount,
             "Commercial Units" = CommercialUnitCount,
             "Total Parking Spaces" = TotalParkingCount,
             "Guest Parking Spaces" = GuestParkingCount,
             "Storage Units" = StorageUnitCount,
             "Not Generating Income" = GenerateNoIncome,
             "Vacant Due to Covid" = CovidVacant,
             "Schedule E" = ScheduleE,
             "Expense Type" = ExpenseType,
             "Expense Ratio" = ExpenseRatio,
             "Income - Schedule E" = IncomeScheduleE,
             "Income - 8825" = Income8825,
             "Any Residential Units Owner Occupied" = ResOwnerOccupied,
             "Garden Units" = GardenUnits,
             "Residential Free Rent" = ResidentialFreeRent,
             "LIHTC Affordable/Subsidized Units" = AffordableUnits_LIHTC,
             "Project-based Affordable/Subsidized Units" = AffordableUnits_PB,
             "Residential Rental Income" = ResidentialRentalIncome,
             "Residential Vacancies" = ResidentialVacancies,
             "Residential Months Vacant Last Year" = ResidentialMonthsVacantLastYear,
             "Residential SQFT" = ResidentialSquareFeet,
             "Total Bedrooms" = TotalBedrooms,
             "Total Bathrooms" = TotalBathrooms,
             "Total Rooms" = TotalRooms,
             "Monthly Residential Rent/SQFT" = ResidentialRentPerSquareFoot,
             "Avg. Studio Rent" = StudioRent,
             "Avg. One Bedroom Rent" = Bedroom1Rent,
             "Avg. Two Bedroom Rent" = Bedroom2Rent,
             "Avg. Three Bedroom Rent" = Bedroom3Rent,
             "Avg. Four+ Bedroom Rent" = Bedroom4Rent,
             "Most Recent Residential Lease" = MostRecentResidentialLease,
             "Any Commercial Units Owner Occupied" = ComOwnerOccupied,
             "Commercial Vacancies" = CommercialVacancies,
             "Commercial Months Vacant Last Year" = CommercialMonthsVacantLastYear,
             "Commercial SQFT" = CommercialSquareFeet,
             "Commercial Rental Income (As Entered)" = CommercialRentalIncome,
             "Yearly Commercial Rent/SQFT" = CommercialRentPerSquareFoot,
             "Commercial Free Rent" = CommercialFreeRent,
             "Taxes Paid" = TaxesPaid,
             "Use Description(s)" = UseDescriptions,
             "Business Type" = BusinessType,
             "Commercial Lease Type" = CommercialLeaseType,
             "Most Recent Commercial Lease" = MostRecentCommercialLease,
             "Township Code" = township_code,
             "Neighborhood" = neighborhood,
             "Class" = class,
             "Latitude" = lat,
             "Longitude" = long,
             "Municipality" = municipality,
             "Address" = address,
             "Zip" = zip,
             "Township Name" = township_name,
             "Tri" = triad_name) %>%

        select("BuildingId",
               "Project Name",
               "Filing Name",
               "Submitted Date",
               #"User Email",
               "RPIE Reporting Year",
               "PIN(s)",
               "Tri",
               "Township Code",
               "Township Name",
               "Neighborhood",
               "Class",
               "Use Description(s)",
               "Business Type",
               "Municipality",
               "Address",
               "Zip",
               "Building Type",
               "Ramp Up Date",
               "Year Built",
               "Effective Age",
               "Entire Building Owned",
               "Building Contains All PINs",
               "Number of Stories",
               "Number of Elevators",
               "Exterior Walls",
               "Roof",
               "Total Parking Spaces",
               "Guest Parking Spaces",
               "Storage Units",
               "Not Generating Income",
               "Vacant Due to Covid",
               "Expense Type",
               "Schedule E",
               "Total Gross Rents",
               "Total Expenses",
               "Income - Schedule E",
               "Income - 8825",
               "Expense Ratio",
               "Residential Units",
               "Any Residential Units Owner Occupied",
               "Garden Units",
               "Residential Free Rent",
               "LIHTC Affordable/Subsidized Units",
               "Project-based Affordable/Subsidized Units",
               "Residential Rental Income",
               "Residential Vacancies",
               "Residential Months Vacant Last Year",
               "Residential SQFT",
               "Monthly Residential Rent/SQFT",
               "Total Bedrooms",
               "Total Bathrooms",
               "Total Rooms",
               "Studio Units",
               "Avg. Studio Rent",
               "One Bedroom Units",
               "Avg. One Bedroom Rent",
               "Two Bedroom Units",
               "Avg. Two Bedroom Rent",
               "Three Bedroom Units",
               "Avg. Three Bedroom Rent",
               "Four+ Bedroom Units",
               "Avg. Four+ Bedroom Rent",
               "Most Recent Residential Lease",
               "Commercial Units",
               "Any Commercial Units Owner Occupied",
               "Commercial Vacancies",
               "Commercial Months Vacant Last Year",
               "Commercial SQFT",
               "Commercial Rental Income (As Entered)",
               "Yearly Commercial Rent/SQFT",
               "Commercial Free Rent",
               "Taxes Paid",
               "Commercial Lease Type",
               "Most Recent Commercial Lease") %>%
        mutate(
          `Building Type` = case_when(
            `Building Type` == 'DTCHD' ~ "Detached",
            `Building Type` == 'HGHRS' ~ "High-Rise",
            `Building Type` == 'MDRS' ~ "Mid-Rise",
            `Building Type` == 'PARKING' ~ "Parking Garage or Paved Lot",
            `Building Type` == 'RWTWNHS' ~ "Row or Townhouse",
            `Building Type` == 'VACANT' ~ "Vacant Lot"
        ),
        `Exterior Walls` = case_when(
          `Exterior Walls` == 1  ~ "Metal",
          `Exterior Walls` == 2  ~ "Metal Siding",
          `Exterior Walls` == 3  ~ "Glass Curtain Wall",
          `Exterior Walls` == 4  ~ "Stone Veneer Curtain Wall",
          `Exterior Walls` == 5  ~ "Brick",
          `Exterior Walls` == 6  ~ "Precast Concrete",
          `Exterior Walls` == 7  ~ "Concrete Block",
          `Exterior Walls` == 8  ~ "Wood Frame",
          `Exterior Walls` == 9  ~ "Wood Frame and Masonry",
          `Exterior Walls` == 10 ~ "Stucco"
        ),
        Roof = case_when(
          Roof == 1  ~ "Built-Up Roofing (BUR) Membrane",
          Roof == 2  ~ "Metal Roofing",
          Roof == 3  ~ "Modified Bitumen Roofing",
          Roof == 4  ~ "Thermoset (EPDM) Roof Membrane",
          Roof == 5  ~ "Thermoplastic (PVC & TPO) Roof Membrane",
          Roof == 6  ~ "Garden “Green” Roofing System",
          Roof == 7  ~ "Shingle/Asphalt",
          Roof == 8  ~ "Tar and Gravel",
          Roof == 9  ~ "Slate",
          Roof == 10 ~ "Shake",
          Roof == 11 ~ "Tile"
        ),
        across(
          c("Total Gross Rents",
            "Total Expenses",
            "Income - Schedule E",
            "Income - 8825",
            "Residential Rental Income",
            "Monthly Residential Rent/SQFT",
            "Avg. Studio Rent",
            "Avg. One Bedroom Rent",
            "Avg. Two Bedroom Rent",
            "Avg. Three Bedroom Rent",
            "Avg. Four+ Bedroom Rent",
            "Commercial Rental Income (As Entered)",
            "Yearly Commercial Rent/SQFT",
            "Taxes Paid"),
          scales::dollar))

  )

}

# raw data needs to be cleaned before it's useful for the analysts to work with
# this function makes a lot of assumptions as to what the data it's given will look like
# and so will need to be adjusted as the report is adjusted
clean_expenses <- function(x, type = "general") {

  x <- x %>%

    rename("PIN(s)" = PIN,
           "RPIE Reporting Year" = TaxYear,
           "Project Name" = ProjectName,
           "Township Code" = township_code,
           "Neighborhood" = neighborhood,
           "Class" = class,
           "Latitude" = lat,
           "Longitude" = long,
           "Municipality" = municipality,
           "Address" = address,
           "Zip" = zip,
           "Township Name" = township_name,
           "Tri" = triad_name,
           "Use Description(s)" = UseDescriptions)

  if (type == "general") {

    x <- x %>%

      filter(!is.na(IncomeExpenseGeneralId)) %>%

      select("BuildingId",
             "Project Name",
             "RPIE Reporting Year",
             "PIN(s)",
             "Tri",
             "Township Code",
             "Township Name",
             "Neighborhood",
             "Class",
             "Use Description(s)",
             "Municipality",
             "Address",
             "Zip",
             TotalExpenseNet:ExpensesOther5Desc) %>%

      mutate(across(TotalExpenseNet:ExpensesOther5Desc & !contains("Desc"), scales::dollar)) %>%

      rename("Total Expenses Net of Int and Dep" = TotalExpenseNet,
             "Total Gross Rental Revenues" = TotalRevenueGrossRental,
             "Gross Rental Revenues" = RevenueGrossRental,
             "Common Area Maintenance Revenues" = RevenueCommonAreas,
             "Parking" = RevenueParking,
             "Reimburseables" = RevenueReimbursables,
             "Concessions" = RevenueConcessions,
             "Revenues from other fees and chanrges" = RevenueMisc,
             "Number of server racks" = DataCenterServerRacks,
             "Smallest rentable rack fraction" = DataCenterRentableFraction,
             "Raised floor area (SF)" = DataCenterRaisedFloorArea,
             "Janitorial" = MaintenanceJanitorial,
             "Landscaping & snow removal" = MaintenanceLandscape,
             "Repairs and/or maintenance services" = MaintenanceRepairServices,
             "Supplies" = MaintenanceSupplies,
             "Security" = MaintenanceSecurity,
             "Maintenance SUBTOTAL" = MaintenanceTotal,
             "Management fees" = AdminManagementFees,
             "Commissions" = AdminCommisions,
             "Legal and other professional fees" = AdminLegalFees,
             "Marketing" = AdminMarketing,
             "All salaries and benefits" = AdminSalariesBenefits,
             "Other and contingency" = AdminOtherCont,
             "Administration SUBTOTAL" = AdminTotal,
             "Electric" = UtilElectric,
             "Heat" = UtilHeat,
             "Internet" = UtilInternet,
             "Garbage & waste disposal" = UtilGarbage,
             "Utilities & Sanitation Services SUBTOTAL" = UtilTotal,
             "Property Taxes" = FinancePropertyTaxes,
             "Insurance" = FinanceInsurance,
             "Replacement reserves" = FinanceReplacementRes,
             "Mortgage interest paid to banks" = FinanceMortInterest,
             "Other interest" = FinanceOtherInterest,
             "Depreciation expense or depletion" = FinanceDepreciationExpense,
             "Finance & Taxes SUBTOTAL" = FinanceTotal,
             "Other Expense 1" = ExpensesOther1Amount,
             "Other Expense 1 Name" = ExpensesOther1Desc,
             "Other Expense 2" = ExpensesOther2Amount,
             "NOther Expense 2 Name" = ExpensesOther2Desc,
             "Other Expense 3" = ExpensesOther3Amount,
             "Other Expense 3 Name" = ExpensesOther3Desc,
             "Other Expense 4" = ExpensesOther4Amount,
             "Other Expense 4 Name" = ExpensesOther4Desc,
             "Other Expense 5" = ExpensesOther5Amount,
             "Other Expense 5 Name" = ExpensesOther5Desc,)

  } else if (type == "hotel") {

    x <- x %>%

      filter(!is.na(IncomeExpenseHotelId))  %>%

      select("BuildingId",
             "RPIE Reporting Year",
             "PIN(s)",
             "Tri",
             "Township Code",
             "Township Name",
             "Neighborhood",
             "Class",
             "Use Description(s)",
             "Municipality",
             "Address",
             "Zip",
             HotelName:UtilSanitServicesTotal) %>%

      mutate(across(RevenuePerRoom:UtilSanitServicesTotal & !contains("Name"), scales::dollar)) %>%

      rename("Name of Hotel/Motel" = HotelName,
             "Operating Company" = CompanyName,
             "Number of rooms" = NumberOfRooms,
             "Occupancy Rate" = OccupancyRate,
             "Revenue Per Available Room" = RevenuePerRoom,
             "Average Daily Room Rate" = AverageDailyRoomRate,
             "Operating Expenses" = OperatingExpenses,
             "Guest Rooms" = GuestRooms,
             "Food and Beverage (Departmental)" = FoodAndBeverageDep,
             "Telecommunications" = Telecommunications,
             "Other Expenses" = OtherExpenses,
             "Total Departmental Expenses" = TotalDepartamentalExpenses,
             "Administrative and General" = AdminGeneral,
             "Food and Beverage (Operating)" = FoodAndBeverageUnd,
             "Marketing" = Marketing,
             "Management Fee" = ManagementFee,
             "Franchise Fee" = FranchiseFee,
             "All Utilities" = AllUtilities,
             "Property Maintenance" = PropertyMaint,
             "Insurance" = Insurance,
             "Other Operating Expenses" = OtherOperExpenses,
             "Reserve for Replacement" = ReserveOfRepl,
             "Real Estate Taxes" = RealStateTaxes,
             "Other Costs" = OtherCosts,
             "Total Undistributed Operating Expenses" = TotalUndExpenses,
             "Other Expense 1 Name" = OtherExpName1,
             "Other Expense 1" = OtherExpAmount1,
             "Other Expense 2 Name" = OtherExpName2,
             "Other Expense 2" = OtherExpAmount2,
             "Other Expense 3 Name" = OtherExpName3,
             "Other Expense 3" = OtherExpAmount3,
             "Other Expense 4 Name" = OtherExpName4,
             "Other Expense 4" = OtherExpAmount4,
             "Other Expense 5 Name" = OtherExpName5,
             "Other Expense 5" = OtherExpAmount5,
             "Is there a reserve for FF&E?" = ReserveForFFE,
             "Contribution to FF&E reserve" = ContributionToFFE,
             "Cost of items purchased" = CostOfItems,
             "Book cost of FF&E" = BookCostOfFFE,
             "Depreciation of FF&E" = DepreciationOfFFE,
             "Book cost less accumulated depreciation" = BookCostDeprec,
             "Utilities & Sanitation Services SUBTOTAL" = UtilSanitServicesTotal)

  }

  return(x)

}