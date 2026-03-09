# 🏥 Azure Community Health Analytics Platform

> **A cloud-native, serverless platform for community health data analytics — enabling governments, NGOs, and health organizations to aggregate, analyze, and act on public health data in real-time.**

[![Build Status](https://dev.azure.com/your-org/community-health/_apis/build/status/community-health-ci?branchName=main)](https://dev.azure.com/your-org/community-health/_build)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![IaC: Bicep](https://img.shields.io/badge/IaC-Bicep-orange.svg)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

---

## 🌍 Why This Project?

Millions of people in underserved communities lack access to real-time health data analytics. This platform solves that by providing:

- **Real-time disease outbreak detection** via streaming health event data
- **Vaccination tracking** across facilities, districts, and regions
- **Health facility mapping** for resource allocation and planning
- **Automated alerting** for epidemiological anomalies
- **Open API access** for researchers, governments, and NGOs

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        Azure Community Health Platform                       │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────┐     ┌──────────────┐     ┌────────────────┐                   │
│  │  External  │────▶│  API Mgmt    │────▶│  Function App  │                  │
│  │  Clients   │     │  (Gateway)   │     │  (.NET 8)      │                  │
│  │  & Apps    │     │  Rate-limit  │     │  Consumption   │                  │
│  └───────────┘     │  CORS/Auth   │     └───────┬────────┘                  │
│                     └──────────────┘             │                            │
│                                        ┌─────────┼──────────┐                │
│                                        │         │          │                │
│                                        ▼         ▼          ▼                │
│                              ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│                              │ Cosmos   │ │  Event   │ │ Storage  │          │
│                              │ DB       │ │  Hub     │ │ Account  │          │
│                              │ (NoSQL)  │ │ (Stream) │ │ (Blob)   │          │
│                              └──────────┘ └──────────┘ └──────────┘          │
│                                                                              │
│  ┌──────────┐     ┌──────────────────┐                                       │
│  │ Key      │     │  App Insights +  │                                       │
│  │ Vault    │     │  Log Analytics   │                                       │
│  │ (Secrets)│     │  (Monitoring)    │                                       │
│  └──────────┘     └──────────────────┘                                       │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
Health Workers / IoT Devices / Mobile Apps
             │
             ▼
    ┌─────────────────┐     ┌──────────────────┐
    │   API Mgmt      │────▶│   Function App   │──── Processes Health Records
    │   (Ingestion)   │     │   (Processor)    │──── Validates & Transforms
    └────────┬────────┘     └────────┬─────────┘
             │                       │
             │              ┌────────┼───────────────┐
             │              ▼        ▼               ▼
             │     ┌──────────┐ ┌──────────┐  ┌──────────┐
             │     │ CosmosDB │ │ EventHub │  │ Blob     │
             │     │ Records  │ │ Stream   │  │ Reports  │
             │     └──────────┘ └──────────┘  └──────────┘
             │                       │
             │              ┌────────▼─────────┐
             │              │ Consumer Groups  │
             │              │ - Analytics      │
             │              │ - Alerts Engine  │
             │              └──────────────────┘
             │
    Researchers / Dashboard / Gov Portals
             │
             ▼
    ┌─────────────────┐
    │   API Mgmt      │──── Query Health Records by Region
    │   (Query)       │──── Vaccination Stats by Facility
    └─────────────────┘     Disease Alert Feed
```

---

## 📁 Repository Structure

```
azure-community-health-bicep/
├── 📄 README.md
├── infra/
│   ├── main.bicep                    # Orchestrator — deploys all modules
│   ├── modules/
│   │   ├── apim.bicep                # API Management gateway + API definitions
│   │   ├── appinsights.bicep         # Application Insights + Log Analytics
│   │   ├── cosmosdb.bicep            # Cosmos DB with 4 containers
│   │   ├── eventhub.bicep            # Event Hub for streaming ingestion
│   │   ├── functionapp.bicep         # Serverless compute (Function App)
│   │   ├── keyvault.bicep            # Key Vault for secrets management
│   │   └── storage.bicep             # Storage Account for blob data
│   └── parameters/
│       ├── dev.bicepparam            # Development environment config
│       ├── staging.bicepparam        # Staging environment config
│       └── prod.bicepparam           # Production environment config
└── pipelines/
    ├── ci-build.yaml                 # CI: Validate, build, upload artifact
    └── cd-release.yaml               # CD: Download artifact, deploy to Azure
```

---

## 🔧 Infrastructure Components

| Resource | Purpose | DEV Config | PROD Config |
|----------|---------|------------|-------------|
| **Cosmos DB** | Health records store | 400 RU/s, single region | 1000 RU/s, zone-redundant, auto-failover |
| **Event Hub** | Real-time data stream | Basic, 2 partitions | Standard, 8 partitions, auto-inflate |
| **Function App** | Data processing & APIs | Consumption, .NET 8 | Consumption, .NET 8, managed identity |
| **API Management** | API gateway & policies | Developer SKU | Standard SKU |
| **Key Vault** | Secrets management | Soft delete, RBAC | Soft delete + purge protection |
| **Storage Account** | Blob storage for reports | Standard LRS | Standard LRS, encryption |
| **App Insights** | Monitoring & telemetry | 90-day retention | 90-day retention |

### Cosmos DB Data Model

| Container | Partition Key | Purpose |
|-----------|--------------|---------|
| `HealthRecords` | `/regionId` | Patient health records by region |
| `VaccinationRecords` | `/facilityId` | Vaccination data by health facility |
| `HealthFacilities` | `/district` | Health facility registry |
| `DiseaseAlerts` | `/alertType` | Time-limited disease alerts (30-day TTL) |

---

## 🚀 CI/CD Pipeline

### Build Pipeline (CI) — `ci-build.yaml`

```
┌─────────┐     ┌───────────┐     ┌───────────┐     ┌──────────────────┐
│  Push   │────▶│  Lint &   │────▶│  Build    │────▶│  Upload to       │
│  to     │     │  Validate │     │  ARM JSON │     │  Azure Storage   │
│  main   │     │  What-If  │     │  Manifest │     │  (Versioned)     │
└─────────┘     └───────────┘     └───────────┘     └──────────────────┘
```

**What it does:**
1. **Lint** — Validates all `.bicep` files for syntax errors
2. **Validate** — Runs `az deployment group validate` against DEV
3. **What-If** — Shows planned changes without applying them
4. **Build** — Compiles Bicep to ARM JSON (`az bicep build`)
5. **Package** — Creates versioned artifact with manifest
6. **Upload** — Pushes artifact to Azure Storage Account with version path

### Release Pipeline (CD) — `cd-release.yaml`

```
┌───────────┐     ┌───────────┐     ┌───────────┐     ┌───────────┐
│  CI Build │────▶│  Deploy   │────▶│  Deploy   │────▶│  Deploy   │
│  Trigger  │     │  DEV      │     │  STAGING  │     │  PROD     │
│           │     │  (Auto)   │     │  (Auto)   │     │  (Manual) │
└───────────┘     └───────────┘     └───────────┘     └───────────┘
                        │                 │                 │
                  Download from     Download from     Download from
                  Azure Storage     Azure Storage     Azure Storage
```

**What it does:**
1. **Downloads** versioned artifact from Azure Storage
2. **Deploys** ARM template to each environment sequentially
3. **DEV → STAGING** deploy automatically; **PROD** requires manual approval
4. **Smoke tests** run post-deployment to verify resources

---

## 🛠️ Getting Started

### Prerequisites

- Azure CLI ≥ 2.50
- Bicep CLI ≥ 0.24
- Azure DevOps organization with service connection
- Azure subscription

### Local Deployment

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-community-health-dev --location eastus2

# Deploy to DEV
az deployment group create \
  --resource-group rg-community-health-dev \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam

# Preview changes (What-If)
az deployment group what-if \
  --resource-group rg-community-health-dev \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam
```

### Setting Up ADO Pipelines

1. **Create Service Connection**: Azure DevOps → Project Settings → Service Connections → Azure Resource Manager
2. **Create CI Pipeline**: Pipelines → New → Select `pipelines/ci-build.yaml`
3. **Create CD Pipeline**: Pipelines → New → Select `pipelines/cd-release.yaml`
4. **Configure Environments**: Pipelines → Environments → Create `community-health-dev`, `community-health-staging`, `community-health-prod` → Add approval gates to prod
5. **Create Artifact Storage**: Create storage account `stbicepartifacts` with container `bicep-artifacts`

---

## 🔐 Security

- **RBAC Authorization** on Key Vault (no access policies)
- **Managed Identity** for Function App → Key Vault, Storage access
- **TLS 1.2 minimum** enforced on all services
- **Soft delete + Purge protection** on Key Vault
- **Blob public access disabled** on Storage Account
- **FTP disabled** on Function App
- **HTTPS only** enforced across all services
- **Network ACLs** with Azure Services bypass

---

## 📊 API Endpoints (via API Management)

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health/records/{regionId}` | Fetch health records by region |
| `POST` | `/health/records` | Submit a new health record |
| `GET` | `/health/vaccinations/{facilityId}/stats` | Vaccination statistics |
| `GET` | `/health/alerts` | Active disease alerts |

Rate limited to **100 requests/minute** per subscription key.

---

## 📝 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
