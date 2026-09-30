import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Executes explicitly delimited JDBC statement plans without splitting on SQL
 * semicolons. This keeps multi-table Zetaris COMPILE USL DDL blocks intact.
 */
public final class JdbcStatementRunner {
    private static final Pattern DIRECTIVE = Pattern.compile(
            "^\\s*--\\s*@(statement|verify)\\s+([A-Za-z0-9._-]+)\\s*$");
    private static final int MAX_RESULT_ROWS = 20;
    private static final int MAX_CELL_LENGTH = 200;

    private JdbcStatementRunner() {}

    public static void main(String[] args) throws Exception {
        Arguments arguments = Arguments.parse(args);
        Properties properties = connectionProperties();
        loadDriverClassIfConfigured();

        try (Connection connection = DriverManager.getConnection(
                requiredEnv("JDBC_URL"), properties)) {
            if (arguments.probe()) {
                printMetadata(connection.getMetaData());
                return;
            }

            List<Block> blocks = parsePlan(arguments.plan());
            execute(connection, blocks, arguments.verifyOnly());
        }
    }

    private static Properties connectionProperties() throws IOException {
        Properties properties = new Properties();
        String propertiesPath = System.getenv("JDBC_PROPERTIES_FILE");
        if (propertiesPath != null && !propertiesPath.isBlank()) {
            try (InputStream input = Files.newInputStream(Path.of(propertiesPath))) {
                properties.load(input);
            }
        }

        setIfPresent(properties, "user", System.getenv("JDBC_USER"));
        setIfPresent(properties, "password", System.getenv("JDBC_PASSWORD"));
        return properties;
    }

    private static void loadDriverClassIfConfigured() throws ClassNotFoundException {
        String driverClass = System.getenv("JDBC_DRIVER_CLASS");
        if (driverClass != null && !driverClass.isBlank()) {
            Class.forName(driverClass);
        }
    }

    private static void printMetadata(DatabaseMetaData metadata) throws SQLException {
        System.out.println("Connection probe succeeded");
        System.out.println("Driver: " + metadata.getDriverName()
                + " " + metadata.getDriverVersion());
        System.out.println("Database: " + metadata.getDatabaseProductName()
                + " " + metadata.getDatabaseProductVersion());
        System.out.println("JDBC: " + metadata.getJDBCMajorVersion()
                + "." + metadata.getJDBCMinorVersion());
    }

    private static List<Block> parsePlan(Path plan) throws IOException {
        List<Block> blocks = new ArrayList<>();
        String name = null;
        boolean verify = false;
        StringBuilder sql = new StringBuilder();

        for (String line : Files.readAllLines(plan)) {
            Matcher matcher = DIRECTIVE.matcher(line);
            if (matcher.matches()) {
                addBlock(blocks, name, verify, sql);
                verify = "verify".equals(matcher.group(1));
                name = matcher.group(2);
                sql = new StringBuilder();
            } else if (name != null) {
                sql.append(line).append('\n');
            } else if (!line.isBlank() && !line.stripLeading().startsWith("--")) {
                throw new IllegalArgumentException(
                        "SQL appears before the first @statement or @verify directive");
            }
        }
        addBlock(blocks, name, verify, sql);

        if (blocks.isEmpty()) {
            throw new IllegalArgumentException("Plan contains no executable blocks: " + plan);
        }
        return blocks;
    }

    private static void addBlock(
            List<Block> blocks, String name, boolean verify, StringBuilder sql) {
        if (name == null) {
            return;
        }
        String statement = trimFinalSemicolon(sql.toString().trim());
        if (statement.isBlank()) {
            throw new IllegalArgumentException("Empty plan block: " + name);
        }
        blocks.add(new Block(name, verify, statement));
    }

    private static String trimFinalSemicolon(String sql) {
        return sql.endsWith(";") ? sql.substring(0, sql.length() - 1).stripTrailing() : sql;
    }

    private static void execute(
            Connection connection, List<Block> blocks, boolean verifyOnly) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            for (Block block : blocks) {
                if (verifyOnly && !block.verify()) {
                    continue;
                }

                System.out.println((block.verify() ? "VERIFY " : "RUN ") + block.name());
                try {
                    boolean hasResult = statement.execute(block.sql());
                    if (hasResult) {
                        try (ResultSet result = statement.getResultSet()) {
                            printResult(result);
                        }
                    } else {
                        System.out.println("  OK (update count " + statement.getUpdateCount() + ")");
                    }
                } catch (SQLException error) {
                    throw new SQLException(
                            "Plan block failed: " + block.name() + ": " + error.getMessage(),
                            error.getSQLState(), error.getErrorCode(), error);
                }
            }
        }
    }

    private static void printResult(ResultSet result) throws SQLException {
        ResultSetMetaData metadata = result.getMetaData();
        int columns = metadata.getColumnCount();
        List<String> headers = new ArrayList<>();
        for (int column = 1; column <= columns; column++) {
            headers.add(metadata.getColumnLabel(column));
        }
        System.out.println("  " + String.join(" | ", headers));

        int rows = 0;
        while (rows < MAX_RESULT_ROWS && result.next()) {
            List<String> cells = new ArrayList<>();
            for (int column = 1; column <= columns; column++) {
                String value = result.getString(column);
                cells.add(abbreviate(value == null ? "NULL" : value));
            }
            System.out.println("  " + String.join(" | ", cells));
            rows++;
        }
        if (rows == MAX_RESULT_ROWS && result.next()) {
            System.out.println("  ... additional rows omitted");
        }
        if (rows == 0) {
            System.out.println("  (no rows)");
        }
    }

    private static String abbreviate(String value) {
        String singleLine = value.replace('\n', ' ').replace('\r', ' ');
        return singleLine.length() <= MAX_CELL_LENGTH
                ? singleLine
                : singleLine.substring(0, MAX_CELL_LENGTH - 3) + "...";
    }

    private static void setIfPresent(Properties properties, String name, String value) {
        if (value != null && !value.isBlank()) {
            properties.setProperty(name, value);
        }
    }

    private static String requiredEnv(String name) {
        String value = System.getenv(name);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing environment variable: " + name);
        }
        return value;
    }

    private record Block(String name, boolean verify, String sql) {}

    private record Arguments(boolean probe, boolean verifyOnly, Path plan) {
        private static Arguments parse(String[] args) {
            if (args.length == 1 && "--probe".equals(args[0])) {
                return new Arguments(true, false, null);
            }
            if (args.length == 1) {
                return new Arguments(false, false, Path.of(args[0]));
            }
            if (args.length == 2 && "--verify-only".equals(args[0])) {
                return new Arguments(false, true, Path.of(args[1]));
            }
            throw new IllegalArgumentException(
                    "Usage: JdbcStatementRunner --probe | [--verify-only] <plan.sql>");
        }
    }
}
