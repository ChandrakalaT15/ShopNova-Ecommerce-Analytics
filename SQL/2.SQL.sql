
CREATE DATABASE shopnova_db;
USE shopnova_db;
SHOW DATABASES;

-- ---------Number od Rows-------------
SELECT COUNT(*) AS total_rows
FROM orders;
SELECT COUNT(*) AS total_rows
FROM Customers;
SELECT COUNT(*) AS total_rows
FROM Products;
SELECT COUNT(*) AS total_rows
FROM Campaigns;
SELECT COUNT(*) AS total_rows
FROM Returns;

-- ------- 10 rows in each table-----------
SELECT * FROM Orders LIMIT 10;
SELECT * FROM Customers LIMIT 10;
SELECT * FROM Products LIMIT 10;
SELECT * FROM Campaigns LIMIT 10;
SELECT * FROM Returns LIMIT 10;

-- --Checking Data Quality--------------
SELECT
    COUNT(*) AS total_rows,
    SUM(Order_ID IS NULL) AS missing_order_id,
    SUM(Order_Date IS NULL) AS missing_order_date,
    SUM(Customer_ID IS NULL) AS missing_customer_id,
    SUM(Product_ID IS NULL) AS missing_product_id,
    SUM(Quantity IS NULL) AS missing_quantity,
    SUM(Final_Amount_INR IS NULL) AS missing_final_amount
FROM Orders;

-- --Missing Values----------
SELECT
    COUNT(*) AS total_rows,
    SUM(Order_ID IS NULL) AS missing_order_id,
    SUM(Order_Date IS NULL) AS missing_order_date,
    SUM(Customer_ID IS NULL) AS missing_customer_id,
    SUM(Product_ID IS NULL) AS missing_product_id,
    SUM(Quantity IS NULL) AS missing_quantity,
    SUM(Final_Amount_INR IS NULL) AS missing_final_amount
FROM Orders;

-- ----Duplicate Order_id----
SELECT Order_ID,COUNT(*) AS duplicate_count
FROM Orders
GROUP BY Order_ID
HAVING COUNT(*) > 1
LIMIT 20;

-- ---available columns---------
SELECT TABLE_NAME,COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'shopnova_db'
  AND TABLE_NAME IN ('Orders','Customers','Products','Campaigns','Returns')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- --------KPIs-------------------
-- --------Challenge 1 — Revenue Visibility---------------

--  -----KPI 1 — Total GMV (Gross Merchandise Value)---------
SELECT ROUND(SUM(Gross_Amount_INR), 2) AS Total_GMV_INR
FROM Orders;

-- ----- KPI 2 — Net Revenue------------
SELECT ROUND(SUM(Net_Amount_INR), 2) AS Net_Revenue_INR
FROM Orders;

-- -----KPI 3 — Average Order Value (AOV)-----
SELECT ROUND(SUM(Net_Amount_INR) / COUNT(DISTINCT Order_ID),2) AS Average_Order_Value_INR
FROM Orders;

-- -----KPI 4 — Gross Profit Margin %.-------
SELECT ROUND(SUM(Gross_Profit_INR), 2) AS Total_Gross_Profit_INR,
       ROUND(SUM(Gross_Profit_INR) / NULLIF(SUM(Net_Amount_INR), 0) * 100,2) AS Gross_Profit_Margin_Pct
FROM Orders;

-- ------Challenge 2 — Marketing Spend Inefficiency---
-- -----KPI 5 — Total Marketing Spend--------
USE shopnova_db;
SELECT ROUND(SUM(Amount_Spent_INR), 2) AS Total_Marketing_Spend_INR
FROM Campaigns;

-- --------KPI 6 — Return on Ad Spend (ROAS)--------
SELECT ROUND(SUM(Revenue_Generated_INR) /NULLIF(SUM(Amount_Spent_INR), 0),2) AS Overall_ROAS
FROM Campaigns;

-- -------KPI 7 — Customer Acquisition Cost (CAC)----------
SELECT ROUND(SUM(Amount_Spent_INR) /NULLIF(SUM(New_Customers_Acquired), 0),2) AS Customer_Acquisition_Cost_INR
FROM Campaigns;

