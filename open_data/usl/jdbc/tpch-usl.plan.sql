-- Worked example for the TPC-H datasource bundled with the local Zetaris
-- platform. Adapt every identifier and source mapping for other environments.

-- @statement create_namespace
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.tpch

-- @statement compile_usl
COMPILE USL IF NOT EXISTS tpch_usl
DEPLOY NAMESPACE lightning.metastore.tpch DDL
CREATE TABLE region (
  r_regionkey int NOT NULL PRIMARY KEY,
  r_name varchar(25) NOT NULL,
  r_comment varchar(152)
);

CREATE TABLE nation (
  n_nationkey int NOT NULL PRIMARY KEY,
  n_name varchar(25) NOT NULL,
  n_regionkey int NOT NULL FOREIGN KEY REFERENCES region(r_regionkey),
  n_comment varchar(152)
);

CREATE TABLE supplier (
  s_suppkey int NOT NULL PRIMARY KEY,
  s_name varchar(25) NOT NULL,
  s_address varchar(40),
  s_nationkey int NOT NULL FOREIGN KEY REFERENCES nation(n_nationkey),
  s_phone varchar(15),
  s_acctbal decimal(15,2),
  s_comment varchar(101)
);

CREATE TABLE part (
  p_partkey int NOT NULL PRIMARY KEY,
  p_name varchar(55) NOT NULL,
  p_mfgr varchar(25),
  p_brand varchar(10),
  p_type varchar(25),
  p_size int,
  p_container varchar(10),
  p_retailprice decimal(15,2),
  p_comment varchar(23)
);

CREATE TABLE customer (
  c_custkey int NOT NULL PRIMARY KEY,
  c_name varchar(25) NOT NULL,
  c_address varchar(40),
  c_nationkey int NOT NULL FOREIGN KEY REFERENCES nation(n_nationkey),
  c_phone varchar(15),
  c_acctbal decimal(15,2),
  c_mktsegment varchar(10),
  c_comment varchar(117)
);

CREATE TABLE orders (
  o_orderkey int NOT NULL PRIMARY KEY,
  o_custkey int NOT NULL FOREIGN KEY REFERENCES customer(c_custkey),
  o_orderstatus varchar(1),
  o_totalprice decimal(15,2),
  o_orderdate date,
  o_orderpriority varchar(15),
  o_clerk varchar(15),
  o_shippriority int,
  o_comment varchar(79)
);

CREATE TABLE partsupp (
  ps_partkey int NOT NULL FOREIGN KEY REFERENCES part(p_partkey),
  ps_suppkey int NOT NULL FOREIGN KEY REFERENCES supplier(s_suppkey),
  ps_availqty int,
  ps_supplycost decimal(15,2),
  ps_comment varchar(199)
);

CREATE TABLE lineitem (
  l_orderkey int NOT NULL FOREIGN KEY REFERENCES orders(o_orderkey),
  l_partkey int NOT NULL FOREIGN KEY REFERENCES part(p_partkey),
  l_suppkey int NOT NULL FOREIGN KEY REFERENCES supplier(s_suppkey),
  l_linenumber int NOT NULL,
  l_quantity decimal(15,2),
  l_extendedprice decimal(15,2),
  l_discount decimal(15,2),
  l_tax decimal(15,2),
  l_returnflag varchar(1),
  l_linestatus varchar(1),
  l_shipdate date,
  l_commitdate date,
  l_receiptdate date,
  l_shipinstruct varchar(25),
  l_shipmode varchar(10),
  l_comment varchar(44)
)

-- @statement activate_region
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.region AS
SELECT r_regionkey, r_name, r_comment FROM TPCH.region

-- @statement activate_nation
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.nation AS
SELECT n_nationkey, n_name, n_regionkey, n_comment FROM TPCH.nation

-- @statement activate_supplier
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.supplier AS
SELECT s_suppkey, s_name, s_address, s_nationkey, s_phone, s_acctbal, s_comment
FROM TPCH.supplier

-- @statement activate_part
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.part AS
SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container,
       p_retailprice, p_comment
FROM TPCH.part

-- @statement activate_customer
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.customer AS
SELECT c_custkey, c_name, c_address, c_nationkey, c_phone, c_acctbal,
       c_mktsegment, c_comment
FROM TPCH.customer

-- @statement activate_orders
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.orders AS
SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate,
       o_orderpriority, o_clerk, o_shippriority, o_comment
FROM TPCH.orders

-- @statement activate_partsupp
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.partsupp AS
SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, ps_comment
FROM TPCH.partsupp

-- @statement activate_lineitem
ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.lineitem AS
SELECT l_orderkey, l_partkey, l_suppkey, l_linenumber, l_quantity,
       l_extendedprice, l_discount, l_tax, l_returnflag, l_linestatus,
       l_shipdate, l_commitdate, l_receiptdate, l_shipinstruct, l_shipmode,
       l_comment
FROM TPCH.lineitem

-- @verify compare_row_counts
SELECT 'region' AS table_name,
       (SELECT COUNT(*) FROM TPCH.region) AS source_rows,
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.region) AS usl_rows
UNION ALL
SELECT 'nation',
       (SELECT COUNT(*) FROM TPCH.nation),
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.nation)
UNION ALL
SELECT 'supplier',
       (SELECT COUNT(*) FROM TPCH.supplier),
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.supplier)
UNION ALL
SELECT 'part',
       (SELECT COUNT(*) FROM TPCH.part),
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.part)
UNION ALL
SELECT 'customer',
       (SELECT COUNT(*) FROM TPCH.customer),
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.customer)
UNION ALL
SELECT 'orders',
       (SELECT COUNT(*) FROM TPCH.orders),
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.orders)
UNION ALL
SELECT 'partsupp',
       (SELECT COUNT(*) FROM TPCH.partsupp),
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.partsupp)
UNION ALL
SELECT 'lineitem',
       (SELECT COUNT(*) FROM TPCH.lineitem),
       (SELECT COUNT(*) FROM lightning.metastore.tpch.tpch_usl.lineitem)

-- @verify representative_query
SELECT n.n_name, COUNT(*) AS customer_count
FROM lightning.metastore.tpch.tpch_usl.customer c
JOIN lightning.metastore.tpch.tpch_usl.nation n
  ON c.c_nationkey = n.n_nationkey
GROUP BY n.n_name
ORDER BY customer_count DESC
LIMIT 10
