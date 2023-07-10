# nolint start
# Pull from the Buildings table on RPIE
qry_buildings <- function(conn) {
  dbGetQuery(
    conn,
    "
    SELECT DISTINCT
    BUILD.[BuildingId],
    FPIN.[FilingId],
    F.[FilingName],
    CONVERT(DATE, F.[SubmittedDate]) AS SubmittedDate,
    U.[Email] AS [UserEmail],

    --- Pin
    [PinNumber] AS PIN,
    N.[TaxYear] AS [TaxYear],

    --- Building
    [ProjectName],
    [BuildingTypeCode],
    CONVERT(DATE, [RampUpDate]) AS RampUpDate,
    [IsEntirelyOwned],
    [ContainsAllPins],
    [NoContainsPinsExplanation],
    [NumberStories],
    [NumberElevators],
    [BuildingWallTypeCode],
    [BuildingRoofTypeCode],
    [YearBuilt],
    [EffectiveAge],
    [ResidentialUnitCount],
    [CommercialUnitCount],
    [TotalParkingCount],
    [GuestParkingCount],
    [StorageUnitCount],
    [GenerateNoIncome],
    [CovidVacant],
    [ScheduleE],
    CASE WHEN [IsScheduleE] = 1 AND [IsForm8825] = 0 THEN 'Schedule E'
    WHEN [IsScheduleE] = 0 AND [IsForm8825] = 1 THEN 'Form 8825'
    WHEN [IsForm8825] = 1 AND [IsScheduleE] = 1 THEN 'Both' END AS 'ExpenseType',

    --- BussinessType
    [Description] AS BusinessType,

    --- IncomeExpense
    --- This variable transformation to varchar needs to happen so that
    --- we get actual values. Otherwise the query returns erroneous values
    --- for ExpenseRatio

    --- Prefer Schedule E data only if rents for 8825 is empty
    --- 8825 forms seem to provide more reliable data
    CASE WHEN IsScheduleE = 1 AND [Form8825Line18A] = 0 THEN [ScheduleELine24]
         WHEN IsForm8825 = 1 THEN [Form8825Line18A]
         END AS [Total Gross Rents],
    CASE WHEN IsScheduleE = 1 AND [Form8825Line18A] = 0 THEN [ScheduleELine23E]
         WHEN IsForm8825 = 1 THEN ABS([Form8825Line18B])
         END AS [Total Expenses],
    CASE WHEN IsScheduleE = 1 AND [Form8825Line18A] = 0 THEN CONVERT(varchar,
         CASE
         WHEN [ScheduleELine24] > 0 THEN ABS([ScheduleELine23E]) / [ScheduleELine24]
         ELSE NULL END)
         WHEN IsForm8825 = 1 THEN CONVERT(varchar,
         CASE
         WHEN Form8825Line18A != 0 AND Form8825Line18B != 0 THEN ABS(Form8825Line18B) / Form8825Line18A
         ELSE NULL END)
         END AS [ExpenseRatio],
    CASE WHEN IsScheduleE = 1 THEN ABS([ScheduleELine24]) END AS IncomeScheduleE,
    CASE WHEN IsForm8825 = 1 THEN ABS(Form8825Line18A) END AS Income8825

    FROM [RPIE].[dbo].[Building] BUILD

    --- FilingPinBuilding
    LEFT JOIN [RPIE].[dbo].[FilingPinBuilding] FPIN ON BUILD.BuildingId = FPIN.[BuildingId]

    --- Filing
    LEFT JOIN [RPIE].[dbo].[Filing] F ON FPIN.FilingId = F.[FilingId]

    --- IncomeExpense via FilingIncomeExpense
    LEFT JOIN [RPIE].[dbo].[FilingIncomeExpense] FIC ON FPIN.[FilingId] = FIC.[FilingId]

    LEFT JOIN [RPIE].[dbo].[IncomeExpense] IC ON FIC.[IncomeExpenseId] = IC.[IncomeExpenseId]

    --- User
    LEFT JOIN [RPIE].[dbo].[UserBuilding] UB ON BUILD.[BuildingId] = UB.[BuildingId]
    LEFT JOIN [RPIE].[dbo].[User] U ON UB.[UserId] = U.[UserId]

    --- Pin
    LEFT JOIN [RPIE].[dbo].Pin PIN ON FPIN.[PinId] = PIN.[PinId]

    --- FilingNotice
    LEFT JOIN [RPIE].[dbo].FilingPinNotice FPN ON F.[FilingId] = FPN.[FilingId]

    --- Notice
    LEFT JOIN [RPIE].[dbo].Notice N ON FPN.[NoticeId] = N.[ID]

    --- Business Type
    LEFT JOIN [RPIE].[dbo].[BuildingBusinessType] BBT ON BUILD.[BuildingId] = BBT.[BuildingId]
    LEFT JOIN [RPIE].[dbo].[BusinessType] BT ON BBT.[BusinessTypeCode] = BT.[BusinessTypeCode]
    "
  ) %>%
    mutate(ExpenseRatio = as.numeric(ExpenseRatio)) # ExpenseRatio is imported as a character vector
}