-- ------Challenge 3 — Returns--------------
-- ------KPI 8: Return Rate %---------------
USE shopnova_db;
SELECT COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    (SELECT COUNT(DISTINCT o.Order_ID)
	 FROM Orders o) AS Total_Orders,ROUND(COUNT(DISTINCT r.Order_ID) * 100.0 /NULLIF((SELECT COUNT(DISTINCT o.Order_ID)
                                                                                      FROM Orders o),0),2) AS Return_Rate_Pct
FROM Returns r;

-- -----KPI 9 — Total Refund Amount -----------
SELECT ROUND(SUM(Refund_Amount_INR), 2) AS Total_Refund_Amount_INR
FROM Returns;

-- -----Challenge 4 — Customer Retention-----------
-- ------KPI 10: Repeat Purchase Rate %-----------
USE shopnova_db;
SELECT COUNT(*) AS Total_Customers,SUM(CASE
									   WHEN order_counts.Order_Count > 1 THEN 1
                                       ELSE 0
                                       END) AS Repeat_Customers,
    ROUND(SUM(CASE
              WHEN order_counts.Order_Count > 1 THEN 1
              ELSE 0 
              END) * 100.0 /NULLIF(COUNT(*), 0),2) AS Repeat_Purchase_Rate_Pct
FROM (SELECT Customer_ID,COUNT(DISTINCT Order_ID) AS Order_Count
      FROM Orders
      WHERE Customer_ID IS NOT NULL
      GROUP BY Customer_ID) AS order_counts;
      
-- -----------KPI 11 — Customer Lifetime Value (CLV)----------
SELECT COUNT(*) AS Total_Customers,ROUND(AVG(Customer_Revenue), 2)AS Average_Customer_Lifetime_Value_INR
FROM (SELECT Customer_ID,SUM(Net_Amount_INR) AS Customer_Revenue
      FROM Orders
      WHERE Customer_ID IS NOT NULL
      GROUP BY Customer_ID) AS customer_values;
      
-- ----Challenge 5 — Operational SLA Breaches--------
-- ---------KPI 12: Average Shipping Days-----------
SELECT COUNT(Shipping_Days) AS Orders_With_Shipping_Data,
       ROUND(AVG(Shipping_Days), 2) AS Average_Shipping_Days,3 AS SLA_Target_Days,
       ROUND(AVG(Shipping_Days) - 3, 2) AS Days_Above_SLA
FROM Orders;

-- ------KPI 13 — SLA Breach Rate %--------
SELECT COUNT(Shipping_Days) AS Orders_With_Shipping_Data,
       SUM(CASE
		   WHEN Shipping_Days > 3 THEN 1
		   ELSE 0
           END) AS SLA_Breached_Orders,
       ROUND(SUM(CASE
			     WHEN Shipping_Days > 3 THEN 1
			     ELSE 0
                 END) * 100.0 /NULLIF(COUNT(Shipping_Days), 0),2) AS SLA_Breach_Rate_Pct
FROM Orders
WHERE Shipping_Days IS NOT NULL;

-- -----Chart analysis-----------------
-- ----------Challenge 1 — Revenue Visibility-------------
-- ------Chart 1 — Revenue Trend------------------
SELECT YEAR(Order_Date) AS Order_Year,MONTH(Order_Date) AS Month_Number,DATE_FORMAT(Order_Date, '%b') AS Month_Name,
    ROUND(SUM(Gross_Amount_INR), 2) AS GMV_INR,
    ROUND(SUM(Net_Amount_INR), 2) AS Net_Revenue_INR,
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM Orders
WHERE Order_Date IS NOT NULL
GROUP BY YEAR(Order_Date),MONTH(Order_Date),DATE_FORMAT(Order_Date, '%b')
ORDER BY Order_Year,Month_Number;

-- -------Chart 2 — Revenue by Category--------
SELECT Category,ROUND(SUM(Gross_Amount_INR), 2) AS GMV_INR,
    ROUND(SUM(Net_Amount_INR), 2) AS Net_Revenue_INR,
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM Orders
WHERE Category IS NOT NULL
GROUP BY Category
ORDER BY Net_Revenue_INR DESC;

