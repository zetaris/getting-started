---
source: kbase
url: https://kbase.zetaris.com/knowledge/genz-tools
title: "Tools Framework in GenZ"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 5933c8caca61d7c7e69f0165f9f94756bd72286ac007d31967811307f9945703
---
# Tools Framework in GenZ

## This guide shows administrators (or users with setup permissions) how to configure, add, and enable tools so they are available for chat sessions in GenZ

GenZ  invokes the Model Context Protocol (MCP) to act as a universal bridge between the model and tools, both internal and external. Through MCP, the agent discovers available tools, authenticates securely, and orchestrates multi-step workflows without hardcoded integrations.

Internal MCP tools include the modern lakehouse, data pipelines, catalog, security, and other enterprise systems (CRM/loans, storage refresh, PII classification, data migration). External MCP servers span services like Slack, email, maps, GitHub, and many more.

**Setting-up tools in GenZ**  
1\. Open the Configuration Section  
After logging in, locate the Configuration button in the main navigation bar at the top of your GenZ dashboard  
2\. Locate the Agent Framework Submenu and you will find Tools Details option.  
3\. Click the plus button at the top to add a new tool and fill out the required details as shown below

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-11-2025-12-01-39-2026-PM.png)

  
4\. It is not mandatory to provide a .py and dependencies file as this will be handled by the engineering team once the tool is submitted.  
5\. Click Submit to create a new tool and your tool is successfully registered.  
6\. Clicking the edit, will show a dropdown containing all available tools registered to your account.

  
**Assign tools to an agent**

1\. You can assign tools to an agent that will allow the user to access the selected tools when the agent is put in action. This can be done in Trainer Toolkit.  
2\. Just drag and drop the agents required tools onto the canvas and connect them to make these tools available to the agent.![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-11-2025-12-00-57-9436-PM.png)

**Using the tools in chat session**  
1\. Once you have created a new tool, when you are in the chat session, you will be able to find additional menu option.

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-11-2025-12-02-26-6439-PM.png)2\. Clicking that will list all the available tools registered by you or assigned to you.  
3\. Simply select the required tool and continue with the chat.  
4\. The same tools can also be accessed when interacting with the digital avatar by clicking the same button in the chat bar of the digi avatar.

**How it works**

1\. You submit a question or task to the AI Agent.  
2\. The AI Agent receives your request and processes it.  
3\. The AI Agent connects to the available MCP Server (Internal or External Tools) to fulfill your request.  
4\. The MCP Agent can also perform scheduled checks and automate repeated processes (e.g., data refresh, scheduled reporting) so you get timely insights or reminders without manual initiation.

  
Below diagram illustrates, how GenZ uses MCP to call the available tools to get the required details when needed.

**Understanding MCP (Model Context Protocol)**

**What is MCP**

-   -   MCP is a standardized protocol that lets AI agents securely discover, connect to, and orchestrate many tools and services through a single interface.
        
    -   It handles capability discovery, authentication, context passing, and response normalization so agents can chain tools reliably.
        

**Why MCP matters in GenZ**

![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Aug-11-2025-11-55-29-0647-AM.png)

-   Tool integration
    
    -   Unified interface to talk to any tool or service.
        
    -   Connect tools in real time without hardcoding.
        
    -   Compose multiple tools into workflows.
        
    -   Add/replace tools without changing the agent.
        
-   Better user experience
    
    -   Invoke tools via natural language.
        
    -   Keeps history across tool calls.
        
    -   Auto-selects the best tool for the task.
        
    -   Retries and fallbacks for reliability.
        
-   Enterprise-grade operations
    
    -   Governed, auditable interactions.
        
    -   Usage logs and metrics for compliance.
        
    -   Caching, pooling, and circuit breakers.
        
    -   Supports many concurrent tool interactions.
        

**How MCP enables multi-tool use cases**

-   Internal tools
    
    -   Database/data warehouse connectors, analytics platforms
        
    -   CRM/ERP/HR and custom line-of-business apps
        
    -   Infrastructure admins tools, notebooks, content systems
        
    -   Security systems: IAM, access control, SIEM
        
-   External tools
    
    -   Cloud APIs (AWS, Azure, GCP), SaaS (Salesforce, HubSpot, Slack, M365)
        
    -   Public APIs/feeds, social platforms, external databases
        
    -   Specialized AI services (vision, translation), iPaaS (Zapier, MuleSoft)
        

**Step-by-step MCP flow**

1.  Tool discovery
    
    -   Agent receives request -> MCP queries the tool registry -> matches capabilities -> validates user permissions.
        
2.  Authentication and connection
    
    -   Retrieves credentials -> establishes secure session -> health checks -> initializes session context.
        
3.  Request processing
    
    -   Translates task to tool-specific calls -> validates/sanitizes params -> executes with metadata -> monitors for timeouts/errors.
        
4.  Data processing and response
    
    -   Validates results -> transforms/merges across tools -> formats user-friendly output.
        
5.  Session management
    
    -   Cleans up connections -> logs metrics -> persists context for follow-ups -> records errors if any.
