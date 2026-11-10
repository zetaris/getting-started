---
source: kbase
url: https://kbase.zetaris.com/knowledge/create-a-dag-for-scheduling-your-first-python-script
title: "Create a DAG for scheduling your first python script"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: ccfa3670f330b130a749cb0db5723b05ac29e2aba82747b8c872c1ff933d4edf
---
# Create a DAG for scheduling your first python script

## On this page, you will find the steps to schedule Python scripts on Airflow for accessing data objects on Zetaris or conducting other operations. These exact steps can also be followed if you intend to schedule a shell script instead.

> ### **Prerequisites:**
> 
> 1.  _Before running the dags, make sure to have Microsoft Teams and Slack connections set up in Airflow for notifications. Refer to the [Version Control In Zetaris](https://kbase.zetaris.com/knowledge/version-control-in-zetaris-using-github-and-airflow?hs_preview=UhOYfMdK-96022112275) documentation for the setup steps._
> 2.  _By default, the installation of Airflow includes predefined variables related to Airflow configuration and the Zetaris Environment._
> 3.  __The table provided below contain either example values or parameter names, which should be replaced with appropriate and specific values.  
>     __
> 4.  __In this example, we are calling a data pipeline on Zetaris using a external python script and Zetaris API.__

1.  Create a Python script for the desired task (in our example, we have created a file named 'PY\_Script\_Sch.py' ).  
      
    ![Screenshot 2023-07-31 at 10.28.51](https://kbase.zetaris.com/hs-fs/hubfs/Screenshot%202023-07-31%20at%2010.28.51.png)
    
2.  Develop a DAG Python file, to schedule the python script created in the above step (in this example, we have created a file named 'Python\_Script\_Scheduler.py).   
      
    ![Screenshot 2023-07-31 at 10.42.25](https://kbase.zetaris.com/hs-fs/hubfs/Screenshot%202023-07-31%20at%2010.42.25.png)
    
3.  We need to create variables on the Airflow UI to provide parameters for the pipeline scheduling process process. Follow these steps:  
    
    1.  On the Airflow UI, navigate to the Admin section and select "Variables" from the dropdown list.
    2.  Upload the [Airflow Variables](https://kbase.zetaris.com/hubfs/Zetaris_Pipeline_Scheduler-1.json)  content as a JSON file by selecting "Choose File," and then import it by clicking "Import Variables" in Airflow.
    
    <table style="border-collapse: collapse; table-layout: fixed; margin-left: auto; margin-right: auto; border: 1px solid #99acc2; width: 85.6489%; height: 98px;"><tbody><tr style="height: 39px;"><td style="text-align: center; width: 39.7778%; height: 39px; border-style: solid; border-width: 1px;"><div aria-disabled="false"><div data-align="center"><p data-renderer-start-pos="4042"><strong data-renderer-mark="true">Variable Name</strong></p></div></div></td><td style="text-align: center; width: 60.2222%; height: 39px; border-style: solid; border-width: 1px;"><strong data-renderer-mark="true">Value</strong></td></tr><tr style="height: 29px;"><td style="text-align: center; width: 39.7778%; height: 29px; border-style: solid; border-width: 1px;">Email_Address</td><td style="text-align: center; width: 60.2222%; height: 29px; border-style: solid; border-width: 1px;">&lt;email_address_for_notifications&gt;</td></tr><tr style="height: 29px;"><td style="text-align: center; width: 39.7778%; height: 29px; border-style: solid; border-width: 1px;">Select_Pipeline_Query</td><td style="text-align: center; width: 60.2222%; height: 29px; border-style: solid; border-width: 1px;">&lt;select-query-pipeline&gt;</td></tr></tbody></table>
    
4.  Upload both files in the Airflow UI through Admin -> DAGS Code editor -> Create new file or upload (Both the files are uploaded in this example).
5.  After setting up the airflow and defining the necessary variables, you are all set to execute the '_**Python\_Script\_Scheduler**_' dag.    
      
    ![Screenshot 2023-07-31 at 10.28.39](https://kbase.zetaris.com/hs-fs/hubfs/Screenshot%202023-07-31%20at%2010.28.39.png)
