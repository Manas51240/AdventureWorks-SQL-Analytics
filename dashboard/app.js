let globalData = null;
let chartInstances = {};

const minimalistSqlRepo = {
    "Q0": {
        title: "Q0: Data Union (FactInternetSales & Fact_Internet_Sales_New)",
        explanation: "Combines both internet sales datasets into a single master view using UNION ALL without removing duplicate rows for maximum query speed.",
        code: `-- Q0: Combine Sales Tables
CREATE VIEW vw_MasterSales AS
SELECT * FROM FactInternetSales
UNION ALL
SELECT * FROM Fact_Internet_Sales_New;`,
        summary: "Master Union Result: 60,398 Total Sales Records stacked vertically."
    },
    "Q1": {
        title: "Q1: Lookup ProductName from Product Sheet",
        explanation: "Uses LEFT JOIN to attach EnglishProductName from DimProduct to sales records based on ProductKey match.",
        code: `-- Q1: Lookup ProductName
SELECT 
    s.SalesOrderNumber,
    p.EnglishProductName AS ProductName
FROM vw_MasterSales s
LEFT JOIN DimProduct p ON s.ProductKey = p.ProductKey;`,
        summary: "Successfully mapped EnglishProductName to all 60,398 sales rows."
    },
    "Q2": {
        title: "Q2: Lookup Customer Full Name and Unit Price",
        explanation: "Joins DimCustomer to concatenate FirstName & LastName and DimProduct to fetch StandardCost & UnitPrice.",
        code: `-- Q2: Lookup Customer Name & Product Pricing
SELECT 
    s.SalesOrderNumber,
    CONCAT(c.FirstName, ' ', c.LastName) AS CustomerFullName,
    s.UnitPrice,
    p.StandardCost AS UnitCost
FROM vw_MasterSales s
LEFT JOIN DimCustomer c ON s.CustomerKey = c.CustomerKey
LEFT JOIN DimProduct p ON s.ProductKey = p.ProductKey;`,
        summary: "Concatenated Customer Names & verified Unit Prices across dataset."
    },
    "Q3": {
        title: "Q3: Calculate 9 Date Breakdown Attributes from OrderDateKey",
        explanation: "Converts integer OrderDateKey (YYYYMMDD) into standard DATE, extracting Year, Month, MonthName, Quarter, YearMonth, Weekdays, Financial Month & Financial Quarter.",
        code: `-- Q3: 9 Date Fields Breakdown
SELECT 
    CAST(CAST(OrderDateKey AS VARCHAR(8)) AS DATE) AS OrderDate,
    YEAR(OrderDate) AS Year,
    MONTH(OrderDate) AS MonthNo,
    DATENAME(MONTH, OrderDate) AS MonthName,
    CONCAT('Q', DATEPART(QUARTER, OrderDate)) AS Quarter,
    FORMAT(OrderDate, 'yyyy-MMM') AS YearMonth,
    DATEPART(WEEKDAY, OrderDate) AS WeekdayNo,
    DATENAME(WEEKDAY, OrderDate) AS WeekdayName,
    ((MONTH(OrderDate) + 5) % 12) + 1 AS FinancialMonth,
    CONCAT('FQ', (((MONTH(OrderDate) + 5) / 3) % 4) + 1) AS FinancialQuarter
FROM vw_MasterSales;`,
        summary: "Extracted 9 attributes (e.g. 2013-12-31 => 2013, Dec, Q4, 2013-Dec, FM6, FQ2)."
    },
    "Q4": {
        title: "Q4: Calculate Sales Amount",
        explanation: "Computes total revenue using OrderQuantity * UnitPrice * (1 - Discount).",
        code: `-- Q4: Calculate Sales Amount
SELECT 
    OrderQuantity * UnitPrice * (1.0 - UnitPriceDiscountPct) AS SalesAmount
FROM vw_MasterSales;`,
        summary: "Total Calculated Sales Revenue: $29,358,677.89"
    },
    "Q5": {
        title: "Q5: Calculate Production Cost",
        explanation: "Computes total production cost by multiplying OrderQuantity with Product StandardCost.",
        code: `-- Q5: Calculate Production Cost
SELECT 
    OrderQuantity * UnitCost AS ProductionCost
FROM vw_MasterSales s
JOIN DimProduct p ON s.ProductKey = p.ProductKey;`,
        summary: "Total Production Cost: $17,277,858.06"
    },
    "Q6": {
        title: "Q6: Calculate Profit",
        explanation: "Subtracts Production Cost from Sales Amount to obtain Net Profit.",
        code: `-- Q6: Calculate Profit
SELECT 
    (OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) - (OrderQuantity * UnitCost) AS Profit
FROM vw_MasterSales;`,
        summary: "Total Net Profit: $12,080,819.83 (Profit Margin: 41.15%)"
    },
    "Q7": {
        title: "Q7: Pivot Table (Monthly Sales for Specific Year)",
        explanation: "Filters by Year = 2013 and groups by Month Number/Name to compute monthly sales sum.",
        code: `-- Q7: Pivot Table for 2013 Monthly Sales
SELECT 
    DATENAME(MONTH, OrderDate) AS MonthName,
    SUM(OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM vw_EnrichedSales
WHERE YEAR(OrderDate) = 2013
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY MONTH(OrderDate);`,
        summary: "2013 Top Month: December ($1.87M), Lowest: February ($771.3k)."
    },
    "Q8": {
        title: "Q8: Bar Chart Data (YoY Sales Trends)",
        explanation: "Groups total sales by Year sorted chronologically to display revenue growth.",
        code: `-- Q8: Year-over-Year (YoY) Sales Trends
SELECT 
    YEAR(OrderDate) AS Year,
    SUM(OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM vw_EnrichedSales
GROUP BY YEAR(OrderDate)
ORDER BY Year ASC;`,
        summary: "Sales Trends: 2010 ($43.4k), 2011 ($7.08M), 2012 ($5.84M), 2013 ($16.35M peak)."
    },
    "Q9": {
        title: "Q9: Line Chart Data (Month-by-Month Performance)",
        explanation: "Groups overall sales by Month to evaluate seasonality performance across all years.",
        code: `-- Q9: Month-by-Month Sales Performance
SELECT 
    DATENAME(MONTH, OrderDate) AS MonthName,
    SUM(OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM vw_EnrichedSales
GROUP BY MONTH(OrderDate), DATENAME(MONTH, OrderDate)
ORDER BY MONTH(OrderDate);`,
        summary: "Overall Top Month: December ($3.21M), November ($2.98M), June ($2.94M)."
    },
    "Q10": {
        title: "Q10: Pie Chart Data (Quarterly Revenue Distribution)",
        explanation: "Groups sales by Quarter to show percentage revenue share across Q1 - Q4.",
        code: `-- Q10: Quarterly Revenue Distribution
SELECT 
    CONCAT('Q', DATEPART(QUARTER, OrderDate)) AS Quarter,
    SUM(OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) AS TotalSales
FROM vw_EnrichedSales
GROUP BY DATEPART(QUARTER, OrderDate)
ORDER BY Quarter;`,
        summary: "Distribution: Q1 (18.81%), Q2 (24.15%), Q3 (26.02%), Q4 (31.02% top)."
    },
    "Q11": {
        title: "Q11: Combo Chart Data (Sales Amount vs Production Cost)",
        explanation: "Displays monthly Sales Amount and Production Cost side-by-side grouped by YearMonth (yyyy-MMM).",
        code: `-- Q11: Combo Chart (Sales vs Production Cost)
SELECT 
    FORMAT(OrderDate, 'yyyy-MMM') AS YearMonth,
    SUM(OrderQuantity * UnitPrice * (1 - UnitPriceDiscountPct)) AS SalesAmount,
    SUM(OrderQuantity * UnitCost) AS ProductionCost
FROM vw_EnrichedSales
GROUP BY YEAR(OrderDate), MONTH(OrderDate), FORMAT(OrderDate, 'yyyy-MMM')
ORDER BY YEAR(OrderDate), MONTH(OrderDate);`,
        summary: "Generated monthly comparison arrays for Revenue vs. Production Cost."
    },
    "Q12": {
        title: "Q12: KPI Breakdown (Products, Customers & Regions)",
        explanation: "Aggregates performance metrics by product categories, ranks customers with DENSE_RANK(), and summarizes regional sales.",
        code: `-- Q12A: Product Line Profit
SELECT pc.EnglishProductCategoryName, SUM(Profit) FROM vw_MasterSales GROUP BY Category;

-- Q12B: Customer DENSE_RANK()
SELECT DENSE_RANK() OVER (ORDER BY SUM(SalesAmount) DESC) AS Rank, CustomerName, SUM(SalesAmount) FROM vw_MasterSales GROUP BY Customer;

-- Q12C: Territory Revenue
SELECT t.SalesTerritoryCountry, SUM(SalesAmount) FROM vw_MasterSales s JOIN DimSalesTerritory t ON s.TerritoryKey = t.TerritoryKey GROUP BY Country;`,
        summary: "Top Category: Bikes ($11.51M profit) | Top Customer: Nichole Nara ($13.29k) | Top Country: USA ($9.39M)."
    },
    "Q13": {
        title: "Q13: Consolidated Executive Reporting View",
        explanation: "Creates dedicated SQL Views bringing together high-level executive summaries.",
        code: `-- Q13: Consolidated Executive Reporting View
CREATE VIEW vw_ExecutiveSummary AS
SELECT 
    YEAR(OrderDate) AS Year,
    COUNT(DISTINCT SalesOrderNumber) AS TotalOrders,
    SUM(SalesAmount) AS TotalRevenue,
    SUM(ProductionCost) AS TotalCost,
    SUM(Profit) AS TotalProfit
FROM vw_EnrichedSales
GROUP BY YEAR(OrderDate);`,
        summary: "Executive Summary View generated & verified successfully."
    }
};

