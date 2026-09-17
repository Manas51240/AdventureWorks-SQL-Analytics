-- QUESTION 9: Monthly Sales Performance
SELECT 
    MONTH(StandardOrderDate) AS MonthNo,
    MONTHNAME(StandardOrderDate) AS MonthName,
    ROUND(SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))), 2) AS TotalSalesAmount
FROM vw_enrichedsales
GROUP BY MONTH(StandardOrderDate), MONTHNAME(StandardOrderDate)
ORDER BY MonthNo ASC;
