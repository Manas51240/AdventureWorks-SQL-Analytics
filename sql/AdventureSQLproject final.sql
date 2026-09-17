-----------------------------------
-- ADVENTURE WORK PROJECT GROUP-2
-----------------------------------

create database adventurework;
use adventurework;
show tables;

-- QUESTION 0(UNION)
create view mastersales as
select * from FactInternetSales
union all
select * from Fact_Internet_Sales_New;

select count(*) from mastersales;

-- Questions 1 & 2 (Lookups): Perform LEFT JOIN operations connecting your sales view with DimProduct and DimCustomer.
-- Retrieve dimensions such as ProductName,UnitPrice,UnitCost,& derive a concatenated CustomerFullName.
SELECT
    dp.EnglishProductName ProductName,
    ms.UnitPrice,
    dp.StandardCost UnitCost,
    concat(dc.FirstName,' ',dc.LastName) AS CustomerFullName
FROM mastersales AS ms
LEFT JOIN DimProduct AS dp ON ms.ProductKey = dp.ProductKey
LEFT JOIN DimCustomer AS dc ON ms.CustomerKey = dc.CustomerKey;

-- Question 3 (Date Breakdown):Convert OrderDateKey into a standard date format.
-- Use SQL date extraction functions(YEAR(),MONTH(),DATENAME(),DATEPART(),FORMAT()) 
-- to return the 9 requested date attributes(Year, Month No, Month Name, Quarter, Year-Month, Weekday No, Weekday Name, FinancialMonth, and Financial Quarter).

with CTE as (select str_to_date(cast(orderdatekey as char),'%Y%m%d') as orderdate from mastersales)
select orderdate,year(orderdate) as Year,month(orderdate) as Month, monthname(orderdate) as Monthname, quarter(orderdate) as Quarter,
date_format(orderdate,'%Y-%m') as YearMonth, weekday(orderdate) as weekdayno, dayname(orderdate) as  weekdayname, 
	case
		when month(orderdate) >= 4
			then month(orderdate)-3
		else month(orderdate)+9
	end as financialmonth,

	case
		when month(orderdate) in (4,5,6)
			then 'Q1'
		when month(orderdate) in (7,8,9)
			then 'Q2'
		when month(orderdate) in (10,11,12)
			then 'Q3'
			else 'Q4'
	end as financialquarter
from CTE;


-- Questions 4 to 6 (Calculated Columns): Compute the core financial metrics in your SELECT statement:
-- Sales Amount: OrderQuantity * UnitPrice * (1 - Discount)
-- Production Cost: OrderQuantity * UnitCost
-- Profit: Sales Amount - Production Cost 
with CTE as (Select round((orderquantity*unitprice*(1-discountamount)),2) SalesAmount, round((orderquantity*productstandardcost),2) ProductionCost 
from mastersales)
select salesamount,productioncost, round((SalesAmount-ProductionCost),2) Profit from CTE;

-- Question 7 (Pivot Table): Group by Month Name/Number with a WHERE 
-- clause filtering for a specific Year, displaying SUM(Sales Amount).
WITH CTE AS (
    SELECT
        SalesAmount,
        STR_TO_DATE(
            CAST(OrderDateKey AS CHAR),
            '%Y%m%d'
        ) AS orderdate
    FROM mastersales
)

SELECT
    MONTHNAME(orderdate) AS Month,
    YEAR(orderdate) AS Year,
    ROUND(SUM(SalesAmount), 2) AS `Total Revenue`
FROM CTE
WHERE YEAR(orderdate) = 2012
GROUP BY
    MONTH(orderdate),
    MONTHNAME(orderdate),
    YEAR(orderdate)
ORDER BY
    MONTH(orderdate);
    
-- Question 8 (Bar Chart Data): Group by Year and output SUM(Sales Amount) sorted chronologically to display year-over-year revenue trends.

WITH CTE AS (SELECT SalesAmount,STR_TO_DATE(CAST(OrderDateKey AS CHAR),'%Y%m%d') AS orderdate
    FROM mastersales)
SELECT
    YEAR(orderdate) AS Year,
    ROUND(SUM(SalesAmount),2) AS `Total Revenue`
FROM CTE
GROUP BY YEAR(orderdate) ORDER BY year;

-- Question 9 (Line Chart Data): Group by Month to display month-by-month performance.
WITH CTE AS (
    SELECT
        SalesAmount,
        STR_TO_DATE(
            CAST(OrderDateKey AS CHAR),
            '%Y%m%d'
        ) AS orderdate
    FROM mastersales
)
SELECT
    MONTHNAME(orderdate) AS Month,
    ROUND(SUM(SalesAmount), 2) AS `Total Revenue`
