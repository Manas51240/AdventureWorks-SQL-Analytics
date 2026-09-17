USE adventureworks;

-- QUESTION 0: Create Master Sales View combining both sales tables
DROP VIEW IF EXISTS vw_MasterSales;

CREATE VIEW vw_MasterSales AS
SELECT 
    ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey, 
    PromotionKey, CurrencyKey, SalesTerritoryKey, SalesOrderNumber, 
    SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, 
    ExtendedAmount, UnitPriceDiscountPct, DiscountAmount, ProductStandardCost, 
    TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber, 
    CustomerPONumber, OrderDate, DueDate, ShipDate
FROM FactInternetSales

UNION ALL

SELECT 
    ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey, 
    PromotionKey, CurrencyKey, SalesTerritoryKey, SalesOrderNumber, 
    SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, 
    ExtendedAmount, UnitPriceDiscountPct, DiscountAmount, ProductStandardCost, 
    TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber, 
    CustomerPONumber, OrderDate, DueDate, ShipDate
FROM Fact_Internet_Sales_New;

-- Test Question 0:
SELECT COUNT(*) AS MasterSalesTotalRows FROM vw_MasterSales;
