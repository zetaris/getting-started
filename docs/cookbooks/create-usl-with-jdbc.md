# Cookbook: Create a USL with the Zetaris JDBC driver

This recipe creates a Unified Semantic Layer (USL) over the bundled TPC-H
sample datasource. It was live-tested with Zetaris Platform 2.4.3 and the
`ndp-jdbc-driver-2.1.0.13-driver.jar` driver.

The finished model is:

```text
lightning.metastore.tpch.tpch_usl
```

It contains eight active tables: `region`, `nation`, `supplier`, `part`,
`customer`, `orders`, `partsupp`, and `lineitem`.

## Prerequisites

- A running local Zetaris platform with the bundled `TPCH` datasource.
- A JDK with `java` and `javac` available.
- The Zetaris JDBC driver JAR.
- The platform administrator email and password in environment variables.

From the platform directory, first check the deployment:

```bash
./verify.sh
```

The final line should say that all checks passed.

## Run the recipe

Set the values for your environment. Do not commit the password or put it in
the Java source.

```bash
export ZETARIS_ADMIN_EMAIL='admin@zetaris.com'
export ZETARIS_ADMIN_PASSWORD='<your-password>'
export ZETARIS_JDBC_URL='jdbc:zetaris:lightning@127.0.0.1:10000'
export ZETARIS_JDBC_JAR='/path/to/ndp-jdbc-driver-2.1.0.13-driver.jar'
```

Compile and run the checked-in helper:

```bash
mkdir -p /tmp/zetaris-usl-build
javac -proc:none -d /tmp/zetaris-usl-build \
  -cp "$ZETARIS_JDBC_JAR" \
  open_data/usl/jdbc/CreateTpchUsl.java

java -cp "/tmp/zetaris-usl-build:$ZETARIS_JDBC_JAR" CreateTpchUsl
```

The helper performs the complete lifecycle:

1. Creates `lightning.metastore.tpch` if it does not exist.
2. Compiles `tpch_usl` from `CREATE TABLE` definitions.
3. Activates all eight tables from the `TPCH` datasource.
4. Compares every USL row count with its source row count.

Once the model exists, run a non-mutating verification at any time:

```bash
java -cp "/tmp/zetaris-usl-build:$ZETARIS_JDBC_JAR" \
  CreateTpchUsl --verify-only
```

## Query the USL

Use the SQL Workspace or any JDBC client connected to the same endpoint:

```sql
SELECT *
FROM lightning.metastore.tpch.tpch_usl.orders
LIMIT 10;
```

The UI should show `tpch_usl` as **8 tables / 8 active** under **Unified
Semantic Layer → tpch**.

## The important SQL shape

USL creation is a compile-and-activate process:

```sql
CREATE NAMESPACE IF NOT EXISTS lightning.metastore.tpch;

COMPILE USL IF NOT EXISTS tpch_usl
DEPLOY NAMESPACE lightning.metastore.tpch DDL
CREATE TABLE region (
  r_regionkey int NOT NULL PRIMARY KEY,
  r_name varchar(25) NOT NULL,
  r_comment varchar(152)
);

ACTIVATE USL TABLE lightning.metastore.tpch.tpch_usl.region AS
SELECT * FROM TPCH.region;
```

The JDBC program sends the whole `COMPILE USL ... DDL` block as one statement.
Do not split a multi-table DDL block on its internal semicolons.

## Troubleshooting

- **`REQUIRES_SINGLE_PART_NAMESPACE` during activation:** use
  `TPCH.<table>`, not `TPCH.public.<table>`, inside `ACTIVATE USL TABLE` on
  this platform version.
- **`ClassNotFoundException` for `LightningDriver`:** confirm the driver JAR
  is present in both the `javac` and `java` classpaths.
- **Authentication failure:** check `ZETARIS_ADMIN_EMAIL` and
  `ZETARIS_ADMIN_PASSWORD`; never print or commit them.
- **Connection refused:** confirm the driver service is healthy and port
  `10000` is published locally.

The SLF4J “no-operation logger” warning from this standalone driver is benign;
it does not indicate a failed connection.
