#!/bin/bash
set -e

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -resourceGroup|-r) resourceGroupName="$2"; shift ;;
        -botEndpoint|-e) botEndpoint="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# === Validation ===
if [[ -z "$resourceGroupName" || -z "$botEndpoint" ]]; then
    echo "Usage: $0 -resourceGroup <resourceGroupName> -botEndpoint <bot endpoint>"
    exit 1
fi

# Variables
appName="unleash-teams-bot"
graphAppId="00000003-0000-0000-c000-000000000000" # Microsoft Graph
location="global"

# Microsoft Graph permission IDs (App role GUIDs)
permissionIds=(
  "7ab1d382-f21e-4acd-a863-ba3e13f7da61" # Directory.Read.All
  "332a536c-c7ef-4017-ab91-336970924f0d" # Sites.Read.All
  "242607bd-1d2c-432c-82eb-bdb27baa23ab" # TeamSettings.Read.All
  "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
)

# Get access token for Microsoft Graph
accessToken=$(az account get-access-token --resource https://graph.microsoft.com --query accessToken -o tsv)

# Build requiredResourceAccess JSON
resourceAccessJson=$(jq -n --argjson ids "$(printf '%s\n' "${permissionIds[@]}" | jq -R . | jq -cs .)" --arg gaid "$graphAppId" '
{
  resourceAccess: $ids | map({id: ., type: "Role"}),
  resourceAppId: $gaid 
}')

# Generate OAuth2 scope ID
scopeId=$(uuidgen)

# Construct full application body
appJson=$(jq -n \
  --arg name "$appName" \
  --arg sid "$scopeId" \
  --argjson resourceAccess "$resourceAccessJson" '
{
  displayName: $name,
  signInAudience: "AzureADandPersonalMicrosoftAccount",
  requiredResourceAccess: [$resourceAccess],
  api: {
    requestedAccessTokenVersion: 2,
    knownClientApplications: ["5e3ce6c0-2b1f-4285-8d4b-75ee78787346"],
    oauth2PermissionScopes: [
      {
        adminConsentDisplayName: "Unleash Teams Bot",
        adminConsentDescription: "Allow Users Access Unleash Team App",
        id: $sid,
        isEnabled: true,
        type: "User",
        userConsentDisplayName: "Unleash Teams Bot",
        userConsentDescription: "Allow Users Access Unleash Team App",
        value: "tabs"
      }
    ]
  }
}')

appResponse=$(curl -s -X POST https://graph.microsoft.com/v1.0/applications \
  -H "Authorization: Bearer $accessToken" \
  -H "Content-Type: application/json" \
  -d "$appJson")

appId=$(echo "$appResponse" | jq -r '.appId')
appObjectId=$(echo "$appResponse" | jq -r '.id')

echo "Created App with App ID: $appId"

secretResponse=$(curl -s -X POST "https://graph.microsoft.com/v1.0/applications/$appObjectId/addPassword" \
  -H "Authorization: Bearer $accessToken" \
  -H "Content-Type: application/json" \
  -d '{ "passwordCredential": { "displayName": "secret" } }')

appSecret=$(echo "$secretResponse" | jq -r '.secretText')

az bot create \
  --resource-group "$resourceGroupName" \
  --name "$appName" \
  --location "$location" \
  --sku S1 \
  --display-name "$appName" \
  --endpoint "$botEndpoint" \
  --appid "$appId" \
  --app-type MultiTenant

az bot msteams create \
  --resource-group "$resourceGroupName" \
  --name "$appName" \
  --location "$location"

echo "Bot Id: $appId"
echo "Bot Password : $appSecret"

echo "✅ App registration and bot setup complete."
echo "⚠️  You still need to manually **admin consent** the app in the Azure portal."