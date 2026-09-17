USE adventureworks;

-- QUESTION 7: Monthly Sales for 2013
SELECT 
    MONTH(StandardOrderDate) AS MonthNo,
    MONTHNAME(StandardOrderDate) AS MonthName,
    ROUND(SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))), 2) AS TotalSalesAmount
FROM vw_enrichedsales
WHERE YEAR(StandardOrderDate) = 2013
GROUP BY MONTH(StandardOrderDate), MONTHNAME(StandardOrderDate)
ORDER BY MonthNo ASC;
