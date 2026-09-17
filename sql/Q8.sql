-- QUESTION 8: YoY Sales Revenue Trend
SELECT 
    YEAR(StandardOrderDate) AS Year,
    ROUND(SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))), 2) AS TotalSalesAmount
FROM vw_enrichedsales
GROUP BY YEAR(StandardOrderDate)
ORDER BY Year ASC;