document.addEventListener("DOMContentLoaded", () => {
    initNavigation();
    initSqlExplorer();
    loadDashboardData();
});

function initNavigation() {
    const navBtns = document.querySelectorAll(".nav-btn");
    const tabSections = document.querySelectorAll(".tab-section");
    const pageTitle = document.getElementById("page-title");

    const titles = {
        "overview": "Executive Sales Overview & Key Metrics",
        "tableau-charts": "Tableau Worksheets & SQL Aggregations (Q7 - Q11)",
        "tableau-performance": "Performance Analysis & Top 10 Reports (Q12)",
        "tableau-lookups": "Data Union & Dimension Lookups (Q0 - Q6)",
        "sqllab": "Minimalist SQL Student Code Explorer"
    };

    navBtns.forEach(btn => {
        btn.addEventListener("click", () => {
            const targetTab = btn.getAttribute("data-tab");
            
            navBtns.forEach(b => b.classList.remove("active"));
            tabSections.forEach(s => s.classList.remove("active"));

            btn.classList.add("active");
            document.getElementById(`tab-${targetTab}`).classList.add("active");
            pageTitle.textContent = titles[targetTab] || "Dashboard";
        });
    });
}

async function loadDashboardData() {
    try {
        const response = await fetch("data.json");
        globalData = await response.json();

        renderKPIs(globalData.kpis);
        renderCharts(globalData);
        renderTables(globalData);
    } catch (err) {
        console.error("Failed to load dashboard data:", err);
    }
}

