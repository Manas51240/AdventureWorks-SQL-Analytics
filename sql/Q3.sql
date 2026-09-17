USE adventureworks;

-- QUESTION 3: 9 Date Attributes Breakdown
SELECT 
    OrderDateKey,
    StandardOrderDate AS OrderDate,
    YEAR(StandardOrderDate) AS Year,                                              -- 1. Year
    MONTH(StandardOrderDate) AS MonthNo,                                          -- 2. Month No
    MONTHNAME(StandardOrderDate) AS MonthName,                                    -- 3. Month Name
    CONCAT('Q', QUARTER(StandardOrderDate)) AS Quarter,                          -- 4. Quarter
    DATE_FORMAT(StandardOrderDate, '%Y-%b') AS YearMonth,                         -- 5. Year-Month
    DAYOFWEEK(StandardOrderDate) AS WeekdayNo,                                    -- 6. Weekday No
    DAYNAME(StandardOrderDate) AS WeekdayName,                                    -- 7. Weekday Name
    ((MONTH(StandardOrderDate) + 5) MOD 12) + 1 AS FinancialMonth,               -- 8. Financial Month (July = FM1)
    CONCAT('FQ', FLOOR((((MONTH(StandardOrderDate) + 5) MOD 12)) / 3) + 1) AS FinancialQuarter -- 9. Financial Quarter
FROM vw_enrichedsales
LIMIT 10;
