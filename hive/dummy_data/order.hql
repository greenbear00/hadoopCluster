--    DB: simple
--       users
-- "users"
--     id = Column('id', String(30), primary_key=True)  # 01073000217
--     name = Column('name', String(30))  # greenbear
--     passwd = Column('passwd', String(120))
--     cret_dt = Column('cret_dt', DateTime)

SET hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;

-- create schema simple
CREATE SCHEMA IF NOT EXISTS simple;



drop table IF EXISTS users;
create external table if not exists users (
    id String,
    name String,
    passwd String,
    cret_dt Timestamp
) row format delimited 
fields terminated by ',' 
stored as textfile 
location '/simple/users'
tblproperties ('externaltable.purge'='true',
"skip.header.line.count"="1");
-- location 'hdfs://namenode:9000/warehouse/tablespace/external/hive/simple/users' 




-- create managed table users
-- hdfs://namenode:9000/warehouse/tablespace/managed/hive/simple.db/users
DROP TABLE IF EXISTS simple.users;
CREATE TABLE IF NOT EXISTS simple.users (
    id String,
    name String,
    passwd String,
    cret_dt Timestamp
) clustered by (id) into 10 buckets 
row format delimited
stored as orc
tblproperties( 
    "transactional"="true",
    "skip.header.line.count"="1",
    "compactor.mapreduce.map.memory.mb"="2048",
    "compactorthreshold.hive.compactor.delta.num.threshold"="4",
    "compactorthreshold.hive.compactor.delta.pct.threshold"="0.5");

-- -- create table product
-- DROP TABLE IF EXISTS simple.product;
-- CREATE TABLE IF NOT EXISTS simple.product (
--     id String,
--     name String,
--     price Double,
--     total int
-- ) clustered by (name) into 2 buckets stored as orc
-- tblproperties( 
--     "transactional"="true",
--     "compactor.mapreduce.map.memory.mb"="2048",
--     "compactorthreshold.hive.compactor.delta.num.threshold"="4",
--     "compactorthreshold.hive.compactor.delta.pct.threshold"="0.5");

-- INSERT INTO TABLE simple.product 
-- VALUES
--     ('1', 'pen', 1000.0, 100),
--     ('2', 'note', 2000.0, 100),
--     ('3', 'wrapping paper', 1000.0, 100),
--     ('4', 'a drinking glass', 10000.0, 10);

-- -- create table order
-- DROP TABLE IF EXISTS simple.orders;
-- CREATE TABLE IF NOT EXISTS simple.orders (
--     id String,
--     order_date timestamp,
--     user_id String,
--     agnet String
-- ) clustered by (order_date) into 2 buckets stored as orc
-- tblproperties( 
--     "transactional"="true",
--     "compactor.mapreduce.map.memory.mb"="2048",
--     "compactorthreshold.hive.compactor.delta.num.threshold"="4",
--     "compactorthreshold.hive.compactor.delta.pct.threshold"="0.5");


-- -- create table order_detail
-- DROP TABLE IF EXISTS simple.order_detail;
-- CREATE TABLE IF NOT EXISTS simple.order_detail (
--     id String,
--     order_date timestamp,
--     user_id String,
--     product_id String,
--     cupon_id String
-- ) clustered by (order_date) into 2 buckets stored as orc
-- tblproperties( 
--     "transactional"="true",
--     "compactor.mapreduce.map.memory.mb"="2048",
--     "compactorthreshold.hive.compactor.delta.num.threshold"="4",
--     "compactorthreshold.hive.compactor.delta.pct.threshold"="0.5");



-- -- crate table cupon
-- DROP TABLE IF EXISTS simple.cupon;
-- CREATE TABLE IF NOT EXISTS simple.cupon (
--     id String,
--     percentage Double,
--     used String default 'N'
-- ) clustered by (used) into 2 buckets stored as orc
-- tblproperties( 
--     "transactional"="true",
--     "compactor.mapreduce.map.memory.mb"="2048",
--     "compactorthreshold.hive.compactor.delta.num.threshold"="4",
--     "compactorthreshold.hive.compactor.delta.pct.threshold"="0.5");

-- INSERT INTO TABLE simple.cupon 
-- VALUES
--     (1, 10.0, 'N'),
--     (2, 10.0, 'N');



-- -- create table grade 
-- DROP TABLE IF EXISTS simple.grade;
-- CREATE TABLE IF NOT EXISTS simple.grade (
--     id String,
--     name String,
--     order_count int,
--     price_amount Double
-- ) clustered by (id) into 2 buckets stored as orc
-- tblproperties( 
--     "transactional"="true",
--     "compactor.mapreduce.map.memory.mb"="2048",
--     "compactorthreshold.hive.compactor.delta.num.threshold"="4",
--     "compactorthreshold.hive.compactor.delta.pct.threshold"="0.5");
