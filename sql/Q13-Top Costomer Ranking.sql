-- QUESTION 13: Top Customers Ranking
SELECT 
    CustomerFullName,
    ROUND(SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))), 2) AS TotalSalesAmount,
    DENSE_RANK() OVER (
        ORDER BY SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))) DESC
    ) AS CustomerRank
FROM vw_enrichedsales
GROUP BY CustomerKey, CustomerFullName
ORDER BY CustomerRank ASC
LIMIT 10;
