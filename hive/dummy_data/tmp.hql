--    DB: tmp2
--        Daily: daily_employee
--        Hourly: hourly_employee

SET hive.exec.dynamic.partition=true;

-- tmp2
CREATE SCHEMA IF NOT EXISTS tmp2;

DROP TABLE IF EXISTS tmp2.daily_employee;
CREATE TABLE IF NOT EXISTS tmp2.daily_employee (
    eid int,
    name String,
    salary String,
    destination String
)
PARTITIONED BY (year int, month int, day int)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS parquet;


INSERT INTO TABLE tmp2.daily_employee PARTITION (year=2020, month=04, day=06)
    VALUES
        (1, 'Kaden', '10000', 'Seoul'),
        (2, 'Barney', '20000', 'Berlin');

INSERT INTO TABLE tmp2.daily_employee PARTITION (year=2020, month=04, day=03)
    VALUES
        (3, 'Sungbin', '10000', 'Sinsa'),
        (4, 'Bob', '20000', 'NewYork');

DROP TABLE IF EXISTS tmp2.hourly_employee;
CREATE TABLE IF NOT EXISTS tmp2.hourly_employee (
    eid int,
    name String,
    salary String,
    destination String
)
COMMENT 'Employee schedule details'
PARTITIONED BY (year int, month int, day int, hh int)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS parquet;


INSERT INTO TABLE tmp2.hourly_employee PARTITION  (year=2020, month=04, day=03, hh=01)
    VALUES
        (1, 'Kaden', '10000', 'Seoul'),
        (2, 'Barney', '20000', 'Berlin');

INSERT INTO TABLE tmp2.hourly_employee PARTITION  (year=2020, month=04, day=03, hh=02)
    VALUES
        (3, 'Sungbin', '10000', 'Sinsa'),
        (4, 'Bob', '20000', 'NewYork');




-- csv 파일을 load해서 partition해서 테이블에 집어넣기
create external table if not exists emp(
    eid int, name String, salary String, destination String, 
    year int, month int, day int
    ) 
    row format delimited fields terminated by ',' 
    stored as textfile location '/tmp/emp/' 
    tblproperties("skip.header.line.count"="1");

select * from emp;

create table IF NOT EXISTS tmp2.emp_part( 
    eid int, name String, salary String, destination String) 
    partitioned by (year int, month int, day int) 
    row format delimited fields terminated by ',' stored as parquet;

set hive.exec.dynamic.partition.mode=nonstrict;

insert overwrite table tmp2.emp_part partition (year, month, day) select eid, name, salary, destination, year, month, day from emp;;