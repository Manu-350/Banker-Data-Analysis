CREATE DATABASE LOANS;

--TASK01
--Q1.Data Base Created
--Q2.Imported 4 CSV Files and Generated 4 Tables in Database
Select * from [dbo].[Banker];

Select * from [dbo].[Customer];

Select * from [dbo].[HomeLoan];

Select * from [dbo].[LoanRecords];

--Q3 Query to print all the databases available in SQL
Select Name As DatabaseNames From Sys.databases

--Q4 Query to print the names of the tables from Loans Database
Select * from INFORMATION_SCHEMA.TABLES

--Q5 Write a Query to print 5 records in each table
Select Top 5 * from [dbo].[Banker]
Select Top 5 * from [dbo].[Customer]
Select Top 5 * from [dbo].[HomeLoan]
Select Top 5 * from [dbo].[LoanRecords]

--TASK02
--Q1 Find the Number of Home Loans issued in Sanfransico
Select Count(*) AS Noofomeloan from [dbo].[HomeLoan]  Where [city] IN ('San Francisco')

--Q2 Find the Avg Age of Male Bankers
Select ROUND(AVG(DATEDIFF(YEAR,[dob],[date_joined])),1) AS AVGAGE From [dbo].[Banker] WHERE [gender] = 'Male'

--Q3 AVG Loan Terms
Select AVG([loan_term]) AS AVGLoanterm from [dbo].[HomeLoan] Where [city] 
IN ('Sparks', 'Biloxi', 'Las Vegas', 'Lansing', 'Waco') AND [property_type] IN ('Detached', 'Condominium')

--Q4 Avg Age of Female Customers
Select[gender], AVG(DATEDIFF(YEAR,[dob],[transaction_date])) AS AVGAGE From [dbo].[Customer] C LEFT JOIN [dbo].[LoanRecords] L ON C.customer_id = L.record_id 
INNER JOIN [dbo].[HomeLoan] H ON L.loan_id = H.loan_id
WHERE [gender] = 'Female' AND [property_type] IN ('townhome') AND [joint_loan] IN ('0')
GROUP BY [gender]

--Q5 Max Property Value for each property type
Select [property_type], MAX([property_value]) AS Maxvalue from [dbo].[HomeLoan]
GROUP BY [property_type]
ORDER BY Maxvalue DESC

--Q6 Top 3 Cities with Loan Percentage and Lowest Avg Loan Perct
Select TOP 3 [city], AVG([loan_percent]) AS AVGLOANPER from [dbo].[HomeLoan]
GROUP BY [city]
ORDER BY [city] DESC, AVGLOANPER ASC

--Q7 Find City Name and Avg Property Value > $3,000,000
Select [city], AVG([property_value]) AS Prpvalue from [dbo].[HomeLoan]
Group BY [city]
Having AVG([property_value]) > '3000000'
ORDER BY Prpvalue DESC

--Q8 Top 2 Bankers Involved in highest number of distinct loan records
Select TOP 2 Count(DISTINCT [record_id]) AS RecordsCount, B.[banker_id],
[first_name], [last_name]
from [dbo].[Banker] B INNER JOIN [dbo].[LoanRecords] L ON B.banker_id = L.banker_id
GROUP BY [first_name], [last_name], B.banker_id 
ORDER BY RecordsCount DESC

--Q9 Total Number of Diiferent Cities where home loans have been issued
Select Count(DISTINCT [city]) CityCount from [dbo].[HomeLoan] H INNER JOIN [dbo].[LoanRecords] L ON H.loan_id = L.loan_id

--Q10 Customer emails contains 'Amazon'
Select customer_id, [first_name], [last_name], [email] from [dbo].[Customer]
Where [email] LIKE '%Amazon%'

--TASK 03
--Q1 Create Stored Procedure
--Since we dont have a column called Loan Amount, it has careated
ALTER TABLE [dbo].[HomeLoan] ADD LoanAmount DECIMAL (18, 2)
UPDATE [dbo].[HomeLoan] SET [LoanAmount] = ([property_value] * [loan_percent])/100
Select [LoanAmount] from [dbo].[HomeLoan]
Select * from [dbo].[HomeLoan]
--
CREATE PROCEDURE city_and_above_loan_amt2
@city_name NVARCHAR(50),
@loan_amt_cutoff DECIMAL(18,2)
AS
BEGIN
Select C.customer_id,
[first_name],[last_name],[email],[gender],[property_type],[city],[LoanAmount]
from [dbo].[Customer] C LEFT JOIN [dbo].[LoanRecords] L ON C.customer_id = L.record_id 
INNER JOIN [dbo].[HomeLoan] H ON L.loan_id = H.loan_id
WHERE
[city] = @city_name
AND
[LoanAmount] >= @loan_amt_cutoff;
END