# Pull from the IncomeExpenseGeneral table on RPIE
qry_generalexpenses <- function(conn) {
  dbGetQuery(
    conn,
    "
    --- IncomeExpenseGeneral contains a multitude of columns related to expenses that need to be manipulated using
    --- the 'CalcExpenseRatio' function
    SELECT F.[FilingId], IEG.*

    FROM Filing F

    --- Income and Expenses via IncomeExpenseGeneral
    LEFT JOIN [RPIE].[dbo].[IncomeExpenseGeneral] IEG ON F.[IncomeExpenseGeneralId] = IEG.[IncomeExpenseGeneralId]
    "
  )
}

# Pull from the IncomeExpenseHotel table on RPIE
qry_hotelexpenses <- function(conn) {
  dbGetQuery(
    conn,
    "
    --- IncomeExpenseGeneral contains a multitude of columns related to expenses that need to be manipulated using
    --- the 'CalcExpenseRatio' function
    SELECT F.[FilingId], IEH.*

    FROM Filing F

    --- Income and Expenses via IncomeExpenseHotel
    LEFT JOIN [RPIE].[dbo].[IncomeExpenseHotel] IEH ON F.[IncomeExpenseHotelId] = IEH.[IncomeExpenseHotelId]
    "
  )
}

# Pull from ResidentialSpaces on RPIE
qry_res_spaces <- function(conn) {
  dbGetQuery(
    conn,
    "
      WITH RS AS (SELECT *,

CASE WHEN [BedroomCount] = 'Studio' THEN 0 ELSE CAST(REPLACE([BedroomCount], '+', '') AS FLOAT) END AS [Beds],
CAST(REPLACE([BathroomCount], '+', '') AS FLOAT) AS Baths,
CAST([RoomCount] AS FLOAT) AS Rooms

FROM [RPIE].[dbo].[ResidentialSpace])

SELECT
          [BuildingId] ,
          CASE
              WHEN SUM(CAST([IsOwnerOccupied] AS INT)) > 0 THEN 1
              ELSE 0
              END AS [ResOwnerOccupied],
          SUM(
              CAST([HasGarden] AS INT)
              ) AS [GardenUnits],
          SUM([FreeRent]) AS [ResidentialFreeRent],
          SUM(CASE WHEN AffordableSubsidized = 'Yes-LIHTC' THEN 1 ELSE 0 END) AS [AffordableUnits_LIHTC],
          SUM(CASE WHEN AffordableSubsidized = 'Yes-PB' THEN 1 ELSE 0 END) AS [AffordableUnits_PB],
          SUM([RentPerMonth]) AS [ResidentialRentalIncome],
          SUM(CAST([IsVacantOnSubmissionDate] AS INT)) AS [ResidentialVacancies],
          AVG(CAST(
            CASE
                  WHEN Vacancy = '0' THEN 0
                  WHEN Vacancy = '0-2' THEN 1
                  WHEN Vacancy = '2-4' THEN 3
                  WHEN Vacancy = '4-6' THEN 5
                  WHEN Vacancy = '6-8' THEN 7
                  WHEN Vacancy = '8-10' THEN 9
                  WHEN Vacancy = '10-12' THEN 11
                  ELSE NULL
            END AS INT)) AS [ResidentialMonthsVacantLastYear],

          --- units
          COUNT(BuildingId) AS ResidentialUnits,

          --- rooms and sqft
          SUM([SquareFeet]) AS [ResidentialSquareFeet],
          SUM(Beds) AS [TotalBedrooms],
          SUM(Baths) AS [TotalBathrooms],
          SUM(Rooms) AS [TotalRooms],

          --- rent per squarefoot
          AVG(
            CASE
              WHEN [RentPerMonth] IS NOT NULL AND [SquareFeet] > 0 THEN [RentPerMonth] / [SquareFeet]
              ELSE NULL END
              ) AS [ResidentialRentPerSquareFoot],

          --- rent by bedroom
          COUNT(CASE WHEN Beds = 0 THEN 1 ELSE NULL END) AS [Studio Units],
          AVG(
              CASE WHEN Beds = 0  THEN [RentPerMonth] ELSE NULL END
              ) AS [StudioRent],
          COUNT(CASE WHEN Beds = 1 THEN 1 ELSE NULL END) AS [One Bedroom Units],
          AVG(
              CASE WHEN Beds = 1 THEN [RentPerMonth] ELSE NULL END
              ) AS [Bedroom1Rent],
          COUNT(CASE WHEN Beds = 2 THEN 1 ELSE NULL END) AS [Two Bedroom Units],
          AVG(
              CASE WHEN Beds = 2 THEN [RentPerMonth] ELSE NULL END
              ) AS [Bedroom2Rent],
          COUNT(CASE WHEN Beds = 3 THEN 1 ELSE NULL END) AS [Three Bedroom Units],
          AVG(
              CASE WHEN Beds = 3 THEN [RentPerMonth] ELSE NULL END
              ) AS [Bedroom3Rent],
          COUNT(CASE WHEN Beds >= 4 THEN 1 ELSE NULL END) AS [Four+ Bedroom Units],
          AVG(
              CASE WHEN Beds >= 4 THEN [RentPerMonth] ELSE NULL END
              ) AS [Bedroom4Rent],
          CAST(MAX(LeaseStartDate) AS DATE) AS [MostRecentResidentialLease]
      FROM [RS]
      GROUP BY [BuildingId]
      "
  )
}