FROM CTE GROUP BY MONTH(orderdate), MONTHNAME(orderdate) ORDER BY MONTH(orderdate);

-- Question 10 (Pie Chart Data): Group by Quarter (DATEPART(QUARTER, ...)) to show quarterly revenue distribution.
WITH CTE AS (
    SELECT
        SalesAmount,
        STR_TO_DATE(
            CAST(OrderDateKey AS CHAR),
            '%Y%m%d'
        ) AS orderdate
    FROM mastersales
)
SELECT
    case
		when month(orderdate) in (4,5,6)
			then 'Q1'
		when month(orderdate) in (7,8,9)
			then 'Q2'
		when month(orderdate) in (10,11,12)
			then 'Q3'
			else 'Q4'
	end as financialquarter,
    ROUND(SUM(SalesAmount), 2) AS `Total Revenue`
FROM CTE GROUP BY financialquarter ORDER BY financialquarter;


-- Question 11 (Combo Chart Data): Group by Year-Month (yyyy-MMM) and display both SUM(Sales Amount) and SUM(Production Cost) side-by-side in your results grid.
WITH CTE AS (SELECT SalesAmount, ProductStandardCost,STR_TO_DATE(CAST(OrderDateKey AS CHAR),'%Y%m%d') AS orderdate
    FROM mastersales)
SELECT
	date_format(orderdate,'%Y-%m') as YearMonth,
    ROUND(SUM(SalesAmount), 2) AS `Total Revenue`,
    ROUND(SUM(Productstandardcost), 2) AS `Production Cost`
    
FROM CTE GROUP BY YearMonth ORDER BY YearMonth;

-- Question 12 (Performance Breakdown): Write structured aggregation queries to evaluate:
-- A)Products: Top product lines and categories by profit.
-- B)Customers: High-value customers ranked using SQL window functions like DENSE_RANK() OVER (ORDER BY SUM(SalesAmount) DESC).
-- C)Regions: Join DimSalesTerritory to aggregate total revenue by territory and region

-- A)
select dp.productline,dpc.englishproductcategoryname,round(sum(ms.salesamount-ms.productstandardcost),2) Profit
from mastersales ms inner join dimproduct dp on  ms.productkey=dp.productkey inner join dimproductsubcategory dpsc
on dp.ProductSubcategoryKey= dpsc.ProductSubcategoryKey inner join dimproductcategory dpc on dpsc.ProductCategoryKey = dpc.ProductCategoryKey
group by dp.productline,dpc.EnglishProductCategoryName order by Profit desc ;

-- B)
select concat(dc.FirstName,' ',dc.LastName) Customer ,round(SUM(SalesAmount),2) as `Total Revenue`, dense_rank() over(Order by SUM(SalesAmount) DESC) as Customer_Rank
from mastersales as ms inner join dimcustomer as dc ON  ms.customerkey = dc.customerkey group by dc.FirstName,dc.LastName;

-- C)
select round(SUM(SalesAmount),2) as `Total Revenue`, salesterritorycountry, salesterritoryregion 
from mastersales as ms inner join dimsalesterritory as dst
on ms.salesterritorykey = dst.salesterritorykey group by salesterritorycountry, salesterritoryregion order by `Total Revenue` desc;



-- Q13 — CONSOLIDATED EXECUTIVE REPORTING
-- Q13A — EXECUTIVE KPI SUMMARY


CREATE VIEW ExecutiveKPI AS
SELECT COUNT(DISTINCT ms.SalesOrderNumber) AS TotalOrders,SUM(ms.OrderQuantity) AS TotalQuantity,
ROUND(SUM(ms.OrderQuantity * ms.UnitPrice *(1 - ms.DiscountAmount)),2) AS TotalSalesAmount,

ROUND(SUM(ms.OrderQuantity * ms.ProductStandardCost),2) AS TotalProductionCost,

ROUND(SUM(ms.OrderQuantity * ms.UnitPrice *(1 - ms.DiscountAmount))-SUM(ms.OrderQuantity * ms.ProductStandardCost),2) AS TotalProfit,

ROUND(SUM(ms.OrderQuantity * ms.UnitPrice *(1 - ms.DiscountAmount))/NULLIF(COUNT(DISTINCT ms.SalesOrderNumber), 0),2) AS AverageOrderValue

FROM MasterSales AS ms;
SELECT *
FROM ExecutiveKPI;

-- Q13B — TERRITORY PERFORMANCE