EXEC city_and_above_loan_amt2 @city_name = 'San Francisco', @loan_amt_cutoff = 1500000


--Q2 List of Customers who are served by Bankers Aged below 30 as on Aug 01 2022
Select C.[customer_id], CONCAT(C.[first_name],' ',C.[last_name]) AS Fullname from [dbo].[Customer]  C LEFT JOIN [dbo].[LoanRecords] L ON C.customer_id = L.record_id 
INNER JOIN [dbo].[Banker] B ON L.banker_id = B.banker_id
Where (DATEDIFF(YEAR,B.[dob],'2022-08-01') <30)

--Q3 Top 3 Transcation dates and Corresponding Loan Amount
Select TOP 3([transaction_date]),
SUM([LoanAmount]) AS Totalamount
from [dbo].[LoanRecords] L LEFT JOIN [dbo].[HomeLoan] H ON L.loan_id = H.loan_id
GROUP BY [transaction_date]
ORDER BY Totalamount DESC

--Q4 Find the number of chinees customers with the conditions below
Select Count(DISTINCT C.[customer_id]) AS ChineeseCust
from [dbo].[Customer]  C LEFT JOIN [dbo].[LoanRecords] L ON C.customer_id = L.record_id 
INNER JOIN [dbo].[HomeLoan] H ON L.loan_id = H.loan_id INNER JOIN [dbo].[Banker] B ON L.banker_id = L.banker_id
WHERE C.[nationality] IN ('China') AND [joint_loan] IN ('1') AND [property_value] < 2100000 AND B.[gender] IN ('Female')


--Q5 create a stored procedure
CREATE PROCEDURE recent_joiners
AS
BEGIN
Select 
[banker_id], 
CONCAT([first_name],' ',[last_name]) AS Fullname,
[dob],[date_joined]
From [dbo].[Banker]
WHERE DATEDIFF(YEAR,[date_joined], '2022-09-01') <=2;
END

EXEC recent_joiners;


--Q6 Find the sum of loan amounts excluding cities Dallas and Waco (Loan Amount Column has been already derived in above queries)
Select B.[banker_id],
SUM([LoanAmount]) As TotalLoanAmt from [dbo].[HomeLoan] H LEFT JOIN [dbo].[LoanRecords] L ON H.loan_id = L.loan_id
INNER JOIN [dbo].[Banker] B ON L.banker_id = B.banker_id
Where [city] NOT IN ('Dallas','Waco')
GROUP BY B.banker_id
ORDER BY TotalLoanAmt DESC

--Q7 Find the no of bankers involved in a loan where the loan amt is greater than the avg loan amount
Select Count(DISTINCT B.[banker_id]) As NoofBankers from [dbo].[Banker] B LEFT JOIN [dbo].[LoanRecords] L ON B.banker_id = L.banker_id
INNER JOIN [dbo].[HomeLoan] H ON L.loan_id = H.loan_id
WHERE H.[LoanAmount]> (Select AVG(H.[LoanAmount]) from [dbo].[Banker] B LEFT JOIN [dbo].[LoanRecords] L ON B.banker_id = L.banker_id
INNER JOIN [dbo].[HomeLoan] H ON L.loan_id = H.loan_id)

--Q8 Tenure
Select C.[customer_id], C.[first_name], C.[last_name],
CASE
WHEN [customer_since] < '2015-01-01' then 'Long'
WHEN [customer_since] >= '2015-01-01' AND [customer_since] < '2019-01-01' then 'Mid'
WHEN [customer_since] >= '2019-01-01' then 'Short'
END AS Tenure
From [dbo].[Customer] C LEFT JOIN [dbo].[LoanRecords] L ON C.customer_id = L.record_id 
INNER JOIN [dbo].[HomeLoan] H ON L.loan_id = H.loan_id
WHERE [property_value] BETWEEN 1500000 AND 1900000

--Q9 Create View 
CREATE VIEW dallas_townhomes_gte_1m AS
(Select * from [dbo].[HomeLoan] 
Where [property_type] IN ('Townhome')
AND [city] IN ('Dallas')
AND [LoanAmount] > 1000000);

Select * from dallas_townhomes_gte_1m;


--Completed--


