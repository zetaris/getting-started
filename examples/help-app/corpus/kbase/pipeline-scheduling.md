---
source: kbase
url: https://kbase.zetaris.com/knowledge/pipeline-scheduling
title: "Pipeline Scheduling"
kind: other
lastmod: 2026-04-02
retrieved: 2026-11-10
sha256: 056af3fbec6af29ed948de3b6be559393f156771f61e77e90c2dbc8345396295
---
# Pipeline Scheduling

## This article will walk through the process of scheduling a Zetaris Pipeline to execute on a schedule

Zetaris pipelines are used to transform structured and unstructured data into a desired state for either real-time use-cases or for moving data into a data warehouse or data lakehouse.

When moving data, rather than having to manually run them, we can use the Zetaris Scheduler, which leverages Apache Airflow, to automate and schedule these pipeline flows.

### **How to setup a schedule**

In creating the schedule, there are key steps for the creation

[1\. Collect Zetaris Details](#collect_details)

[2\. Access the Zetaris Scheduler](#access_scheduler)

[3\. Build the DAG pipeline script](#build_DAG)

The DAG pipeline script is where we build the logic for how to orchestrate the pipeline. It is where we include things like schedule cycle, pipeline/s to call, and the authentication mechanism

[4\. Inspect the DAG](#inspect_dag)

#### **1\. Collect Zetaris Details**

We need to collect some information from the Zetaris hub to include in the orchestration, these include Org\_ID, the pipeline name, and the bearer token, check below for examples of where to find each

-   Org\_ID
    
    example: **7** 
    
    ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-02-2026-02-30-07-9180-AM.png) 
    
-   Pipeline name (with container)
    
    example: **customer\_insights.customer\_master**
    

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-02-2026-02-32-35-2552-AM.png)

-   Bearer Token
    
    example: **akjzqcuhk7se452dsety1sfq7c2u35ivguiiq0cojrogcc7jobtthbdde93i**
    

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-02-2026-02-39-33-5017-AM.png)

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-02-2026-02-46-25-7987-AM.png)

#### **2\. Access the Zetaris Scheduler**

#### Select the Apache Airflow integration from the top panel

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-02-2026-03-52-26-7867-AM.png)

#### **3\. Build the DAG pipeline script**

**Step 1:** Create a new DAG by going to **Admin > DAGs Code Editor** then select **+New**

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Apr-02-2026-02-58-26-8304-AM.png)

**Step 2:** Create a new DAG script

Below are example scripts that is used to create a DAG schedule, which you can  copy and paste into your DAG editor. There are two examples,