-- -------Chart 3 — Revenue by Brand--------------
SELECT Brand,ROUND(SUM(Gross_Amount_INR), 2) AS GMV_INR,
    ROUND(SUM(Net_Amount_INR), 2) AS Net_Revenue_INR,
    COUNT(DISTINCT Order_ID) AS Total_Orders
FROM Orders
WHERE Brand IS NOT NULL
GROUP BY Brand
ORDER BY Net_Revenue_INR DESC;

-- -----Chart 4 — Revenue by Region-----------
SELECT c.State AS Region,
    ROUND(SUM(o.Gross_Amount_INR), 2) AS GMV_INR,ROUND(SUM(o.Net_Amount_INR), 2) AS Net_Revenue_INR,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,COUNT(DISTINCT o.Customer_ID) AS Unique_Customers
FROM Orders o
INNER JOIN Customers c
    ON o.Customer_ID = c.Customer_ID
WHERE c.State IS NOT NULL
GROUP BY c.State
ORDER BY Net_Revenue_INR DESC;

-- -----Challenge 2: Marketing Spend Inefficiency--------
-- -----Chart 5 — ROAS by Marketing Channel----------
SELECT Channel,ROUND(SUM(Amount_Spent_INR), 2) AS Marketing_Spend_INR,
			   ROUND(SUM(Revenue_Generated_INR), 2) AS Revenue_Generated_INR,
               ROUND(SUM(Revenue_Generated_INR) /NULLIF(SUM(Amount_Spent_INR), 0),2) AS ROAS
FROM Campaigns
WHERE Channel IS NOT NULL
GROUP BY Channel
ORDER BY ROAS DESC;

-- ---------Chart 6 — CAC by Marketing Channel--------
SELECT Channel,ROUND(SUM(Amount_Spent_INR), 2) AS Marketing_Spend_INR,
    SUM(New_Customers_Acquired) AS New_Customers_Acquired,
    ROUND(SUM(Amount_Spent_INR) /NULLIF(SUM(New_Customers_Acquired), 0),2) AS CAC_INR
FROM Campaigns
WHERE Channel IS NOT NULL
GROUP BY Channel
ORDER BY CAC_INR ASC;
      
-- -------Chart 7 — Marketing Spend vs Revenue by Channel-----------
SELECT Channel,ROUND(SUM(Amount_Spent_INR), 2) AS Marketing_Spend_INR,
               ROUND(SUM(Revenue_Generated_INR), 2) AS Revenue_Generated_INR,
               ROUND(SUM(Revenue_Generated_INR) -SUM(Amount_Spent_INR),2) AS Revenue_Minus_Spend_INR,
               ROUND(SUM(Revenue_Generated_INR) /NULLIF(SUM(Amount_Spent_INR), 0),2) AS ROAS
FROM Campaigns
WHERE Channel IS NOT NULL
GROUP BY Channel
ORDER BY Revenue_Generated_INR DESC;
      
-- ----------Challenge 3 — Rising Return Rate------------
-- ----------Chart 8 — Return Rate by Category-------------
SELECT o.Category,COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    ROUND(COUNT(DISTINCT r.Order_ID) * 100.0 /NULLIF(COUNT(DISTINCT o.Order_ID), 0),2) AS Return_Rate_Pct
FROM Orders o
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
WHERE o.Category IS NOT NULL
GROUP BY o.Category
ORDER BY Return_Rate_Pct DESC;

-- ----------Chart 9 — Return Reasons Analysis-------------------
SELECT Return_Reason,
    COUNT(DISTINCT Return_ID) AS Total_Returns,
    ROUND(SUM(Refund_Amount_INR),2) AS Total_Refund_Amount_INR,
    ROUND(AVG(Resolution_Days),2) AS Avg_Resolution_Days
FROM Returns
WHERE Return_Reason IS NOT NULL
GROUP BY Return_Reason
ORDER BY Total_Returns DESC;

