USE adventureworks;

-- Check Product Names in your Enriched Sales View
SELECT SalesOrderNumber, ProductName, UnitPrice, UnitCost, CustomerFullName 
FROM vw_enrichedsales;