-   One for a [single pipeline schedule](#single_pipeline_script)
-   One for a [multi pipeline schedule](#multipipeline_script)

Once that is done you need to update the following fields

`"X-Org-ID": "**<Your Org ID>**"`

`"Authorization": "Bearer **<your Bearer Token>**"`

`"sql" : "SELECT * FROM **<pipeline_container.pipeline_name>**"`

The "sql" field for updating is towards the end of the script.

For multipipeline DAG schedules you will need to update the the "sql" field in both run\_query\_task\_\* locations

`"schedule_interval" : "**<your preferred interval>**"`

The "schedule\_interval" field uses **CRON** notation. e.g. "0 2 \* \* \*" schedules a task to run at 2am UTC every day

##### **Optional Updates:**

`dag_id="**<name of the DAG>**"`

`task_id="**<name of the schedule task>**"`

**Step 3:** Save script

**EXAMPLE SCRIPT - SINGLE PIPELINE EXECUTION _(FOR COPY)_**

```
from airflow import DAGfrom airflow.operators.python import PythonOperatorfrom datetime import datetimeimport requestsimport jsonimport loggingimport pandas as pd# ---------------- CONFIG ----------------URL = "https://api.enterprise.zetaris.com/api/v1.0/sql-editor/sqls/run-query"HEADERS = {    "X-Request-ID": "f9fb18eb-e225-4af4-a7fa-355375628a38",    "X-Org-ID": "7",    "Content-Type": "application/json",    "Authorization": "Bearer <TOKEN>",}# ---------------- TASK FUNCTION ----------------def run_zetaris_query(sql):    logging.info("🚀 Running Zetaris SQL Query...")    payload = json.dumps({        "sql": sql    })    try:        response = requests.post(URL, headers=HEADERS, data=payload)        logging.info(f"Status Code: {response.status_code}")        logging.info(f"Response: {response.text}")                return response.json()        # ❗ Fail task if API fails        if response.status_code != 200:            raise Exception(f"API failed with status {response.status_code}")        # Optional: check logical failure        if "error" in response.text.lower():            raise Exception(f"API returned error: {response.text}")    except Exception as e:        logging.error(f"❌ Error running Zetaris query: {e}")        raise### Query the zetaris API heredef get_sql(sql):    sql = run_zetaris_query(sql)        df = pd.DataFrame(sql["data"], columns=sql["headers"])    print(df.head())        return sql  with DAG(    dag_id="test",    start_date=datetime(2025,11,25),    schedule_interval="0 2 * * *",  # scheduled at 2am UTC every day    catchup=False,    tags=["demo"]) as dag:    run_query_task_1 = PythonOperator(        task_id="run_zetaris_sql_1",        python_callable=get_sql,        op_kwargs={            "sql": "SELECT * FROM customer_insights.customer_master"}    )        run_query_task_1
```

**EXAMPLE SCRIPT - MULTIPLE PIPELINE EXECUTION _(FOR COPY)_**

```
from airflow import DAGfrom airflow.operators.python import PythonOperatorfrom datetime import datetimeimport requestsimport jsonimport loggingimport pandas as pd# ---------------- CONFIG ----------------URL = "https://api.enterprise.zetaris.com/api/v1.0/sql-editor/sqls/run-query"HEADERS = {    "X-Request-ID": "f9fb18eb-e225-4af4-a7fa-355375628a38",    "X-Org-ID": "7",    "Content-Type": "application/json",    "Authorization": "Bearer <TOKEN>",}# ---------------- TASK FUNCTION ----------------def run_zetaris_query(sql):    logging.info("🚀 Running Zetaris SQL Query...")    payload = json.dumps({        "sql": sql    })    try:        response = requests.post(URL, headers=HEADERS, data=payload)        logging.info(f"Status Code: {response.status_code}")        logging.info(f"Response: {response.text}")                return response.json()        # ❗ Fail task if API fails        if response.status_code != 200:            raise Exception(f"API failed with status {response.status_code}")        # Optional: check logical failure        if "error" in response.text.lower():            raise Exception(f"API returned error: {response.text}")    except Exception as e:        logging.error(f"❌ Error running Zetaris query: {e}")        raise### Query the zetaris API heredef get_sql(sql):    sql = run_zetaris_query(sql)        df = pd.DataFrame(sql["data"], columns=sql["headers"])    print(df.head())        return sql  with DAG(    dag_id="test",    start_date=datetime(2025,11,25),    schedule_interval="0 2 * * *",  # scheduled at 2am UTC every day    catchup=False,    tags=["demo"]) as dag:    run_query_task_1 = PythonOperator(        task_id="run_zetaris_sql_1",        python_callable=get_sql,        op_kwargs={            "sql": "SELECT * FROM ny_taxi_csv.taxi_zones_csv"}    )    run_query_task_2 = PythonOperator(        task_id="run_zetaris_sql_2",        python_callable=get_sql,        op_kwargs={            "sql": "SELECT * FROM ny_taxi_csv.for_hire_vehicles_csv"}    )        run_query_task_1 >> run_query_task_2
```

#### **Inspect the DAG**

Navigate back to the main screen by select **DAGs** from the top, then your DAG should appear in the list below

**NOTE:** It may not appear straight away, in which case you may need to refresh a few times

Select your DAG to inspect logs, history, and for manual triggering
