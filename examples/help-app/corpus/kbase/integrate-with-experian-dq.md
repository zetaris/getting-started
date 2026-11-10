---
source: kbase
url: https://kbase.zetaris.com/knowledge/integrate-with-experian-dq
title: "Integrate with Experian DQ"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 82011b88523178996e14997f33ecf42c190f8bbd435b4e0defd617ade34846c8
---
# Integrate with Experian DQ

### Integration via REST API (Recommended for Aperture)

#### Step 1: Get Experian API Access

Experian's **Aperture Data Studio** offers REST APIs for:

-   Data Profiling
    
-   DQ Rule Execution
    
-   Metadata Access
    
-   Data Quality Scorecards
    

Request API access via your Experian account manager. Ensure you get:

-   Base URL (e.g., `https://api.experian.com/dq/`)
    
-   OAuth2 credentials or API keys
    
-   Swagger/OpenAPI specs (optional)
    

#### Step 2: Configure Zetaris REST API Source

1.  Go to **Connections > Data Sources**
    
2.  Select **REST API**
    
3.  Fill in:
    
    -   **Base URL**
        
    -   **Authentication Type** (e.g., Bearer Token or OAuth2)
        
    -   **Headers** if needed
        
    -   Optional: Import Swagger for schema detection
        

#### Step 3: Define API Calls

You can define endpoints such as:

| Purpose | Endpoint |
| --- | --- |
| Run Profiling Job | `/profiling/start` |
| Get Profiling Results | `/profiling/result/{jobId}` |
| List DQ Rules | `/dq/rules` |
| Run DQ Rules | `/dq/run` |
| Get DQ Scores | `/dq/scorecard` |

Use **Zetaris REST Data Source Wizard** to define:

-   GET or POST calls
    
-   Parameter templates
    
-   Authentication handling
    

#### Step 4: Use API Output as Virtual Tables

Once connected:

-   Zetaris will treat API responses as **virtual tables**
    
-   You can run **SQL over JSON outputs** (e.g., flattening response)
    
-   Join with other internal or cloud datasets
    

### References

-   [Experian Aperture API Docs](https://www.experian.com/)
