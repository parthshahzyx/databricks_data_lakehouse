-- Databricks notebook source
-- MAGIC %md
-- MAGIC #Initialization

-- COMMAND ----------

-- SQL needs no imports. Setting the catalog is the closest equivalent setup step.
USE CATALOG workspace;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC # Read Bronze table

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW bronze_cust AS
SELECT * FROM workspace.bronze.crm_cust_info;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #Silver Transformations

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##Trimming

-- COMMAND ----------

-- SQL can't loop over "all string columns" the way the Python loop does,
-- so each string column is trimmed by name.
CREATE OR REPLACE TEMP VIEW cust_trimmed AS
SELECT
    cst_id,
    TRIM(cst_key)            AS cst_key,
    TRIM(cst_firstname)      AS cst_firstname,
    TRIM(cst_lastname)       AS cst_lastname,
    TRIM(cst_marital_status) AS cst_marital_status,
    TRIM(cst_gndr)           AS cst_gndr,
    cst_create_date
FROM bronze_cust;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##Normalization

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW cust_normalized AS
SELECT
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    CASE
        WHEN UPPER(cst_marital_status) = 'S' THEN 'Single'
        WHEN UPPER(cst_marital_status) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_marital_status,
    CASE
        WHEN UPPER(cst_gndr) = 'F' THEN 'Female'
        WHEN UPPER(cst_gndr) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
FROM cust_trimmed;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ##Remove Records with Missing Customer ID

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW cust_filtered AS
SELECT *
FROM cust_normalized
WHERE cst_id IS NOT NULL;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Renaming Columns

-- COMMAND ----------

CREATE OR REPLACE TEMP VIEW cust_renamed AS
SELECT
    cst_id             AS customer_id,
    cst_key            AS customer_number,
    cst_firstname      AS first_name,
    cst_lastname       AS last_name,
    cst_marital_status AS marital_status,
    cst_gndr           AS gender,
    cst_create_date    AS created_date
FROM cust_filtered;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Sanity checks of dataframe

-- COMMAND ----------

SELECT * FROM cust_renamed LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC #Writing Silver Table

-- COMMAND ----------

CREATE OR REPLACE TABLE workspace.silver.crm_customers
USING DELTA
AS SELECT * FROM cust_renamed;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Sanity checks of silver table

-- COMMAND ----------

SELECT * FROM workspace.silver.crm_customers LIMIT 10;