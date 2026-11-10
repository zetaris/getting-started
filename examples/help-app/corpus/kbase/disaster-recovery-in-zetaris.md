---
source: kbase
url: https://kbase.zetaris.com/knowledge/disaster-recovery-in-zetaris
title: "Disaster Recovery in Zetaris"
kind: other
lastmod: 2026-01-19
retrieved: 2026-11-10
sha256: 784d11bc19e54b5e7dbbf4a78c1eab7953562ba222b31534b42f1c9a181b6a87
---
# Disaster Recovery in Zetaris

Zetaris supports enterprise-grade backup and recovery to protect application data and ensure minimal downtime in the event of failures. All application data is stored on Persistent Volume Claims (PVCs), which provide reliable persistence across pod restarts, node failures, or upgrades.

This article describes how Zetaris handles backup and recovery, the storage options supported, and the expected recovery time objective (RTO).

#### Storage and Persistence

-   **Persistent Volumes (PVs) / PVCs**  
    Zetaris application pods store data on PVCs provisioned in the Kubernetes cluster.
-   **Supported Storage Options**:
    -   **Block storage** (e.g., AWS EBS, Azure Disk, GCP Persistent Disk)
    -   **Shared storage (NFS/CSI drivers)** for high-availability workloads
-   **Detachment & Reattachment**  
    If a pod or node is terminated, PVCs can be detached from the old node and re-attached to a new one. This ensures data continuity without manual intervention.

#### Backup Strategy

-   **Vendor-Integrated Backup System**  
    Zetaris integrates with the backup system provided by the storage vendor (e.g., Velero, Cloud-native snapshots, CSI snapshots).
-   **Scheduled Backups**  
    Kubernetes **CronJobs** are used to schedule regular backups of PVCs. Frequency can be customized based on retention requirements (e.g., hourly, daily, weekly).
-   **Backup Storage Targets**
    -   Local snapshots (fast recovery)
    -   Remote object storage (S3, Azure Blob, GCS) for disaster recovery scenarios

#### Recovery Procedure

1.  Identify the most recent successful backup from the backup repository.
2.  Restore PVCs from the chosen backup snapshot.
3.  Re-attach restored PVCs to Zetaris pods via Kubernetes.
4.  Restart the Zetaris application stack to resume normal operations.

The process is largely automated if using vendor-provided backup/restore operators (e.g., Velero).

**RTO/RPO guidance**

-   **RTO:** ≤ 1 hour (dominated by data restore + service warm-up + DNS cutover)
    
-   **RPO:** choose per business need; common: 15–60 minutes for prod
    

**Validation**

-   Quarterly DR tests: simulate primary outage; time the restore; verify data integrity and user connectivity.
    
-   Monitor backup job success and snapshot age via Prometheus/Grafana or other vendor tooling.