# Pull from CommercialSpaces on RPIE
qry_com_spaces <- function(conn) {
  dbGetQuery(
    conn,
    "
      SELECT
          [BuildingId],
          CASE
              WHEN SUM(CAST([IsOwnerOccupied] AS INT)) > 0 THEN 1
              ELSE 0
          END AS [ComOwnerOccupied],
          SUM(CAST([IsVacant] AS INT)) AS [CommercialVacancies],
          AVG(CAST(CASE WHEN Vacancy = '0' THEN 0
            WHEN Vacancy = '0-2' THEN 1
            WHEN Vacancy = '2-4' THEN 3
            WHEN Vacancy = '4-6' THEN 5
            WHEN Vacancy = '6-8' THEN 7
            WHEN Vacancy = '8-10' THEN 9
            WHEN Vacancy = '10-12' THEN 11
            ELSE NULL
            END AS INT)) AS [CommercialMonthsVacantLastYear],
          SUM([SquareFeet]) AS [CommercialSquareFeet],

          --- units
          COUNT(BuildingId) AS CommercialUnits,

          --- rent per squarefoot
          AVG(
            CASE
          --- commercial rent is a mess; taxpayers enter yearly, monthly, and per sqft
              WHEN [RentPerMonth] IS NOT NULL
              AND [RentPerMonth] > 100
              AND [SquareFeet] > 0
              THEN [RentPerMonth] / [SquareFeet] * 12
              ELSE NULL END
              ) AS [CommercialRentPerSquareFoot],

          SUM([RentPerMonth]) AS [CommercialRentalIncome],
          SUM([FreeRent]) AS [CommercialFreeRent],
          SUM([TaxesPaid]) AS [TaxesPaid],
          STRING_AGG(CAST([UseDescription] as NVARCHAR(MAX)), ', ') AS [UseDescriptions],
          STRING_AGG(CAST([LeaseTypeCode] as NVARCHAR(MAX)), ', ') AS [CommercialLeaseType],
          CAST(MAX(LeaseStartDate) AS DATE) AS [MostRecentCommercialLease]
      FROM [RPIE].[dbo].[CommercialSpace]
      GROUP BY [BuildingId]
      "
  )
}

# Pull spatial and PIN-related data from tables on AWS
qry_pins <- function(conn) {
  dbGetQuery(
    conn,
    "
    select
      parid as PIN,
      substr(nbhd, 1, 2) as township_code,
      nbhd as neighborhood,
      class,
      lat,
      lon as long,
      cityname as municipality,
      adrno as PL_HOUSE_NO,
      adrdir as PL_DIR,
      adrstr as PL_STR_NAME,
      adrsuf as PL_STR_SUFFIX,
      zip1 as zip,
      cast(taxyr as int) as TaxYear
    from iasworld.pardat
    left join (
      select
        pin10, cast(cast(year as int) + 1 as varchar) as year, lat, lon
      from spatial.parcel
    ) parcel
    on substr(parid, 1, 10) = pin10 and pardat.taxyr = parcel.year
    where substr(class, 1, 1) in ('3', '4', '5', '6', '7', '8', '9')
      and taxyr >= '2020'
  "
  )
}
# nolint end
