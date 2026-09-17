-- QUESTION 11: Monthly Sales vs Production Cost Comparison
SELECT 
    DATE_FORMAT(StandardOrderDate, '%Y-%m') AS YearMonth,
    ROUND(SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))), 2) AS TotalSalesAmount,
    ROUND(SUM(OrderQuantity * UnitCost), 2) AS TotalProductionCost
FROM vw_enrichedsales
GROUP BY DATE_FORMAT(StandardOrderDate, '%Y-%m')
ORDER BY YearMonth ASC;
