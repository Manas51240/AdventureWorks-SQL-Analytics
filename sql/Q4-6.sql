SELECT 
    SalesOrderNumber,
    ProductName,
    OrderQuantity,
    UnitPrice,
    IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0) AS UnitPriceDiscountPct,
    UnitCost,
    
    -- Q4: Sales Amount
    ROUND(OrderQuantity * UnitPrice * (1.0 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0)), 2) AS SalesAmount,
    
    -- Q5: Production Cost
    ROUND(OrderQuantity * UnitCost, 2) AS ProductionCost,
    
    -- Q6: Profit
    ROUND((OrderQuantity * UnitPrice * (1.0 - IFNULL(CAST(UnitPriceDiscountPct AS DOUBLE), 0))) - (OrderQuantity * UnitCost), 2) AS Profit

FROM vw_enrichedsales;
