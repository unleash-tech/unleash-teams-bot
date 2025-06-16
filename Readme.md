# Initializing the Unleash Teams Bot

This guide walks you through the process of deploying and initializing the Unleash Teams Bot within your Azure environment.

---

## Prerequisites

Before starting, ensure the following prerequisites are met:

- **Azure CLI Installed**  
  You must have the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed on your machine.

- **Azure Subscription**  
  You must have access to an active Azure subscription.

- **Permissions**  
  The user performing the setup must have at least **Contributor** permissions on the target resource group.

- **Microsoft Teams Admin Access**  
  You must have access to the [Microsoft Teams admin center](https://admin.teams.microsoft.com/) with sufficient permissions to manage Teams settings and configurations.

---

## Step 1: Create Entra Application and Bot Resources in Azure

### 1. Log in to Azure

Make sure you are logged in with the correct user account and operating in the correct subscription context:

```bash
az login
az account set --subscription "<your-subscription-name-or-id>
```

Replace <your-subscription-name-or-id> with the name or ID of the Azure subscription you intend to use.

### 2. Obtain the Bot Endpoint

Request the **bot endpoint URL** from your Unleash representative.


