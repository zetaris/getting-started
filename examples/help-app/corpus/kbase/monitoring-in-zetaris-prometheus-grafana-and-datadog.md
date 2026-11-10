---
source: kbase
url: https://kbase.zetaris.com/knowledge/monitoring-in-zetaris-prometheus-grafana-and-datadog
title: "Monitoring in Zetaris: Prometheus, Grafana, and Datadog"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 8a11b309a572f1c33045e7b653501d219965ea310867f791221e4f622f1a3724
---
# Monitoring in Zetaris: Prometheus, Grafana, and Datadog

Zetaris supports robust monitoring of infrastructure and applications through a combination of **Prometheus, Grafana, and Datadog**.

-   **Prometheus** provides metrics collection and storage.
    
-   **Grafana** enables visualization and dashboarding.
    
-   **Datadog** is available as a SaaS option for organizations preferring managed monitoring and analytics.
    

Depending on the deployment model (client environment vs SaaS), different monitoring stacks are applied.

### ![](https://kbase.zetaris.com/hs-fs/hubfs/image-png-Sep-30-2025-05-01-53-8389-AM.png)

### Components

#### Prometheus – Metrics Collection & Storage

-   **Purpose**: Collects, stores, and queries time-series metrics from Zetaris components, Kubernetes clusters, and services.
    
-   **Key Features**:
    
    -   Time-series database optimized for metrics.
        
    -   Pull-based model to scrape metrics from exporters (e.g., node, application, Kubernetes).
        
    -   Native integration with Kubernetes for service discovery.
        
-   **Deployment**: Installed as a **Helm chart** on the Kubernetes cluster hosting Zetaris services.
    

#### Grafana – Visualization & Dashboards

-   **Purpose**: Provides interactive dashboards and visualization for Prometheus metrics.
    
-   **Key Features**:
    
    -   Pre-configured dashboards for cluster health, service uptime, and performance metrics.
        
    -   Alerting rules (integrated with email, Slack, PagerDuty, etc.).
        
    -   Extensible with plugins and other data sources.
        
-   **Deployment**: Installed as a **Helm chart** on the Kubernetes cluster, connecting directly to Prometheus.
    

#### Datadog – SaaS Monitoring (Optional)

-   **Purpose**: Cloud-hosted monitoring and observability platform.
    
-   **Use Case**: For clients who prefer a fully managed solution without maintaining Prometheus/Grafana infrastructure.
    
-   **Capabilities**:
    
    -   Out-of-the-box integrations with Kubernetes, cloud providers, and Zetaris services.
        
    -   Dashboards, logs, metrics, and distributed tracing under a single SaaS platform.
        
    -   Requires enabling Datadog agents within the client environment.
        

### Deployment Models

1.  **Client Environments**
    
    -   **Prometheus** collects metrics.
        
    -   **Grafana** visualizes metrics.
        
    -   Both deployed using Helm charts on the client’s Kubernetes cluster.
        
2.  **Zetaris SaaS (Datadog)**
    
    -   Zetaris-managed Datadog instance.
        
    -   Provides centralized monitoring, dashboards, and alerting for client workloads.
        
    -   Reduces operational overhead of managing Prometheus and Grafana.
        

### How It Works Together

**1\. Metrics Collection**

-   **Prometheus** scrapes metrics from Zetaris services running on Kubernetes (e.g., system health, performance, usage).
    
-   These metrics are stored in its time-series database for querying and analysis.
    

 **2\. Visualization & Dashboards**

-   **Grafana** connects to Prometheus as a data source.
    
-   Metrics are displayed in **interactive dashboards** for real-time monitoring of clusters, services, and workloads.
    

 **3\. Alerting & Notifications**

-   **Alerts** can be defined either in Prometheus or Grafana.
    
-   Notifications can be sent to Slack, email, PagerDuty, or integrated into Datadog pipelines.
    

**4\. SaaS Option with Datadog**

1.  -   In **SaaS deployments**, **Datadog** can replace Prometheus + Grafana with a fully managed monitoring solution.
        
    -   Provides **end-to-end observability** (metrics, logs, traces) without requiring clients to manage infrastructure.