CREATE VIEW TerritoryPerformance AS
SELECT
    dst.SalesTerritoryRegion,
    dst.SalesTerritoryCountry,
    dst.SalesTerritoryGroup,

    COUNT(DISTINCT ms.SalesOrderNumber) AS TotalOrders,

    ROUND(
        SUM(
            ms.OrderQuantity * ms.UnitPrice *
            (1 - ms.DiscountAmount)
        ),
        2
    ) AS SalesAmount,

    ROUND(
        SUM(
            ms.OrderQuantity * ms.ProductStandardCost
        ),
        2
    ) AS ProductionCost,

    ROUND(
        SUM(
            ms.OrderQuantity * ms.UnitPrice *
            (1 - ms.DiscountAmount)
        )
        -
        SUM(
            ms.OrderQuantity * ms.ProductStandardCost
        ),
        2
    ) AS Profit

FROM MasterSales AS ms

LEFT JOIN DimSalesTerritory AS dst
    ON ms.SalesTerritoryKey = dst.SalesTerritoryKey

GROUP BY
    dst.SalesTerritoryRegion,
    dst.SalesTerritoryCountry,
    dst.SalesTerritoryGroup;


SELECT *
FROM TerritoryPerformance
ORDER BY SalesAmount DESC;



-- Q13C — TOP 10 PRODUCTS EXECUTIVE REPORT

CREATE VIEW ProductPerformance AS
SELECT
    dp.ProductKey,
    dp.EnglishProductName AS ProductName,
    dpc.EnglishProductCategoryName AS CategoryName,
    dpsc.EnglishProductSubcategoryName AS SubcategoryName,
    ROUND(
        SUM(
            ms.OrderQuantity * ms.UnitPrice *
            (1 - ms.DiscountAmount)
        ),
        2
    ) AS SalesAmount,

    ROUND(
        SUM(
            ms.OrderQuantity * ms.ProductStandardCost
        ),
        2
    ) AS ProductionCost,

    ROUND(
        SUM(
            ms.OrderQuantity * ms.UnitPrice *
            (1 - ms.DiscountAmount)
        )
        -
        SUM(
            ms.OrderQuantity * ms.ProductStandardCost
        ),
        2
    ) AS Profit

FROM MasterSales AS ms

LEFT JOIN DimProduct AS dp
    ON ms.ProductKey = dp.ProductKey

LEFT JOIN DimProductSubcategory AS dpsc
    ON dp.ProductSubcategoryKey = dpsc.ProductSubcategoryKey

LEFT JOIN DimProductCategory AS dpc
    ON dpsc.ProductCategoryKey = dpc.ProductCategoryKey

GROUP BY
    dp.ProductKey,
    dp.EnglishProductName,
    dpc.EnglishProductCategoryName,
    dpsc.EnglishProductSubcategoryName;

SELECT *
FROM ProductPerformance
ORDER BY Profit DESC
LIMIT 10;


-- Q13D — FINAL EXECUTIVE DASHBOARD QUERY

SELECT
COUNT(DISTINCT ms.SalesOrderNumber) AS TotalOrders,
SUM(ms.OrderQuantity) AS TotalQuantity,
ROUND(
        SUM(ms.OrderQuantity * ms.UnitPrice *(1 - ms.DiscountAmount)),2) AS TotalSalesAmount,

    ROUND(
        SUM(
            ms.OrderQuantity * ms.ProductStandardCost
        ),
        2
    ) AS TotalProductionCost,

    ROUND(
        SUM(
            ms.OrderQuantity * ms.UnitPrice *
            (1 - ms.DiscountAmount)
        )
        -
        SUM(
            ms.OrderQuantity * ms.ProductStandardCost
        ),
        2
    ) AS TotalProfit,

    ROUND(
        (
            SUM(
                ms.OrderQuantity * ms.UnitPrice *
                (1 - ms.DiscountAmount)
            )
            -
            SUM(
                ms.OrderQuantity * ms.ProductStandardCost
            )
        )
        /
        NULLIF(
            SUM(
                ms.OrderQuantity * ms.UnitPrice *
                (1 - ms.DiscountAmount)
            ),
            0)* 100,2) AS ProfitMarginPct

FROM MasterSales AS ms;



-- Q13 — VERIFY ALL EXECUTIVE VIEWS

SHOW FULL TABLES
WHERE Table_type = 'VIEW';

SELECT *
FROM ExecutiveKPI;

SELECT *
FROM TerritoryPerformance
ORDER BY SalesAmount DESC;

SELECT *
FROM ProductPerformance
ORDER BY Profit DESC
LIMIT 10;


