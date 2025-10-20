#!/bin/bash
# Usage: ./deploy-to-azure.sh <resource-group> <location> <acr-name> <env-name> <frontend-app-name> <node-app-name> <pizzaz-python-app-name> <solar-system-python-app-name>

set -e

if [ "$#" -ne 8 ]; then
  echo "Usage: $0 <resource-group> <location> <acr-name> <env-name> <frontend-app-name> <node-app-name> <pizzaz-python-app-name> <solar-system-python-app-name>"
  exit 1
fi

RESOURCE_GROUP=$1
LOCATION=$2
ACR_NAME=$3
ENV_NAME=$4
FRONTEND_APP_NAME=$5
NODE_APP_NAME=$6
PIZZAZ_PYTHON_APP_NAME=$7
SOLAR_SYSTEM_PYTHON_APP_NAME=$8


# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
az acr login --name $ACR_NAME

# Build and push frontend
az acr build --registry $ACR_NAME --image frontend:latest .

# Build and push Node.js backend
az acr build --registry $ACR_NAME --image pizzaz-node:latest ./pizzaz_server_node

# Build and push Python backend (pizzaz)
az acr build --registry $ACR_NAME --image pizzaz-python:latest ./pizzaz_server_python

# Build and push Python backend (solar-system)
az acr build --registry $ACR_NAME --image solar-system-python:latest ./solar-system_server_python

# Create Container Apps environment
az containerapp env create --name $ENV_NAME --resource-group $RESOURCE_GROUP --location $LOCATION

# Deploy frontend
az containerapp create \
  --name $FRONTEND_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image $ACR_NAME.azurecr.io/frontend:latest \
  --target-port 80 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io

# Deploy Node.js backend
az containerapp create \
  --name $NODE_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image $ACR_NAME.azurecr.io/pizzaz-node:latest \
  --target-port 3000 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io

# Deploy Python backend (pizzaz)
az containerapp create \
  --name $PIZZAZ_PYTHON_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image $ACR_NAME.azurecr.io/pizzaz-python:latest \
  --target-port 8000 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io

# Deploy Python backend (solar-system)
az containerapp create \
  --name $SOLAR_SYSTEM_PYTHON_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image $ACR_NAME.azurecr.io/solar-system-python:latest \
  --target-port 8000 \
  --ingress external \
  --registry-server $ACR_NAME.azurecr.io

echo "Deployment complete!"
echo "To get the URLs for your apps, run:"
echo "az containerapp show --name <app-name> --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv"