---
source: kbase
url: https://kbase.zetaris.com/knowledge/sql-manual
title: "Zetaris SQL Manual"
kind: sql-reference
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 1b6ac6bab581d9eae13e8471a3a0f7b186d03b739bd63bd27f52346d4339c216
---
# Zetaris SQL Manual

## 1\. SELECT

```
SELECT [hints, ...] [* |DISTINCT] named_expression[, named_expression, ...]
FROM relation[, relation, ...]
[lateral_view[, lateral_view, ...]]
[WHERE boolean_expression]
[aggregation [HAVING boolean_expression]]
[WINDOW named_window[, WINDOW named_window, ...]]
[LIMIT num_rows]

 named_expression:
   : expression [AS alias]

 relation:
   | join_relation
   | (table_name|query|relation) [sample] [AS alias]
   : VALUES (expressions)[, (expressions), ...]
       [AS (column_name[, column_name, ...])]

 expressions:
   : expression[, expression, ...]
```

Output data from one or more relations. A relation refers to any source of input data. It could be the contents of an existing table (or view), the joined result of two existing tables, or a subquery (the result of another SELECT statement).

### 1.1 \* (ALL)

> Select all matching rows from the relation. Enabled by default.

### 1.2 DISTINCT

> Select all matching rows from the relation then remove duplicate

### 1.3 WHERE

Filter rows by predicate.

Like Operator: used to match text values against a pattern using wildcards. If the search expression can be matched to the pattern expression, the LIKE operator will return true, which is 1.

There are two wildcards used in conjunction with the LIKE operator −

-   The percent sign (%)
-   The underscore (\_)

```
SELECT FROM table_name
WHERE column LIKE 'XXXX%'
```

```
SELECT FROM table_name
WHERE column LIKE '%XXXX%'
```

```
SELECT FROM table_name
WHERE column LIKE 'XXXX_'
```

### 1.4 GROUP BY (Aggregate Functions)

It is used in collaboration with the SELECT statement to group together those rows in a table that have identical data. This is done to eliminate redundancy in the output and/or compute aggregates that apply to these groups. The GROUP BY clause follows the WHERE clause in a SELECT statement and precedes the ORDER BY clause.

```
SELECT column-list
FROM table_name
WHERE [ conditions ]
GROUP BY column1, column2....columnN
ORDER BY column1, column2....columnN
```

#### Common Aggregate Functions

> COUNT() Returns the number of rows containing non-NULL values in the specified field. SUM() Returns the sum of the non-NULL values in the specified field. AVG() Returns the average of the non-NULL values in the specified field. MAX() Returns the maximum of the non-NULL values in the specified field. MIN() Returns the minimum of the non-NULL values in the specified field.

### 1.5 HAVING

Filter grouped result by predicate.

### 1.6 ORDER BY

Impose total ordering on a set of expressions. Default sort direction is ascending.

### 1.7 WINDOW

Assign an identifier to a window specification. Refer to section 6, for more information on Window Function.

### 1.8 LIMIT

Limit the number of rows returned.

### 1.9 VALUES

Explicitly specify values instead of reading them from a relation.

### 1.10 COMMON TABLE EXPRESSIONS (CTE)

A common table expression is a temporary result set which you can reference within another SQL statement including SELECT, INSERT, UPDATE OR DELETE Common Table Expressions are temporary in the sense that they only exist during the execution of the query. The following shows the syntax of creating a CTE:

```
WITH cte_name (column_list) AS (
    CTE_query_definition
)
[SELECT STATEMENT]:[INSERT SATEMENT]:[UPDATE SATEMENT]:[DELETE SATEMENT];
```

**For Example:**

```
with cte as
(SELECT
*
from
  ipl.individual)
SELECT
  count(*)
from
  cte
```

_In this syntax_

-   First, specify the name of the CTE following by an optional column list.
-   Second, inside the body of WITH clause, specify a query that returns a result set. If you do not explicitly specify the column list after the CTE name, the select list of the cte query definition will become the column list of the CTE.
-   Third, use the CTE like a table or view in the statement which can be a SELECT, INSERT, UPDATE OR DELETE

Common Table Expressions or CTEs are typically used to simplify complex joins and subqueries.

### 1.11 EXAMPLES:

```
SELECT * FROM ipl.iplmatch;

SELECT matchnumber,hometeam from ipl.iplmatch;

SELECT DISTINCT  matchnumber,hometeam from ipl.iplmatch;

SELECT count(*) from ipl.iplmatch;

SELECT * FROM ipl.iplmatch where Location='Bangalore' and IndexNo=419112;

SELECT * FROM ipl.iplmatch LIMIT 10;

SELECT batsman_name as batsman ,max(batsman_runs) as max_runs FROM bbl.bbl01cs
group by 1
order by max_runs desc ;

SELECT batsman_name as batsman ,max(batsman_runs) as max_runs FROM bbl.bbl01cs
where batsman_name like '%Ma%'
group by 1
having max_runs >=4
order by max_runs desc;
```

## 2\. SAMPLING

```
sample:
| TABLESAMPLE ((integer_expression | decimal_expression) PERCENT): TABLESAMPLE (integer_expression ROWS)
```

Sample the input data. This can be expressed in terms of either a percentage (must be between 0 and 1 00) or a fixed number of input rows

### 2.1 EXAMPLES:

```
SELECT
  *
FROM
  ipl.individual
  TABLESAMPLE (3 ROWS);

SELECT
  *
FROM
  ipl.individual
  TABLESAMPLE (25 PERCENT);
```

## 3\. JOIN

```
join_relation:
  | relation join_type JOIN relation (ON boolean_expression | USING (column_name[, column_name, ...]))
  : relation NATURAL join_type JOIN relation
join_type:
  | INNER
  | (LEFT|RIGHT) SEMI
  | (LEFT|RIGHT|FULL) [OUTER]
  : [LEFT] ANTI
```

### 3.1 INNER JOIN

Select all rows from both relations where there is match.

### 3.2 OUTER JOIN

Select all rows from both relations, filling with null values on the side that does not have a match.

### 3.3 RIGHT JOIN

Select ALL rows from the RIGHT side and corresponding matching values from left.

### 3.4 LEFT JOIN

Select ALL rows from the left side and corresponding matching values from right.

### 3.5 EXAMPLES :

```
SELECT
  a.game_id,
  a.venue,
  b.game_id,
  b.venue
from
  bbl.bbl01cs a
inner join
  bbl.bbl02cs b
on
  a.competition=b.competition:

SELECT
  a.game_id,
  a.venue,
  b.game_id,
  b.venue
from
  bbl.bbl01cs a
left join
  bbl.bbl02cs b
on a.venue=b.venue
```

#### Joining multiple data sources

```
SELECT
  a.game_id as wbbl_game_id
  , a.competition
  , b.game_id
  , b.competition
FROM
  wbbl.wbbl01c a
inner join
  bbl.bbl01cs b
on
  a.game_id=b.game_id
group by 1,2,3,4
limit 10
```

## 4\. LATERAL VIEW

```
lateral_view:
  : LATERAL VIEW [OUTER] function_name (expressions)
        table_name [AS (column_name[, column_name, ...])]
```

Generate zero or more output rows for each input row using a table-generating function. The most common built-in function used with LATERAL VIEW is explode.

### 4.1 LATERAL VIEW OUTER

Generate a row with null values even when the function returned zero rows.

### 4.2 EXAMPLES:

```
SELECT
  *
FROM
  bbl.bbl01cs
LATERAL VIEW explode(Array(1, 2, 3)) my_view
```

## 5\. AGGREGATION

```
aggregation:
    : GROUP BY expressions [(WITH ROLLUP | WITH CUBE | GROUPING SETS (expressions))]
```

Group by a set of expressions using one or more aggregate functions. Common built-in aggregate functions include count, avg, min, max, and sum.

### 5.1 ROLLUP

Create a grouping set at each hierarchical level of the specified expressions.

```
For instance,
  GROUP BY a, b, c WITH ROLLUP is equivalent to GROUP BY a, b, c GROUPING SETS ((a, b, c), (a, b), (a), ()).
```

The total number of grouping sets will be N + 1, where N is the number of group expressions.

### 5.2 CUBE

Create a grouping set for each possible combination of set of the specified expressions.

```
For instance,
  GROUP BY a, b, c WITH CUBE is equivalent to GROUP BY a, b, c GROUPING SETS ((a, b, c), (a, b), (b, c), (a, c), (a), (b), (c), ()).
```

The total number of grouping sets will be 2^N, where N is the number of group expressions.

### 5.3 GROUPING SETS

Perform a group by for each subset of the group expressions specified in the grouping sets.

```
For instance,
  GROUP BY x, y GROUPING SETS (x, y) is equivalent to the result of GROUP BY x unioned with that of GROUP BY y.
```

### 5.4 EXAMPLES:

```
SELECT
  venue,
  COUNT(*) AS num_matches
FROM
  wbbl.wbbl01c
GROUP BY venue

SELECT
  venue,
  AVG(batsman_runs) AS avg_runs
FROM
  wbbl.wbbl01c
GROUP BY venue

SELECT
  venue,
  fixture,
  batsman_name
FROM
  wbbl.wbbl01c
GROUP BY venue, fixture, batsman_name WITH ROLLUP

SELECT
  venue,
  fixture,
  AVG(batsman_runs)
FROM
  wbbl.wbbl01c
GROUP BY venue, fixture   GROUPING SETS (venue, fixture)
```

## 6\. WINDOW FUNCTION

```
window_expression:
 : expression OVER window_spec
named_window:
: window_identifier AS window_spec
window_spec:
| window_identifier
: ((PARTITION|DISTRIBUTE) BY expressions
 [(ORDER|SORT) BY sort_expressions] [window_frame])
window_frame:
| (RANGE|ROWS) frame_bound
: (RANGE|ROWS) BETWEEN frame_bound AND frame_bound
frame_bound:
| CURRENT ROW
 | UNBOUNDED (PRECEDING|FOLLOWING)
  : expression (PRECEDING|FOLLOWING)
```

Compute a result over a range of input rows. A windowed expression is specified using the OVER keyword, which is followed by either an identifier to the window (defined using the WINDOW keyword) or the specification of a window.

### 6.1 PARTITION BY

Specify which rows will be in the same partition, aliased by DISTRIBUTE BY.

### 6.2 ORDER BY

Specify how rows within a window partition are ordered, aliased by SORT BY.

### 6.3 RANGE BOUND

Express the size of the window in terms of a value range for the expression.

### 6.4 ROWS bound

Express the size of the window in terms of the number of rows before and/or after the current row.

### 6.5 CURRENT ROW

Use the current row as a bound.

### 6.6 UNBOUNDED

Use negative infinity as the lower bound or infinity as the upper bound.

### 6.7 PRECEDING

If used with a RANGE bound, this defines the lower bound of the value range. If used with a ROWS bound, this determines the number of rows before the current row to keep in the window.

### 6.8 FOLLOWING

If used with a RANGE bound, this defines the upper bound of the value range. If used with a ROWS bound, this determines the number of rows after the current row to keep in the window.

## 7\. HINTS

```
hints:
: /*+ hint[, hint, ...] */
hint:
: hintName [(expression[, expression, ...])]
```

Hints can be used to help execute a query better.

For example, you can hint that a table is small enough to be broadcast, which would speed up joins.

