-- Query public available table
SELECT station_id, name FROM
    bigquery-public-data.new_york_citibike.citibike_stations
LIMIT 100;


-- Creating external table referring to gcs path
CREATE OR REPLACE EXTERNAL TABLE `datatalksclub-380013.trips_data_all.external_yellow_tripdata`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://dtc_data_lake_datatalksclub-380013/data/yellow/yellow_tripdata_2021-*.parquet']
);

-- Check yello trip data
SELECT * FROM datatalksclub-380013.trips_data_all.external_yellow_tripdata limit 10;

-- Create a non partitioned table from external table
CREATE OR REPLACE TABLE datatalksclub-380013.trips_data_all.yellow_tripdata_non_partitoned AS
SELECT * FROM datatalksclub-380013.trips_data_all.external_yellow_tripdata;


-- Create a partitioned table from external table
CREATE OR REPLACE TABLE datatalksclub-380013.trips_data_all.yellow_tripdata_partitoned
PARTITION BY
  DATE(tpep_pickup_datetime) AS
SELECT * FROM datatalksclub-380013.trips_data_all.external_yellow_tripdata;

-- Impact of partition
-- Scanning 1.6GB of data - Ignore because I dind't ingest 2019 and 2020
SELECT DISTINCT(VendorID)
FROM datatalksclub-380013.trips_data_all.yellow_tripdata_non_partitoned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-01-01' AND '2021-03-31';

-- Scanning ~106 MB of DATA - Ignore because I dind't ingest 2019 and 2020
SELECT DISTINCT(VendorID)
FROM datatalksclub-380013.trips_data_all.yellow_tripdata_partitoned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-01-01' AND '2021-03-31';

-- Let's look into the partitons
SELECT table_name, partition_id, total_rows
FROM `trips_data_all.INFORMATION_SCHEMA.PARTITIONS`
WHERE table_name = 'yellow_tripdata_partitoned'
ORDER BY total_rows DESC;

-- Creating a partition and cluster table
CREATE OR REPLACE TABLE datatalksclub-380013.trips_data_all.yellow_tripdata_partitoned_clustered
PARTITION BY DATE(tpep_pickup_datetime)
CLUSTER BY VendorID_int AS
SELECT 
  *,
  CAST(VendorID AS INT64) AS VendorID_int
FROM datatalksclub-380013.trips_data_all.external_yellow_tripdata;

-- Query scans 1.1 GB - Ignore because I dind't ingest 2019 and 2020
SELECT count(*) as trips
FROM datatalksclub-380013.trips_data_all.yellow_tripdata_partitoned
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-06-01' AND '2021-12-31'
  AND VendorID=1;

-- Query scans 864.5 MB - Ignore because I dind't ingest 2019 and 2020
SELECT count(*) as trips
FROM datatalksclub-380013.trips_data_all.yellow_tripdata_partitoned_clustered
WHERE DATE(tpep_pickup_datetime) BETWEEN '2021-06-01' AND '2021-12-31'
  AND VendorID_str=1;
