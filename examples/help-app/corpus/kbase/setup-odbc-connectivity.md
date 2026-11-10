---
source: kbase
url: https://kbase.zetaris.com/knowledge/setup-odbc-connectivity
title: "Setup ODBC Driver"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 47793cdb9292ea98bb40ee7ba8b073ddcf80baf42c3e3af619a1c21188fa378d
---
# Setup ODBC Driver

## How to connect to Zetaris via ODBC.

  
To connect through ODBC, you will need to install the ODBC driver.

> ODBC is available for Windows clients only

### Resources

Download  resources:  

-   [ODBC Driver](https://kbase.zetaris.com/hubfs/odbc%20jdbc%20Drivers/zetaris-ndp-odbc-ver1.1.0-installer.exe)       
-   [ODBC Connection Demo](https://kbase.zetaris.com/hubfs/odbc%20jdbc%20Drivers/ODBC_PowerBI_ConnectionDemo.mp4)       
-   [PowerBI Sample MEZ File](https://kbase.zetaris.com/hubfs/odbc%20jdbc%20Drivers/ZetarisDataFabric.mez)

> If unable to access the above link due to network/firewall blocks, or other reasons, please contact your Zetaris representative.

###   
Installing the Zetaris ODBC Driver

To connect through ODBC, you will need to install the ODBC driver.

1.  Download the Zetaris ODBC .exe file (use resource link at the top of the page).
    
2.  Run the ODBC installer, check “Zetaris Networked Data Platform ODBC Driver” and install in the default directory.
    
3.  Open the ODBC Data Source Administrator (64 bit) by searching for “ODBC data source” in the search terminal.
    
4.  Add Zetaris Data Fabric in User DSN.
    

-   -   Select User DSN
        
    -   Select Add…
        
    -   Select Zetaris Networked Data Platform
        
    -   Select Finish
        

> If the Zetaris driver does not exist when creating new data source, or error messages occur when adding, then uninstall the ODBC driver and reinstall.

5\. Configure Zetaris ODBC Connection.

<table style="border-collapse: collapse; table-layout: fixed; border: 1px solid #000000; width: 66%; height: 287px; margin-left: auto; margin-right: auto;" class=" hs-table-align-center" data-number-column="false"><tbody><tr style="height: 39px;"><td style="width: 26.6905%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p style="text-align: center;" data-renderer-start-pos="1396"><strong data-renderer-mark="true">Field</strong></p></td><td style="width: 73.2922%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1405"><strong data-renderer-mark="true">Value</strong></p></td></tr><tr style="height: 65px;"><td style="width: 26.6905%; height: 65px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1416">DSN Name</p></td><td style="width: 73.2922%; height: 65px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1428">Name your ODBC connection, this can be anything</p></td></tr><tr style="height: 65px;"><td style="width: 26.6905%; height: 65px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1481">Server Host</p></td><td style="width: 73.2922%; height: 65px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1496">Zetaris server IP address</p></td></tr><tr style="height: 39px;"><td style="width: 26.6905%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1527">Port</p></td><td style="width: 73.2922%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1535">10000 (default)</p></td></tr><tr style="height: 39px;"><td style="width: 26.6905%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1556">Username</p></td><td style="width: 73.2922%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1568">Zetaris Username</p></td></tr><tr style="height: 39px;"><td style="width: 26.6905%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1590">Password</p></td><td style="width: 73.2922%; height: 39px; padding: 0px; border-style: solid; border-width: 1px; text-align: center;" rowspan="1" colspan="1" data-colwidth="340"><p data-renderer-start-pos="1602">Zetaris Password</p></td></tr></tbody></table>

6\. Select “**Connect**”, to confirm connection, then select “**OK**”.

The ODBC driver has now been installed.  
  

### Configuring the Power BI Direct Query connection

To connect through _**Zetaris MEZ**_ after configuring _**ODBC**_, follow these steps:

1.  Download the Zetaris _**.mez**_  file from the resource link provided above.
    
2.  Create two new nested directories in Documents.
    1.  Create a folder named "_**Microsoft Power BI Desktop**_" in Documents (C:\\Users\\\[user\]\\Documents\\Microsoft Power BI Desktop).
    2.  Within the "_**Microsoft Power BI Desktop**_" folder, create another folder named "_**Custom Connectors**_" (C:\\Users\\\[user\]\\Documents\\Microsoft Power BI Desktop\\Custom Connectors).
3.  Copy and paste the downloaded _**.mez**_  file into the "_**Custom Connectors**_" folder.
4.  Restart or launch the Power BI application to ensure that the changes take effect.
5.  Now, you need to change the _**data extension**_ settings in _**Power BI**_. Follow these steps:  
    1.  File > Options and Settings> Options.
    2.  Select “Security”.
    3.  Under “Data Extensions”,check the box that reads,“(Not Recommended) Allow any extension to load without validation or warning”.
    4.  Select“OK”.
6.  Close Power BI and relaunch the application to apply the updated security settings.
7.  After relaunching, go to "_**Get Data**_" and search for "_**Zetaris**_".
8.  Select the "_**Zetaris Data Fabric**_" connector from the options.
9.  To establish the connection, you will be prompted to enter the following information:
    
    1.  _**Zetaris Server IP Address**_ (provided by the Zetaris team).
    2.  _**Port: 10000**_ (the default port for Zetaris).
    3.  _**User credentials**_ (username and password) to authenticate and access the data on the Zetaris server.

By following these steps, you should be able to connect to Zetaris in Power BI  using "DirectQuery" and not "Import" and start utilising the data from the configured ODBC source.
