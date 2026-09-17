-- QUESTION 10: Quarterly Revenue Distribution
SELECT 
    CONCAT('Q', QUARTER(StandardOrderDate)) AS Quarter,
    ROUND(SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))), 2) AS TotalSalesAmount
FROM vw_enrichedsales
GROUP BY CONCAT('Q', QUARTER(StandardOrderDate))
ORDER BY Quarter ASC;