function renderKPIs(kpis) {
    document.getElementById("kpi-sales").textContent = "$" + kpis.total_sales.toLocaleString(undefined, {minimumFractionDigits: 2});
    document.getElementById("kpi-cost").textContent = "$" + kpis.total_cost.toLocaleString(undefined, {minimumFractionDigits: 2});
    document.getElementById("kpi-profit").textContent = "$" + kpis.total_profit.toLocaleString(undefined, {minimumFractionDigits: 2});
    document.getElementById("kpi-orders").textContent = kpis.total_orders.toLocaleString();
    document.getElementById("kpi-margin").textContent = `KPI 3: ${kpis.profit_margin}% Profit Margin`;
    document.getElementById("kpi-records").textContent = kpis.total_records.toLocaleString();
}

function renderCharts(data) {
    // Sparkline Sales Trend
    chartInstances['sparkline'] = new Chart(document.getElementById("chart-sparkline"), {
        type: "line",
        data: {
            labels: data.sales_sparkline.map(d => d.YearMonth),
            datasets: [{
                label: "Sales Revenue ($)",
                data: data.sales_sparkline.map(d => d.Sales),
                borderColor: "#38bdf8",
                backgroundColor: "rgba(56, 189, 248, 0.1)",
                fill: true,
                borderWidth: 2,
                pointRadius: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { x: { display: false }, y: { display: false } }
        }
    });

    // Q8 YoY Bar Chart
    chartInstances['yoy'] = new Chart(document.getElementById("chart-yoy"), {
        type: "bar",
        data: {
            labels: data.q8_yoy_sales.map(d => d.Year),
            datasets: [{
                label: "Total Sales Amount ($)",
                data: data.q8_yoy_sales.map(d => d.Sales),
                backgroundColor: "#38bdf8",
                borderRadius: 6
            }]
        },
        options: chartOptions("$")
    });

    // Q10 Quarter Pie Chart
    chartInstances['quarter'] = new Chart(document.getElementById("chart-quarter"), {
        type: "doughnut",
        data: {
            labels: data.q10_quarterly_sales.map(d => d.Quarter),
            datasets: [{
                data: data.q10_quarterly_sales.map(d => d.Sales),
                backgroundColor: ["#38bdf8", "#818cf8", "#34d399", "#fb923c"]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: "bottom", labels: { color: "#f8fafc" } } }
        }
    });

    // Q9 Monthly Line Chart
    chartInstances['monthly'] = new Chart(document.getElementById("chart-monthly"), {
        type: "line",
        data: {
            labels: data.q9_monthly_sales.map(d => d.MonthName),
            datasets: [{
                label: "Monthly Sales ($)",
                data: data.q9_monthly_sales.map(d => d.Sales),
                borderColor: "#34d399",
                backgroundColor: "rgba(52, 211, 153, 0.15)",
                fill: true,
                tension: 0.3
            }]
        },
        options: chartOptions("$")
    });

    // Q11 Combo Chart
    chartInstances['combo'] = new Chart(document.getElementById("chart-combo"), {
        type: "bar",
        data: {
            labels: data.q11_combo_sales_cost.map(d => d.YearMonth),
            datasets: [
                {
                    label: "Sales Amount ($)",
                    data: data.q11_combo_sales_cost.map(d => d.Sales),
                    backgroundColor: "#0284c7"
                },
                {
                    label: "Production Cost ($)",
                    data: data.q11_combo_sales_cost.map(d => d.Cost),
                    backgroundColor: "#ea580c"
                }
            ]
        },
        options: chartOptions("$")
    });

    // Top 5 Product Subcategories
    chartInstances['top_subcat'] = new Chart(document.getElementById("chart-top-subcategories"), {
        type: "bar",
        data: {
            labels: data.top5_subcategories.map(d => d.Subcategory),
            datasets: [{
                label: "Sales Revenue ($)",
                data: data.top5_subcategories.map(d => d.Sales),
                backgroundColor: "#818cf8",
                borderRadius: 6
            }]
        },
        options: chartOptions("$")
    });

    // Top 10 Products Horizontal Bar Chart
    chartInstances['top_products'] = new Chart(document.getElementById("chart-top-products"), {
        type: "bar",
        data: {
            labels: data.top10_products.map(d => d.ProductName),
            datasets: [{
                label: "Sales Revenue ($)",
                data: data.top10_products.map(d => d.Sales),
                backgroundColor: "#34d399",
                borderRadius: 6
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { labels: { color: "#f8fafc" } } },
            scales: {
                x: { ticks: { color: "#94a3b8" }, grid: { color: "rgba(255,255,255,0.05)" } },
                y: { ticks: { color: "#94a3b8", font: { size: 10 } }, grid: { color: "rgba(255,255,255,0.05)" } }
            }
        }
    });

    // Q12C Regional Bar Chart
    chartInstances['regions'] = new Chart(document.getElementById("chart-regions"), {
        type: "bar",
        data: {
            labels: data.q12c_regions.map(d => d.Country),
            datasets: [{
                label: "Territory Revenue ($)",
                data: data.q12c_regions.map(d => d.Revenue),
                backgroundColor: "#fb923c",
                borderRadius: 6
            }]
        },
        options: chartOptions("$")
    });
}

function chartOptions(unit = "") {
    return {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { labels: { color: "#f8fafc" } } },
        scales: {
            x: { ticks: { color: "#94a3b8" }, grid: { color: "rgba(255,255,255,0.05)" } },
            y: { ticks: { color: "#94a3b8" }, grid: { color: "rgba(255,255,255,0.05)" } }
        }
    };
}

function renderTables(data) {
    renderQ7Table(data.q7_pivot_years['2013']);

    // Q12B Table
    const tbody12b = document.querySelector("#table-q12b tbody");
    tbody12b.innerHTML = data.q12b_top_customers.map(r => `
        <tr>
            <td><strong>#${r.Rank}</strong></td>
            <td>${r.CustomerFullName}</td>
            <td>$${r.Revenue.toLocaleString(undefined, {minimumFractionDigits: 2})}</td>
        </tr>
    `).join("");
}

function renderQ7Table(rows) {
    const tbody7 = document.querySelector("#table-q7 tbody");
    if (!rows || rows.length === 0) {
        tbody7.innerHTML = `<tr><td colspan="3">No sales data for selected year.</td></tr>`;
        return;
    }
    tbody7.innerHTML = rows.map(r => `
        <tr>
            <td>${r.MonthNo}</td>
            <td>${r.MonthName}</td>
            <td>$${r.Sales.toLocaleString(undefined, {minimumFractionDigits: 2})}</td>
        </tr>
    `).join("");
}

function onYearFilterChange(selectedYear) {
    document.getElementById("pivot-year-badge").textContent = `Filtered: ${selectedYear === 'all' ? 'All Years Combined' : 'Year ' + selectedYear}`;
    const rowData = globalData.q7_pivot_years[selectedYear];
    renderQ7Table(rowData);
}

function initSqlExplorer() {
    const qButtonsContainer = document.getElementById("q-buttons");
    
    Object.keys(minimalistSqlRepo).forEach((key, index) => {
        const btn = document.createElement("button");
        btn.className = `q-btn ${index === 0 ? 'active' : ''}`;
        btn.textContent = key + ": " + minimalistSqlRepo[key].title.split(":")[1].trim();
        btn.onclick = () => selectQuestion(key, btn);
        qButtonsContainer.appendChild(btn);
    });

    selectQuestion("Q0", qButtonsContainer.children[0]);
}

function selectQuestion(key, btnElem) {
    document.querySelectorAll(".q-btn").forEach(b => b.classList.remove("active"));
    if (btnElem) btnElem.classList.add("active");

    const qInfo = minimalistSqlRepo[key];
    document.getElementById("sql-q-title").textContent = qInfo.title;
    document.getElementById("sql-q-explanation").textContent = qInfo.explanation;
    document.getElementById("sql-code-snippet").textContent = qInfo.code;
    document.getElementById("sql-output-summary").textContent = qInfo.summary;
}

function copySqlCode() {
    const codeText = document.getElementById("sql-code-snippet").textContent;
    navigator.clipboard.writeText(codeText).then(() => {
        alert("Minimal SQL Code copied to clipboard!");
    });
}
