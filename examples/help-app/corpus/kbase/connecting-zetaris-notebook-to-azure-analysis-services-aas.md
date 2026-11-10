---
source: kbase
url: https://kbase.zetaris.com/knowledge/connecting-zetaris-notebook-to-azure-analysis-services-aas
title: "Connecting Zetaris Notebook to Azure Analysis Services (AAS)"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 945e7c5b93e368f9d03f6e1e00451355cbcc441f9460da8f1d0aa4c5b02c614b
---
# Connecting Zetaris Notebook to Azure Analysis Services (AAS)

## This article explains how to establish a secure connection between Zetaris Data Hub and Azure Analysis Services (AAS) to query both tabular tables and OLAP cubes directly using Python (pyadomd + MSAL + .NET Core runtime).

The article provides step-by-step guidance on installing dependencies, setting up authentication, and running both DAX and MDX queries from within a Zetaris environment.

### 1\. Prerequisites

| Component | Description |
| --- | --- |
| Azure Analysis Services | Accessible AAS instance with database and user/service principal permissions |
| Service Principal | Azure AD App Registration with Delegated or Application permission to AAS |
| Credentials | Tenant ID, Client ID, and Client Secret of the Service Principal |
| Python Environment | Python 3.10+ with pip access inside the Zetaris Notebook |
| .NET 8 Runtime | Installed on the same environment (ensure `$DOTNET_ROOT` is set) |

### 2\. Install Python Dependencies

```
%pip install pyadomd msal
```

### 3\. Load .NET Core and ADOMD Assemblies

The following section loads the required **.NET Core runtime** and **ADOMD assemblies** dynamically from NuGet.

```
import os, sys, json, tempfile, urllib.request, zipfilefrom pathlib import Pathimport pythonnetpythonCopy codeDOTNET_ROOT = os.environ.get("DOTNET_ROOT", os.path.expanduser("~/dotnet"))RUNTIME_VERSION = os.environ.get("DOTNET_RUNTIME_VERSION", "8.0.21")runtime_config = {    "runtimeOptions": {"tfm": "net8.0",        "framework": {"name": "Microsoft.NETCore.App", "version": RUNTIME_VERSION}}}tmp_config = Path(tempfile.gettempdir()) / "coreclr.runtimeconfig.json"tmp_config.write_text(json.dumps(runtime_config), encoding="utf-8")pythonnet.set_runtime("coreclr", runtime_config=str(tmp_config), dotnet_root=DOTNET_ROOT)
```

This ensures Python can interoperate with .NET (CoreCLR) for ADOMD operations.

### 4\. Download and Register ADOMD Assemblies

ADOMD libraries are downloaded directly from **NuGet** and extracted.

```
 nuget_url = "https://www.nuget.org/api/v2/package/Microsoft.AnalysisServices.AdomdClient.NetCore.retail.amd64/19.61.1.4"# Extract DLLs to temporary folder
```

The following assemblies are used:

-   `Microsoft.AnalysisServices.Runtime.Core.dll`
    
-   `Microsoft.AnalysisServices.Runtime.Windows.dll`
    
-   `Microsoft.AnalysisServices.AdomdClient.dll`
    

 5\. Load the Assemblies into Python

```
from pathlib import Pathimport clrassembly_dir = Path(os.environ["ADOMD_ASSEMBLY_DIR"])for dll in [    "Microsoft.AnalysisServices.Runtime.Core",    "Microsoft.AnalysisServices.Runtime.Windows",    "Microsoft.AnalysisServices.AdomdClient",]:    clr.AddReference(str(assembly_dir / f"{dll}.dll"))
```

###  6. Set Environment Variables for Connection

```
os.environ["AAS_TENANT_ID"] = "<Tenant ID>"os.environ["AAS_CLIENT_ID"] = "<Client ID>"os.environ["AAS_CLIENT_SECRET"] = "<Client Secret>"os.environ["AAS_SERVER"] = "asazure://<region>.asazure.windows.net/<server>"os.environ["AAS_DATABASE"] = "<Database Name>"
```

###  7. Authenticate with Azure AD (MSAL)

```
from msal import ConfidentialClientApplicationAPP = ConfidentialClientApplication(    client_id=os.environ["AAS_CLIENT_ID"],    authority=f"https://login.microsoftonline.com/{os.environ['AAS_TENANT_ID']}",    client_credential=os.environ["AAS_CLIENT_SECRET"],)TOKEN_SCOPE = ["https://*.asazure.windows.net/.default"]result = APP.acquire_token_for_client(scopes=TOKEN_SCOPE)print(result)
```

The token is used as a password in the ADOMD connection string.

### 8\. Authenticate with Azure AD (MSAL)

 Define Helper Functions

```
 def run_query(command_text: str, max_rows=None):    conn_str = f"Data Source={SERVER};Initial Catalog={DATABASE};User ID=;Password=<REDACTED>    conn = AdomdClient.AdomdConnection(conn_str)    conn.Open()    cmd = AdomdClient.AdomdCommand(command_text, conn)    reader = cmd.ExecuteReader()    # Parse results into Python list
```

 

Display Results

```
def display_rows(columns, rows, max_rows=20):    print(" | ".join(columns))    print("-" * 50)    for row in rows[:max_rows]:        print(" | ".join(str(v) if v is not None else "" for v in row))
```

### 9\. Run a DAX Query

Example fetching top 10 customers:

```
 dax_query = "EVALUATE TOPN(10, 'Customer')"cols, rows = run_query(dax_query)display_rows(cols, rows)
```

Discover Tables and Measures

```
# List all tablescols, rows = run_query("SELECT * FROM $SYSTEM.TMSCHEMA_TABLES")# List all measurescols, rows = run_query("SELECT * FROM $SYSTEM.TMSCHEMA_MEASURES")
```

Run MDX Query (Cube)

```
mdx_query = """WITH    MEMBER [Measures].[Internet Sales %] AS        IIF(            ([Measures].[Internet Total Sales], [Product].[Product].[(All)]) = 0,            NULL,            [Measures].[Internet Total Sales] /            ([Measures].[Internet Total Sales], [Product].[Product].[(All)])        ),        FORMAT_STRING = "Percent"SELECT    { [Measures].[Internet Total Sales],      [Measures].[Internet Total Units],      [Measures].[Internet Total Margin],      [Measures].[Internet Sales %] } ON COLUMNS,    TOPCOUNT(        [Internet Sales].[Customer Id].[Customer Id],        10,        [Measures].[Internet Total Sales]    ) ON ROWSFROM [Model]WHERE ( [Date].[Calendar Year].&[2013] )"""cols, rows = run_query(mdx_query)display_rows(cols, rows)
```