-- --------Chart 10 — Quarterly Return Trend----------
SELECT o.Year,o.Quarter,
    COUNT(DISTINCT o.Order_ID) AS Total_Orders,
    COUNT(DISTINCT r.Order_ID) AS Returned_Orders,
    ROUND(COUNT(DISTINCT r.Order_ID) * 100.0 /NULLIF(COUNT(DISTINCT o.Order_ID), 0),2) AS Return_Rate_Pct
FROM Orders o
LEFT JOIN Returns r
    ON o.Order_ID = r.Order_ID
GROUP BY o.Year, o.Quarter
ORDER BY o.Year, MIN(o.Order_Date);

-- ------------Challenge 4 — Customer Retention Declining-------
-- --------Chart 11 — Repeat Purchase Trend-----------
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
       COUNT(DISTINCT Customer_ID) AS Active_Customers,
       COUNT(DISTINCT CASE
                      WHEN TRIM(Is_Repeat_Customer) = 'Yes'
                      THEN Customer_ID
                      END) AS Repeat_Customers,
	   ROUND(COUNT(DISTINCT CASE
                            WHEN TRIM(Is_Repeat_Customer) = 'Yes'
							THEN Customer_ID
                            END) * 100.0 /NULLIF(COUNT(DISTINCT Customer_ID), 0),2) AS Repeat_Purchase_Rate_Pct
FROM Orders
WHERE Order_Date IS NOT NULL
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY Month;

-- ------Chart 12 — Customer Segmentation (New, Regular, Premium, VIP)----------
SELECT Customer_Segment,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    ROUND(SUM(Total_Spend_Lifetime_INR),2) AS Total_Lifetime_Spend_INR,
    ROUND(AVG(Total_Spend_Lifetime_INR),2) AS Avg_Lifetime_Spend_INR
FROM Customers
GROUP BY Customer_Segment
ORDER BY Total_Customers DESC;

-- ------Chart 13 — Customer Value by Segment----------
SELECT Customer_Segment,
    COUNT(DISTINCT Customer_ID) AS Total_Customers,
    ROUND(AVG(Total_Spend_Lifetime_INR),2) AS Avg_Customer_Value_INR,
    ROUND(SUM(Total_Spend_Lifetime_INR),2) AS Total_Segment_Value_INR
FROM Customers
GROUP BY Customer_Segment
ORDER BY Avg_Customer_Value_INR DESC;

-- -------Challenge 5 — Operational SLA Breaches----------
-- ---------Chart 14 — Average Shipping Days vs 3-Day SLA-----
SELECT Order_Channel,
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    ROUND(AVG(Shipping_Days), 2) AS Avg_Shipping_Days,3 AS SLA_Target_Days,
    COUNT(DISTINCT CASE
                   WHEN Shipping_Days > 3 THEN Order_ID
                   END) AS SLA_Breached_Orders,
    ROUND(COUNT(DISTINCT CASE
                         WHEN Shipping_Days > 3 THEN Order_ID
						 END) * 100.0 /NULLIF(COUNT(DISTINCT CASE
															 WHEN Shipping_Days IS NOT NULL THEN Order_ID
                                                             END), 0),2) AS SLA_Breach_Rate_Pct
FROM Orders
WHERE Shipping_Days IS NOT NULL
GROUP BY Order_Channel
ORDER BY Avg_Shipping_Days DESC;

-- ---------Chart 15 — Monthly Shipping Trend-------
SELECT DATE_FORMAT(Order_Date, '%Y-%m') AS Month,
       COUNT(DISTINCT Order_ID) AS Total_Orders,
       ROUND(AVG(Shipping_Days), 2) AS Avg_Shipping_Days,3 AS SLA_Target_Days,
       ROUND(SUM(CASE
				 WHEN Shipping_Days > 3 THEN 1
                 ELSE 0
                 END) * 100.0 /NULLIF(COUNT(Shipping_Days), 0),2) AS SLA_Breach_Rate_Pct
FROM Orders
WHERE Order_Date IS NOT NULL
  AND Shipping_Days IS NOT NULL
GROUP BY DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY Month;