You add one or more hints to a SELECT statement inside /[\*](#id6)\+ … [\*](#id8)/ comment blocks.

Multiple hints can be specified inside the same comment block, in which case the hints are separated by commas, and there can be multiple such comment blocks. A hint has a name (for example, BROADCAST) and accepts 0 or more parameters.

### 7.1 EXAMPLES

```
SELECT /*+ BROADCAST(customers) */
  a.*,
  b.*
FROM
  TPCH_AZBLB.customer a,
  TPCH_AZBLB.orders b
WHERE a.c_custkey = b.o_custkey

SELECT /*+ SKEW('orders') */
  a.*,
  b.*
FROM
  TPCH_AZBLB.customer a,
  TPCH_AZBLB.orders b
WHERE a.c_custkey = b.o_custkey
```

## 8\. DATA SOURCE VIEW

View is virtual table based on the result-set of an SQL statement.

A view contains rows and columns, just like a real table.

The fields in a view are fields from one or more real tables in the database.

Using the Zetaris Data Fabric, tables/views from multiple data sources can be used to create a new view.

You can add SQL functions, WHERE, and JOIN statements to a view and present the data as if the data were coming from one single table.

```
CREATE VIEW [OR ALTER] schema_name.view_name [(column_list)]
AS
    select_statement;
```

_In this syntax:_

-   First, specify the name of the view after the CREATE VIEW keywords. The schema\_name is the name of the schema to which the view belongs.
-   Second, specify a SELECT statement (select\_statement) that defines the view after the AS keyword. The SELECT statement can refer to one or more tables.

If you don’t explicitly specify a list of columns for the view, SQL Server will use the column list derived from the SELECT statement.

In case you want to redefine the view e.g., adding more columns to it or removing some columns from it, you can use the OR ALTER keywords after the CREATE VIEW keywords.

```
CREATE DATASOURCE VIEW cust_ordr_count  AS
select
  b.c_name,
  count(distinct(a.o_orderkey))
FROM
  TPCH_AZBLB.orders a
INNER JOIN
  TPCH_AZBLB.customer   b
on
  a.o_custkey=b.c_custkey
group by 1
```

## 9\. CAST OPERATOR

There are many cases that you want to convert a value of one data type into another. PostgreSQL provides you with the CAST operator that allows you to do this.

The following illustrates the syntax of type CAST:

CAST ( expression AS target\_type );

In this syntax:

-   First, specify an expression that can be a constant, a table column, an expression that evaluates to a value.
-   Then, specify the target data type to which you want to convert the result of the expression.

### 9.1 EXAMPLES

```
SELECT
  CAST ('100' AS INTEGER);
```

If the expression cannot be converted to the target type, PostgreSQL will raise an error. See the following example:

```
SELECT
   CAST ('10C' AS INTEGER);

[Err] ERROR:  invalid input syntax for integer:

SELECT
   CAST ('2015-01-01' AS DATE),
   CAST ('01-OCT-2015' AS DATE);
```

## 10\. Other String Functions

### 10.1 CONCAT( string str1, string str2… )

The CONCAT function concatenates all the stings.

```
Example: CONCAT('hadoop','-','hive') returns 'hadoop-hive'

CONCAT_WS( string delimiter, string str1, string str2... )
```

The CONCAT\_WS function is similar to the CONCAT function. Here you can also provide the delimiter, which can be used in between the strings to concat.

```
Example: CONCAT_WS('-','hadoop','hive') returns 'hadoop-hive'
```

### 10.2 FIND\_IN\_SET( string search\_string, string source\_string\_list )

The FIND\_IN\_SET function searches for the search string in the source\_string\_list and returns the position of the first occurrence in the source string list. Here the source string list should be comma delimited one. It returns 0 if the first argument contains comma.

```
Example: FIND_IN_SET('ha','hao,mn,hc,ha,hef') returns 4
```

### 10.3 LENGTH( string str )

The LENGTH function returns the number of characters in a string.

```
Example: LENGTH('hive') returns 4
```

### 10.4 LOWER( string str ), LCASE( string str )

The LOWER or LCASE function converts the string into lower case letters.

```
Example: LOWER('HiVe') returns 'hive'
```

### 10.5 LPAD( string str, int len, string pad )

The LPAD function returns the string with a length of len characters left-padded with pad.

```
Example: LPAD('hive',6,'v') returns 'vvhive'
```

### 10.6 LTRIM( string str )

The LTRIM function removes all the trailing spaces from the string.

```
Example: LTRIM('   hive') returns 'hive'
```

### 10.7 REPEAT( string str, int n )

The REPEAT function repeats the specified string n times.

```
Example: REPEAT('hive',2) returns 'hivehive'
```

### 10.8 RPAD( string str, int len, string pad )

The RPAD function returns the string with a length of len characters right-padded with pad.

```
Example: RPAD('hive',6,'v') returns 'hivevv'
```

### 10.9 REVERSE( string str )

The REVERSE function gives the reversed string

```
Example: REVERSE('hive') returns 'evih'
```

### 10.10 RTRIM( string str )

The RTRIM function removes all the leading spaces from the string.

```
Example: LTRIM('hive   ') returns 'hive'
```

### 10.11 SPACE( int number\_of\_spaces )

The SPACE function returns the specified number of spaces.

```
Example: SPACE(4) returns '    '
```

### 10.12 SPLIT( string str, string pat )

The SPLIT function splits the string around the pattern pat and returns an array of strings. You can specify regular expressions as patterns.

```
Example: SPLIT('hive:hadoop',':') returns ["hive","hadoop"]
```

### 10.13 SUBSTR( string source\_str, int start\_position \[,int length\] )

The SUBSTR or SUBSTRING function returns a part of the source string from the start position with the specified length of characters. If the length is not given, then it returns from the start position to the end of the string.

```
Example1: SUBSTR('hadoop',4) returns 'oop'

Example2: SUBSTR('hadoop',4,2) returns 'oo'
```

### 10.14 TRIM( string str )

The TRIM function removes both the trailing and leading spaces from the string.

```
Example: TRIM('   hive   ') returns 'hive'
```

### 10.15 UPPER( string str ), UCASE( string str )

The UPPER or UCASE function converts the string into upper case letters.

### 10.16 Example:

```
UPPER('HiVe') returns 'HIVE' UPPER( string str ), UCASE( string str )
```

## 11\. Other Useful Functions - Quick Reference

### 11.1 Mathematical Functions

The following built-in mathematical functions are supported in Lightning; most return NULL when the argument(s) are NULL:

**Function Name**

#### abs(double a)

> Returns the absolute value
> 
> Returns double

#### acos(double a), acos(DECIMAL a)

> Returns the arc cosine of x if -1<=a<=1 or null otherwise
> 
> Returns double

#### asin(double a), asin(DECIMAL a)

> Returns the arc sin of x if -1<=a<=1 or null otherwise
> 
> Returns double

#### atan(double a), atan(DECIMAL a)

> Returns the arctangent of a
> 
> Returns double

#### bin(BIGINT a)

> Returns the number in binary format
> 
> Returns string

#### ceil(double a), ceiling(double a)

> Returns the minimum BIGINT value that is equal or greater than the double
> 
> Returns bigint

#### conv(BIGINT num, int from\_base, int to\_base), conv(STRING num, int from\_base, int to\_base)

> Converts a number from a given base to another
> 
> Returns string

#### cos(double a), cos(DECIMAL a)

> Returns the cosine of a (a is in radians)
> 
> Returns double

#### degrees(double a), degrees(DECIMAL a)

> Converts value of a from radians to degre
> 
> Returns double

#### exp(double a), exp(DECIMAL a)

> Returns ea where e is the base of the natural logarithm
> 
> Returns double

#### floor(double a)

> Returns the maximum BIGINT value that is equal or less than the double
> 
> Returns bigint

#### hex(BIGINT a) hex(string a) hex(BINARY a)

> If the argument is an int, hex returns the number as a string in hex format.
> 
> Otherwise if the number is a string, it converts each character into its hex representation and returns the resulting string.
> 
> Returns string

#### ln(double a), ln(DECIMAL a)

> Returns the natural logarithm of the argument
> 
> Returns double

#### log(double base, double a), log(DECIMAL base, DECIMAL a)

> Return the base “base” logarithm of the argument
> 
> Returns double

#### log10(double a), log10(DECIMAL a)

> Returns the base-10 logarithm of the argument
> 
> Returns double

#### log2(double a), log2(DECIMAL a)

> Returns the base-2 logarithm of the argument
> 
> Returns double

#### negative(int a), negative(double a)

> Returns -a int double

#### pmod(int a, int b) pmod(double a, double b)

> Returns the positive value of a mod b
> 
> Returns integer

#### positive(int a), positive(double a)

> Returns a int, double

#### pow(double a, double p), power(double a, double p)

> Return ap

#### radians(double a)

> Converts value of a from degrees to radians
> 
> Returns double

#### rand(), rand(int seed)

> Returns a random number (that changes from row to row) that is distributed uniformly from 0 to 1.
> 
> Specifiying the seed will make sure the generated random number sequence is deterministic.
> 
> Returns double

#### round(double a)

> Returns the rounded BIGINT value of the double
> 
> Returns bigint

#### round(double a, int d)

> Returns the double rounded to d decimal places
> 
> Returns double

#### sign(double a), sign(DECIMAL a)

> Returns the sign of a as ‘1.0’ or ‘-1.0’
> 
> Returns float

#### sin(double a), sin(DECIMAL a)

> Returns the sine of a (a is in radians)
> 
> Returns double

#### sqrt(double a), sqrt(DECIMAL a)

> Returns the square root of a
> 
> Returns double

#### tan(double a) tan(double a), tan(DECIMAL a)

> Returns the tangent of a (a is in radians)

#### unhex(string a)

> Inverse of hex.
> 
> Interprets each pair of characters as a hexidecimal number and converts to the character represented by the number. string
> 
> Returns string

### 11.2 The following are built-in String functions

**Function Name**

#### ascii(string str)

> Returns the numeric value of the first character of str
> 
> Returns int

#### base64(binary bin)

> Converts the argument from binary to a base- 64 string (as of 0.12.0)
> 
> Returns string

#### chr(bigint|double A)

> Returns the ASCII character having the binary equivalent to A (as of Hive 1.3.0 and 2.1.0). If A is larger than 256 the result is equivalent to chr(A % 256). Example: select chr(88); returns “X”.string
> 
> Returns string

#### concat(string|binary A, string|binary B…)

> Returns the string or bytes resulting from concatenating the strings or bytes passed in as parameters in order. e.g. concat(‘foo’, ‘bar’) results in ‘foobar’. Note that this function can take any number of input strings.

#### context\_ngrams(array<array>, array, int K, int pf)

> Returns the top-k contextual N-grams from a set of tokenized sentences, given a string of “context”. See StatisticsAndDataMining for more information.
> 
> Returns array<struct<string,double>>

#### concat\_ws(string SEP, string A, string B…)

> Like concat() above, but with custom separator SEP.
> 
> Returns string

#### concat\_ws(string SEP, array<string>)

> Like concat\_ws() above, but taking an array of strings. (as of Hive 0.9.0)
> 
> Returns string

#### decode(binary bin, string charset)

> Decodes the first argument into a String using the provided character set (one of ‘US-ASCII’, ‘ISO-8859-1’, ‘UTF-8’, ‘UTF-16BE’, ‘UTF-16LE’, ‘UTF-16’). If either argument is null, the result will also be null. (As of Hive 0.12.0.)
> 
> Returns string

#### elt(N int,str1 string,str2 string,str3 string,…)

> Return string at index number. For example elt(2,’hello’,’world’) returns ‘world’. Returns NULL if N is less than 1 or greater than the number of arguments. (See [https://dev.mysql.com/doc/refman/5.7/en/string-functions.html#function\_elt](https://dev.mysql.com/doc/refman/5.7/en/string-functions.html#function_elt))
> 
> Returns string

#### encode(string src, string charset)

> Encodes the first argument into a BINARY using the provided character set (one of ‘US-ASCII’, ‘ISO-8859-1’, ‘UTF-8’, ‘UTF-16BE’, ‘UTF-16LE’, ‘UTF-16’). If either argument is null, the result will also be null. (As of Hive 0.12.0.)
> 
> Returns binary

#### field(val T,val1 T,val2 T,val3 T,…)

> Returns the index of val in the val1,val2,val3,… list or 0 if not found. For example field(‘world’,’say’,’hello’,’world’) returns 3. All primitive types are supported, arguments are compared using str.equals(x). If val is NULL, the return value is 0. (See [https://dev.mysql.com/doc/refman/5.7/en/string-functions.html#function\_field](https://dev.mysql.com/doc/refman/5.7/en/string-functions.html#function_field))
> 
> Returns int

#### find\_in\_set(string str, string strList)

> Returns the first occurance of str in strList where strList is a comma-delimited string. Returns null if either argument is null. Returns 0 if the first argument contains any commas. e.g. find\_in\_set(‘ab’, ‘abc,b,ab,c,def’) returns 3
> 
> Returns int

#### format\_number(number x, int d)

> Formats the number X to a format like ‘#,###,###.##’, rounded to D decimal places, and returns the result as a string. If D is 0, the result has no decimal point or fractional part. (as of Hive 0.10.0)
> 
> Returns string

#### get\_json\_object(string json\_string, string path)

> Extract json object from a json string based on json path specified, and return json string of the extracted json object. It will return null if the input json string is invalid. NOTE: The json path can only have the characters \[0-9a-z\], i.e., no upper-case or special characters. Also, the keys _cannot start with numbers._ This is due to restrictions on Hive column names.
> 
> Returns string

#### in\_file(string str, string filename)

> Returns true if the string str appears as an entire line in filename.
> 
> Returns boolean

#### initcap(string A)

> Returns string, with the first letter of each word in uppercase, all other letters in lowercase. Words are delimited by whitespace. (As of Hive 1.1.0.)
> 
> Returns int

#### instr(string str, string substr)

> Returns the position of the first occurence of substr in str
> 
> Returns int

#### length(string A)

> Returns the length of the string
> 
> Returns int

#### levenshtein(string A, string B)

> Returns the Levenshtein distance between two strings (as of Hive 1.2.0). For example, levenshtein(‘kitten’, ‘sitting’) results in 3.
> 
> Returns int

#### locate(string substr, string str\[, int pos\])

> Returns the position of the first occurrence of substr in str after position pos
> 
> Returns int

#### lower(string A) lcase(string A)

> Returns the string resulting from converting all characters of B to lower case. For example, lower(‘fOoBaR’) results in ‘foobar’.
> 
> Returns string

#### lpad(string str, int len, string pad)

> Returns str, left-padded with pad to a length of len. If str is longer than len, the return value is shortened to len characters. In case of empty pad string, the return value is null.
> 
> Returns string

#### ltrim(string A)

> Returns the string resulting from trimming spaces from the beginning(left hand side) of A e.g. ltrim(‘ foobar ‘) results in ‘foobar ‘
> 
> Returns string

#### ngrams(array<array >, int N, int K, int pf)

> Returns the top-k N-grams from a set of tokenized sentences, such as those returned by the sentences() UDAF. See StatisticsAndDataMining for more information.
> 
> Returns array<struct<string,double>>

#### parse\_url(string urlString, string partToExtract \[, string keyToExtract\])

> Returns the specified part from the URL. Valid values for partToExtract include HOST, PATH, QUERY, REF, PROTOCOL, AUTHORITY, FILE, and USERINFO. e.g. parse\_url(‘[https://facebook.com/path1/p.php?k1=v1&k2=v2#Ref1](https://facebook.com/path1/p.php?k1=v1&k2=v2#Ref1)’, ‘HOST’) returns ‘facebook.com’. Also a value of a particular key in QUERY can be extracted by providing the key as the third argument, e.g. parse\_url(‘[https://facebook.com/path1/p.php?k1=v1&k2=v2#Ref1](https://facebook.com/path1/p.php?k1=v1&k2=v2#Ref1)’, ‘QUERY’, ‘k1’) returns ‘v1’.
> 
> Returns string

#### printf(String format, Obj… args)

> Returns the input formatted according do printf-style format strings (as of Hive 0.9.0)
> 
> Returns string

#### regexp\_extract(string subject, string pattern, int index)

> Returns the string extracted using the pattern. e.g. regexp\_extract(‘foothebar’, ‘foo(.\*?)(bar)’, 2) returns ‘bar.’’ Note that some care is necessary in using predefined character classes: using ‘s’ as the second argument will match the letter s; ‘s’ is necessary to match whitespace, etc. The ‘index’ parameter is the Java regex Matcher group() method index. See docs/api/java/util/regex/Matcher.html for more information on the ‘index’ or Java regex group() method.
> 
> Returns string

#### regexp\_replace(string INITIAL\_STRING, string PATTERN, string REPLACEMENT)

> Returns the string resulting from replacing all substrings in INITIAL\_STRING that match the java regular expression syntax defined in PATTERN with instances of REPLACEMENT, e.g. regexp\_replace(“foobar”, “oo|ar”, “”) returns ‘fb.’ Note that some care is necessary in using predefined character classes: using ‘s’ as the second argument will match the letter s; ‘s’ is necessary to match whitespace, etc.
> 
> Returns string

#### repeat(string str, int n)

> Repeat str n times
> 
> Returns string

#### replace(string A, string OLD, string NEW)

> Returns the string A with all non-overlapping occurrences of OLD replaced with NEW (as of Hive 1.3.0 and 2.1.0). Example: select replace(“ababab”, “abab”, “Z”); returns “Zab”.
> 
> Returns string

#### reverse(string A)

> Returns the reversed string
> 
> Returns string

#### rpad(string str, int len, string pad)

> Returns str, right-padded with pad to a length of len. If str is longer than len, the return value is shortened to len characters. In case of empty pad string, the return value is null.
> 
> Returns string

#### rtrim(string A)

> Returns the string resulting from trimming spaces from the end(right hand side) of A e.g. rtrim(‘ foobar ‘) results in ‘ foobar’

#### sentences(string str, string lang, string locale)

> Tokenizes a string of natural language text into words and sentences, where each sentence is broken at the appropriate sentence boundary and returned as an array of words. The ‘lang’ and ‘locale’ are optional arguments. e.g. sentences(‘Hello there! How are you?’) returns ( (“Hello”, “there”), (“How”, “are”, “you”) )
> 
> Returns array<array>

#### soundex(string A)

> Returns soundex code of the string (as of Hive 1.2.0). For example, soundex(‘Miller’) results in M460.
> 
> Returns string

#### space(int n)

> Return a string of n spaces
> 
> Returns string

#### split(string str, string pat)

> Split str around pat (pat is a regular expression)
> 
> Returns array

#### str\_to\_map(text\[, delimiter1, delimiter2\])

> Splits text into key-value pairs using two delimiters. Delimiter1 separates text into K-V pairs, and Delimiter2 splits each K-V pair. Default delimiters are ‘,’ for delimiter1 and ‘=’ for delimiter2.
> 
> Returns map<string,string>

#### substr(string|binary A, int start) substring(string|binary A, int start)

> Returns the substring or slice of the byte array of A starting from start position till the end of string A e.g. substr(‘foobar’, 4) results in ‘bar’
> 
> Returns string

#### substr(string|binary A, int start, int len) substring(string|binary A, int start, int len)

> Returns the substring or slice of the byte array of A starting from start position with length len e.g. substr(‘foobar’, 4, 1) results in ‘b’
> 
> Returns string

#### translate(string|char|varchar input, string|char|varchar from, string|char|varchar to)

> Translates the input string by replacing the characters present in the from string with the corresponding characters in the to string. This is similar to the translate function in PostgreSQL. If any of the parameters to this UDF are NULL, the result is NULL as well (available as of Hive 0.10.0; char/varchar support added as of Hive 0.14.0.)
> 
> Returns string

#### trim(string A)

> Returns the string resulting from trimming spaces from both ends of A e.g. trim(‘ foobar ‘) results in ‘foobar’
> 
> Returns string

## 12 Register Logical Datasources

To build a virtual data lake, a user need to identify data base to be connected. Lightning supports all JDBC compliant DB, all know NoSQL, RestAPI, CSV, JSON file.

### Register Clustered Databases

#### Register Master Datasources

A user need to provide JDBC driver class, url and connectivity credentials including extra parameters database need.

**Syntax:**

```
CREATE DATASOURCE ORCL [DESCRIBE BY ["Oracle for Product Master"] OPTIONS (
jdbcdriver "com.oracle.OracleDriver",
jdbcurl "jdbc:oracle:thin@oracle-master:1521:orcl",
username "scott",
password "tiger",
[key "value"]*)
```

`Real-world example` showing a connection to Oracle on port 1521 of a localhost with a database name of orcl with user name scott and password tiger.

```
CREATE DATASOURCE ORACLE DESCRIBE BY "Oracle for Product Master" OPTIONS (
jdbcdriver "com.oracle.OracleDriver",
jdbcurl "jdbc:oracle:thin@localhost:1521:orcl",
username "scott",
password "tiger")
```

#### Add Slave Nodes

If the registered database supports cluster base computing such as MPP, then a user can register slave nodes so that Lightning can directly query to slave nodes rather than running it through the master node.

```
ADD SLAVE DATASOURCE TO ORCL OPTIONS (
jdbcdriver "com.oracle.OracleDriver",
jdbcurl "jdbc:oracle:thin@oracle-slave1;1521:orcl",
username "scott",
password "tiger",
[key "value"])*
```

```
ADD SLAVE DATASOURCE TO ORCL OPTIONS (
jdbcdriver "com.oracle.OracleDriver",
jdbcurl "jdbc:oracle:thin@oracle-slave2;1521:orcl",
username "scott",
password "tiger",
[key "value"])*
```

```
ADD SLAVE DATASOURCE TO ORCL OPTIONS (
jdbcdriver "com.oracle.OracleDriver",
jdbcurl "jdbc:oracle:thin@oracle-slave3;1521:orcl",
username "scott",
password "tiger",
[key "value"])*
```

The above example shows registering 1 master node(oracle-master) and 3 slave nodes(oracle-slave1, oracle-slave2, and oracle-slave3).

\*ORCL is alias for the target data source which will be decided by a user when creating data source. \*If schema is provided, Lightning will only ingest metadata from that schema \*If schema\_prepended\_table is set to true, schema will be prepended to the table name as there may be same tables using the same name across different schemas. For example, role table in zetaris\_bi schema will be named zetaris\_bi\_\_role

### Register RDBMS Datasource

#### MS SQL Server

```
CREATE DATASOURCE MSSQL DESCRIBE BY "MSSQL-2017-linux " OPTIONS (
  jdbcdriver "com.microsoft.sqlserver.jdbc.SQLServerDriver",
  jdbcurl "jdbc:sqlserver://localhost:1433 ",
  databaseName "DemoData",
  username "scott" ,
  password "tiger",
  schema “dbo”
)
```

#### My SQL

```
CREATE DATASOURCE MY_SQL DESCRIBE BY "MySQL " OPTIONS (
  jdbcdriver "com.mysql.jdbc.Driver",
  jdbcurl "jdbc:mysql://127.0.0.1/test_db",
  username "scott" ,
  password "tiger
)
```

#### IBM DB2

```
CREATE DATASOURCE DB2_DB2INST1 DESCRIBE BY "DB2 Sample DB Schema " OPTIONS (
  jdbcdriver "com.ibm.db2.jcc.DB2Driver",
  jdbcurl "jdbc:db2://127.0.0.1:50000/db_name",
  username "db2inst1" ,
  password "db2inst1-pwd",
  schema "DB2INST1",
  schema_prepended_table "true"
)
```

#### Green Plum

```
CREATE DATASOURCE GREEN_PLUM  DESCRIBE  BY  "GREEN_PLUM " OPTIONS (
  jdbcdriver "org.postgresql.Driver",
  jdbcurl "jdbc:postgresql://localhost:5432/postgres",
  username "gpadmin" ,
  password "pivotal",
  schema "public"
)
```

#### Teradata

```
CREATE DATASOURCE TERA_DATA DESCRIBE BY "TERA_DATA " OPTIONS (
  jdbcdriver "com.teradata.jdbc.TeraDriver",
  jdbcurl "jdbc:teradata://10.128.87.16/DBS_PORT=1025",
  username "dbc" ,
  password "dbc",
  schema "dbcmngr"
)
```

#### Amazon Aurora

```
CREATE DATASOURCE AWS_AURORA DESCRIBE BY "AWS_AURORA " OPTIONS (
  jdbcdriver "com.mysql.jdbc.Driver",
  jdbcurl "jdbc:mysql://zet-aurora-cluster.cluster-ckh4ncwbhsty.ap-southeast-2.rds.amazonaws.com/your_db?",
  username "your_db_account_name" ,
  password "your_db_account_password""
)
```

#### Amazon Redshift

```
CREATE DATASOURCE REDSHIFT DESCRIBE BY "AWS RedShift" OPTIONS (
  jdbcdriver "com.amazon.redshift.jdbc.Driver",
  jdbcurl "jdbc:redshift://zetaris.cyzoanxzdpje.ap-southeast-2.redshift.amazonaws.com:5439/your_db_name",
  username "your_db_account_name",
  password "your_db_account_password"
)
```

### Register NOSQL Datasource

#### Register Mongo DB

For MongoDB, the below 5 parameters(host, port, db name, user name and password) must be provided.

```
CREATE DATASOURCE MONGO DESCRIBE BY "MongoDB" OPTIONS (
lightning.datasource.mongodb.host "localhost",
lightning.datasource.mongodb.port "27017",
lightning.datasource.mongodb.database "lightning-demo",
lightning.datasource.mongodb.username "",
lightning.datasource.mongodb.password ""
)
```

#### Register Cassandra

For Cassandra, there is only on parameter for Lightning, which is key space for this connection. the other parameters start with “spark.cassandra” prefix, which is actually provided for Spark Cassandra connector([https://github.com/datastax/spark-cassandra-connector](https://github.com/datastax/spark-cassandra-connector)).

```
CREATE DATASOURCE CSNDR DESCRIBE BY "Cassandra" OPTIONS (
spark.cassandra.connection.host "localhost",
spark.cassandra.connection. port "9042",
spark.cassandra.auth.username "cassandra",
spark.cassandra.auth. password "cassandra",
lightning. datasource .cassandra.keyspace "lightning_demo"
)
```

#### Register Amazon DynamoDB

```
CREATE DATASOURCE AWS_DYNAMODB DESCRIBE BY "AWS DynamoDB" OPTIONS (
  accessKeyId "Your_aws_accessKeyId",
  secretKey "Your_aws_SecretAccessKey" ,
  region "ap-southeast-2"
)
```

## 13 Create Physical Datasources

These are datasources based on physical files residing on on-prem filestore (Local filesystem,nfs filesystem), or cloud filestores like S3 and Azure Blob. One need to first create a lightning database and then register the respective files under this namespace . .. highlight:: sql

```
CREATE LIGHTNING DATABASE AWS_S3 DESCRIBE BY "AWS S3 bucket" OPTIONS (
[key "value"]
)
```

### Ingest file from local filesystem

```
CREATE LIGHTNING FILESTORE TABLE pref FROM HR FORMAT (CSV | JSON)
OPTIONS (path "file path", header "true", inferSchema "true", [key value pair]);
```

### Ingest RESTful Service

For the RESTful service when returns JSON format, a user need to provide end point, HTTP method, encoding type as well as schema.::

```
REGISTER REST DATASOURCE TABLE SAFC_USERS FROM SAFC SCHEMA (
uid Long,
gender String,
age Integer ,
job String,
ts String)
OPTIONS (
endpoint "/example/users",
method "GET",
requesttype "URLENCODED"
);
```

Other parameter for the API call, such as security key, can be provided in OPTIONS field.

### Ingest file from S3

```
CREATE LIGHTNING FILESTORE  TABLE customer FROM TPCH_S3 FORMAT CSV(JSON) OPTIONS (
  PATH "s3n://zetaris-lightning-test/csv-data/tpc-h/customer.csv",
  inferSchema "true",
  AWSACCESSKEYID "AKIAITGIWHBIPE******A",
  AWSSECRETACCESSKEY "EWfnuO/2E8UAA/5v89sxo6hTVefa5U*********"
)
```

### Ingest file from azure Blob

```
CREATE  LIGHTNING  FILESTORE  TABLE customer FROM TPCH_AZBLB FORMAT CSV(JSON) OPTIONS (
  PATH "wasb://<REDACTED>/customer.csv",
  inferSchema "true",
  fs.azure.account.key.zettesstorage.blob.core.windows.net "bHLzau36KlZ6cYnSrvPzSJVniBDtu819nHTR/+hRyDZEVScQ3wuesst9P5/I7v******"
)
```

Key name for security key depends on Azure Blob container, refer to Azure Blob service.

## 14 Ingest Metadata

Once a data source is registered in Lightning it will ingest all table, column and constraints metadata.

### Ingest all tables from the data source

```
REGISTER DATASOURCE TABLES FROM ORCL
```

This command will connect to ORCL database, and ingest all metadata(tables, columns, foreign key, index and all other constraints) into Schema Store

### Ingest a table from the data source

```
REGISTER DATASOURCE TABLE "USER" [USER_ALIAS] FROM ORCL
```

This will register “USER” table as USER\_ALIAS if alias is provided.

### Update Schema

When changes were made to the target data source, a user can reflect them using update schema command:

```
UPDATE DATASOURCE SCHEMA ORCL
```

### Update description and materialised table for each relation in a data source

## 15 Manage Schema Store

Lightning provides various commands to manage meta data in the schema store. Also, these will be provided via RESTful service.

### Datasource

#### Show Datasource

This command shows the data sources registered in the schema store:: .. highlight:: sql

```
SHOW DATASOURCES
```

#### Drop Datasource

This command drop the registered data source as well as all tables under that.:

```
DROP DATASOURCE ORCL
```

#### Describe Datasource

```
DESCRIBE DATASOURCE ORCL
```

#### Describe Slave Datasource

```
DESCRIBE SLAVE DATASOURCE ORCL
```

### Table

#### Describe data source table

```
DESC ORCL.USERS
```

#### Show all tables

```
SHOW TABLES
```

#### Show data source tables

```
SHOW DATASOURCE TABLES ORCL
```

#### Drop Table

```
DROP TABLE ORCL.USERS
```

### View

Lightning supports the view capability with query definition on a single data source or across multiple data sources

#### Create Data Source View

```
CREATE DATASOURCE VIEW TEEN_AGER FROM ORCL  AS
SELECT * FROM USERS WHERE AGE >= 13 AND AGE < 20
```

the TEEN\_AGER view belongs to ORCL data source. With this capability a user can create a view with DBMS native query, which is really handy :

```
CREATE DATASOURCE VIEW SALARY_RANK FROM ORCL AS
  SELECT department_id, last_name, salary, RANK() OVER (PARTITION BY department_id ORDER BY salary) RANK
  FROM employees
  WHERE department_id = 60
  ORDER BY RANK, last_name
SELECT * FROM ORCL.SALARY_RANK will produce :

DEPARTMENT_ID LAST_NAME                     SALARY       RANK
------------- ------------------------- ---------- ----------
           60 Lorentz                         4200          1
           60 Austin                          4800          2
           60 Pataballa                       4800          2
           60 Ernst                           6000          4
           60 Hunold                          9000          5
```

Also, those views can be join with other tables in other data sources.

#### Create Schema Store View

This view can across different data sources.

```
CREATE DATASOURCE VIEW TOP10_MOVIES_FOR_TEENS AS
  SELECT movies_from_oracle.title, user_rating.count, user_rating.min, user_rating.max, user_rating.avg
  FROM(
    SELECT iid, count(*) count, min(pref) min, max(pref) max, avg(pref) avg
    FROM TRDT.ratings ratings_from_teradata, PGRS.users users_from_postgres
    WHERE users_from_postgres.age >=13AND users_from_postgres.age <20
    AND ratings_from_teradata.uid = users_from_postgres.uid
    GROUP BY ratings_from_teradata.iid
    ORDER BY avg DESC
    LIMIT20
) AS user_rating, ORCL.movies movies_from_oracle
WHERE movies_from_oracle.iid = user_rating.iid
```

This view can be queried like normal table :

```
SELECT*FROM TOP10_MOVIES_FOR_TEENS
```

#### Drop View

```
DROP VIEW ORCL.TEEN_AGER;
```

## 16 Run Query

Lightning supports SQL2003. Also, it can run all 99 TPC-DS queries. As long as a data source registered into schema store, query can across all data sources.

For example the following query run join query across three different data sources(Teradata ↔ Oracle ↔ Cassandra),

```
SELECT  users_from_cassandra.age, users_from_cassandra.gender, movies_from_oracle.title title, ratings_from_teradata.pref, ratings_from_teradata.ts
FROM TRDT.ratings ratings_from_teradata, ORCL.movies movies_from_oracle, CSNDR.users users_from_cassandra
WHERE users_from_postgres.gender = 'F'
AND ratings_from_teradata.uid = users_from_postgres.uid
AND movies_from_oracle.iid = ratings_from_teradata.iid
```

## 17 Materialization and Cache

For some reasons, for example query performance, all data source tables or views can be materialized by leveraging Zetaris Fusion DB. Also, Lightning support Cache capabilities where a user can load all data into main memory.

### Materialization

For example the following query materialize all data from RESTful Service to USER\_FOR\_COPY table in fusion db.:

```
INSERT INTO FUSIONDB.USERS_FOR_COPY
SELECT uid, gender, age, job , ts FROM SAFC.SAFC_USERS
```

### Cache/Uncache

A user can load all data into main memory by leverging cache capability and also, uncache it anytime.

```
CACHE TABLE pref;
CACHE TABLE ORCL.movies;
```

The pref, ORCL.moves table are chaned now, and the following query performs a lot better :

```
SELECT movies_from_oracle.title, hdfs_pref. count , hdfs_pref. min , hdfs_pref. max , hdfs_pref. avg
FROM (
SELECT iid, count ( * ) count , min (pref) min , max (pref) max , avg (pref) avg
FROM pref
GROUP BY iid
) AS hdfs_pref, ORCL.movies movies_from_oracle
WHERE movies_from_oracle.iid = hdfs_pref.iid
These tables uncached any time
UNCACHE TABLE pref
UNCACHE TABLE ORCL.movies
```

## 18 Statistics

Lighting come up with CBO(Cose Based Optimizer) to reduce data shuffling across cluster. To do this, Lighting keeps statistics for the data source. There are two types of statistics, the one is table level statistics and the other is column level statistics.

### Table level statistics

```
ANALYZE DATASOURCE TABLE ORCL.MOVIES
This command generate statistics such as size in bytes, cardinality for the table, and these are browsed by the following command :
SHOW DATASOURCE TABLE STATISTICS ORCL.MOVIES
```

### Column level statistics

```
ANALYZE DATASOURCE TABLE ORCL.MOVIES COMPUTE STATISTICS FOR COLUMNS (IID, TITLE)
```

This command generate statistics such as cardinality, number of null, min, max, average value, and these are browsed by the following command :

```
SHOW DATASOURCE COLUMN STATISTICS ORCL.MOVIES;
```

## 19 Partitioning

Query performance can be improved by partitioning table. What partitioning means here is that all records are splitted into multiple partitions and these are processed independently in each worker node.

```
CREATE DATASOURCE PARTITION ON ORCL.USERS OPTIONS (
COLUMN "UID",
COUNT "2",
LOWERBOUND "1",
UPPERBOUND "6040")
This command makes two partitions based on the "UID" column. lower/upper bound provides boundary value for the partition. This partition can be removed by :
DROP DATASOURCE PARTITION ON ORCL.USERS
```

## 20 Import CSV file

Lighting supports CSV file and running query on top of it. A CSV can be imported by either :

### Hive syntax

```
CREATE EXTERNAL TABLE pref (uid INT, iid INT, pref FLOAT, ts STRING)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION 'csv directory'
```

With the syntax, a user can import other file format than csv(tsv for example). But this doesn’t support :

1.  Header CSV header must be got rid of.
2.  LOCATION must be directory. Create a directory, and place csv file there
3.  For directory in s3 bucket, csv directory looks like “s3n://mys3bucket/perf/”

> OR

### Lightning Syntax

```
CREATE TABLE pref
USING com.databricks.spark.csv
OPTIONS (path "file path", header "true", inferSchema "true")
```

With this syntax, user can do :

1.  infer schema
2.  support header
3.  support a single file
4.  `file path` in Amazon s3 looks like `s3n://mys3bucket/perf/pref.csv`

## 21 Access Control

### User Management

Only admin user or users in “admin” role can add/drop user.

#### Add user

1.  level : admin | general
2.  password doesnt allow white spaces

```
ADD USER WITH (
email '<REDACTED>',
name 'someone',
level 'general',
password '1234567'
)
```

#### Update user password

```
UPDATE USER user_id SET PASSWORD 'new_password'
```

#### Describe user

```
DESCRIBE USER user_id
```

#### Delete user

```
DROP USER user_id
```

#### Show users

```
SHOW USERS
```

### Role Based Access(RBA) control

The Lightning provides Role Based Access which limits a users to access a specific set of data. This is applied at data source level or table level in each data source. Only admin users or equivalents can run these commands

**Privileges**

-   SELECT privilege - Give read access to the data source or relation
-   INSERT privilege - Give insert access to the data source or relation
-   CACHE privileges - Give cache access to a relation : (UN)CACHE DATASOURCE TABLE

**Predefined Roles**

Role is case insensitive - admin - none - all - default

#### Create Role

```
CREATE ROLE role_name [DESCRIBE BY "this is blah~~~"]
```

#### Drop Role

```
DROP ROLE role_name;
```

#### Show Roles

```
SHOW ROLES
```

#### Assign an User a Role

```
ASSIGN USER user_name [, user_name] ...TO ROLE role_name
```

#### Revoke User from Role

```
REVOKE USER user_name[, user_name] ...FROM ROLE role_name
```

#### Show Role Assigned to user

Show all roles granted to the user

```
SHOW ROLE ASSIGNED TO USER user_name
```

#### Show Role Assigned to user

Show all users granted to the role

```
SHOW USER ASSIGNED TO ROLE role_name
```

#### Grant

Granted user with GRANT OPTIONS can grant same privilege on the table.

```
GRANT SELECT | INSERT | CACHEON table_or_view_nameTO principal_spec [,principal_spec] ...[WITH GRANT OPTION]
```

#### Revoke

```
REVOKE SELECT(INSERT | CACHE) ON table_or_view_name FROM principal_spec [,principal_spec] ...
```

#### Show Grant

-   Wild card can be only used in table field. for example, ORCL.\* is allowed but \*.\* or \*.movies were not allowed.

```
SHOW GRANT[principal_specification] ON(ALL | [TABLE] table_or_view_name)
principal_specification: USER user | ROLE roleIt will display :
table_identifier        | principal_name  | principal_type  | privilege  | grant_option  |   grant_time                      | grantor
+------------------------+----------------------+--------------------+-------------+------------------+----------------------------------+----------+
ORCL.movies         | ashutosh            | USER              | DELETE  | false              | 2018-05-07 11:44:12.301 | thejas
ORCL.movies         | ashutosh            | USER              | INSERT   | false              | 2018-05-07 11:44:12.301 | thejas
ORCL.ratings          | ashutosh            | ROLE              | SELECT  | false              | 2018-05-07 11:44:12.301 | thejas
```
