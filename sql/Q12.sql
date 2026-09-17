USE adventureworks;

-- QUESTION 12: Executive KPI Scorecard
SELECT 
    ROUND(SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))), 2) AS TotalSalesRevenue,
    ROUND(SUM(OrderQuantity * UnitCost), 2) AS TotalProductionCost,
    ROUND(SUM((OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))) - (OrderQuantity * UnitCost)), 2) AS TotalProfit,
    ROUND((SUM((OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))) - (OrderQuantity * UnitCost)) / 
           SUM(OrderQuantity * UnitPrice * (1 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0)))) * 100, 2) AS ProfitMarginPct,
    COUNT(DISTINCT SalesOrderNumber) AS TotalOrders,
    SUM(OrderQuantity) AS TotalQuantitySold
FROM vw_enrichedsales;
