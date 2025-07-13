CREATE TABLE Date_Dimension (
    [Date] DATE PRIMARY KEY,
    SKDate INT,
    KeyDate VARCHAR(20),
    CalendarDay INT,
    CalendarMonth INT,
    CalendarQuarter INT,
    CalendarYear INT,
    DayName VARCHAR(20),
    DayNameShort VARCHAR(10),
    DayNumberOfWeek INT,
    DayNumberOfYear INT,
    DaySuffix VARCHAR(10),
    FiscalWeek INT,
    FiscalPeriod INT,
    FiscalQuarter INT,
    FiscalYear INT,
    FiscalYearPeriod VARCHAR(20)
);

-- Step 2: Create the stored procedure to populate the Date_Dimension table
CREATE PROCEDURE PopulateDateDimension
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    -- Generate a series of dates for the entire year using a single insert
    ;WITH DateSeries AS (
        SELECT TOP (DATEDIFF(DAY, @StartDate, @EndDate) + 1)
            DateValue = DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @StartDate)
        FROM sys.all_objects -- Using a large system table to generate rows
    )
    INSERT INTO Date_Dimension (
        [Date], SKDate, KeyDate, CalendarDay, CalendarMonth, CalendarQuarter,
        CalendarYear, DayName, DayNameShort, DayNumberOfWeek, DayNumberOfYear,
        DaySuffix, FiscalWeek, FiscalPeriod, FiscalQuarter, FiscalYear, FiscalYearPeriod
    )
    SELECT
        d.DateValue,
        CAST(CONVERT(CHAR(8), d.DateValue, 112) AS INT),
        CONVERT(VARCHAR(20), d.DateValue, 101),
        DATEPART(DAY, d.DateValue),
        DATEPART(MONTH, d.DateValue),
        DATEPART(QUARTER, d.DateValue),
        DATEPART(YEAR, d.DateValue),
        DATENAME(WEEKDAY, d.DateValue),
        LEFT(DATENAME(WEEKDAY, d.DateValue), 3),
        DATEPART(WEEKDAY, d.DateValue),
        DATEPART(DAYOFYEAR, d.DateValue),
        CAST(DATEPART(DAY, d.DateValue) AS VARCHAR) + 
            CASE 
                WHEN DATEPART(DAY, d.DateValue) IN (11, 12, 13) THEN 'th'
                WHEN DATEPART(DAY, d.DateValue) % 10 = 1 THEN 'st'
                WHEN DATEPART(DAY, d.DateValue) % 10 = 2 THEN 'nd'
                WHEN DATEPART(DAY, d.DateValue) % 10 = 3 THEN 'rd'
                ELSE 'th'
            END,
        DATEPART(WEEK, d.DateValue),
        DATEPART(MONTH, d.DateValue),
        DATEPART(QUARTER, d.DateValue),
        DATEPART(YEAR, d.DateValue),
        CAST(DATEPART(YEAR, d.DateValue) AS VARCHAR) + 
            RIGHT('0' + CAST(DATEPART(MONTH, d.DateValue) AS VARCHAR), 2)
    FROM DateSeries d;
END;

-- Step 3: Call the stored procedure to populate dates for the year 2020
EXEC PopulateDateDimension '2020-07-14';

-- Step 4: Verify a few inserted records
SELECT TOP 10 * 
FROM Date_Dimension
ORDER BY [Date];


-- View the entire year if need : 
SELECT * 
FROM Date_Dimension
WHERE CalendarYear = 2020
ORDER BY [Date];
