import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Properties;

/** Creates and verifies a TPC-H Unified Semantic Layer through Zetaris JDBC. */
public final class CreateTpchUsl {
    private static final String JDBC_URL =
            System.getenv().getOrDefault(
                    "ZETARIS_JDBC_URL",
                    "jdbc:zetaris:lightning@127.0.0.1:10000");
    private static final String NAMESPACE = "lightning.metastore.tpch";
    private static final String USL_NAME = "tpch_usl";
    private static final String USL_PATH = NAMESPACE + "." + USL_NAME;

    private static final String DDL = """
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
            """;

    private static final Map<String, String> TABLES = new LinkedHashMap<>();
    static {
        TABLES.put("region", "TPCH.region");
        TABLES.put("nation", "TPCH.nation");
        TABLES.put("supplier", "TPCH.supplier");
        TABLES.put("part", "TPCH.part");
        TABLES.put("customer", "TPCH.customer");
        TABLES.put("orders", "TPCH.orders");
        TABLES.put("partsupp", "TPCH.partsupp");
        TABLES.put("lineitem", "TPCH.lineitem");
    }

    private CreateTpchUsl() {}

    public static void main(String[] args) throws Exception {
        boolean verifyOnly = args.length == 1 && "--verify-only".equals(args[0]);
        if (args.length > 0 && !verifyOnly) {
            throw new IllegalArgumentException("Usage: CreateTpchUsl [--verify-only]");
        }

        Properties properties = new Properties();
        properties.setProperty("user", requiredEnv("ZETARIS_ADMIN_EMAIL"));
        properties.setProperty("password", requiredEnv("ZETARIS_ADMIN_PASSWORD"));
        properties.setProperty("loginTimeout", "30");

        Class.forName("com.zetaris.lightning.jdbc.LightningDriver");
        try (Connection connection = DriverManager.getConnection(JDBC_URL, properties);
             Statement statement = connection.createStatement()) {
            if (!verifyOnly) {
                createAndActivate(statement);
            }
            verify(statement);
        }
    }

    private static void createAndActivate(Statement statement) throws SQLException {
        run(statement, "CREATE NAMESPACE IF NOT EXISTS " + NAMESPACE);
        run(statement, "COMPILE USL IF NOT EXISTS " + USL_NAME
                + " DEPLOY NAMESPACE " + NAMESPACE + " DDL " + DDL);

        for (Map.Entry<String, String> table : TABLES.entrySet()) {
            run(statement, "ACTIVATE USL TABLE " + USL_PATH + "." + table.getKey()
                    + " AS SELECT * FROM " + table.getValue());
        }
    }

    private static void verify(Statement statement) throws SQLException {
        System.out.println("Verified row counts:");
        for (Map.Entry<String, String> table : TABLES.entrySet()) {
            long sourceCount = scalar(statement, "SELECT COUNT(*) FROM " + table.getValue());
            long uslCount = scalar(statement, "SELECT COUNT(*) FROM "
                    + USL_PATH + "." + table.getKey());
            if (sourceCount != uslCount) {
                throw new SQLException("Row-count mismatch for " + table.getKey()
                        + ": source=" + sourceCount + ", usl=" + uslCount);
            }
            System.out.printf("  %-10s %,d%n", table.getKey(), uslCount);
        }
        System.out.println("USL ready: " + USL_PATH);
    }

    private static void run(Statement statement, String sql) throws SQLException {
        System.out.println("Running: " + firstLine(sql));
        statement.execute(sql);
    }

    private static long scalar(Statement statement, String sql) throws SQLException {
        try (ResultSet result = statement.executeQuery(sql)) {
            if (!result.next()) {
                throw new SQLException("No result returned by: " + sql);
            }
            return result.getLong(1);
        }
    }

    private static String requiredEnv(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing environment variable: " + name);
        }
        return value;
    }

    private static String firstLine(String sql) {
        int newline = sql.indexOf('\n');
        return newline < 0 ? sql : sql.substring(0, newline) + " ...";
    }
}
