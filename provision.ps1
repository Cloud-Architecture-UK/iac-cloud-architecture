#requires -Modules Az.Resources, Az.Websites

<#
.SYNOPSIS
  Provision the Azure hosting for the Cloud Architecture blog: a resource group and one
  Azure Static Web App (Standard). The PowerShell equivalent of the Terraform in this repo.

.DESCRIPTION
  Deployment is decoupled: this creates the app and prints a deployment token. The site
  repo's GitHub Actions workflow deploys to the app using that token, so there is no repo
  linkage here and either side can be rebuilt without touching the other.

  The script is idempotent: re-running it reconciles to the desired state rather than
  erroring on resources that already exist.

.EXAMPLE
  ./provision.ps1 -SubscriptionId 00000000-0000-0000-0000-000000000000

.EXAMPLE
  ./provision.ps1 -CustomDomain www.cloud-architecture.co.uk
#>

[CmdletBinding()]
param(
  [string]$SubscriptionId,
  [string]$ResourceGroupName = 'rg-cloud-architecture-site-weu',
  [string]$StaticWebAppName  = 'swa-cloud-architecture',
  # Must be a Static Web Apps region: westeurope, westus2, centralus, eastus2, eastasia.
  [string]$Location          = 'westeurope',
  # Free or Standard. Standard is required for password protection, custom auth and an SLA.
  [ValidateSet('Free', 'Standard')]
  [string]$Sku               = 'Standard',
  [string]$CustomDomain      = ''
)

$ErrorActionPreference = 'Stop'
$tags = @{ project = 'cloud-architecture.co.uk'; managed_by = 'powershell' }

# Sign in and select the subscription.
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -Subscription $SubscriptionId | Out-Null }

# Resource group.
if (-not (Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
  Write-Host "Creating resource group $ResourceGroupName in $Location"
  New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $tags | Out-Null
}
else {
  Write-Host "Resource group $ResourceGroupName already exists"
}

# Static Web App.
if (-not (Get-AzStaticWebApp -Name $StaticWebAppName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
  Write-Host "Creating Static Web App $StaticWebAppName ($Sku)"
  New-AzStaticWebApp -Name $StaticWebAppName -ResourceGroupName $ResourceGroupName `
    -Location $Location -SkuName $Sku -SkuTier $Sku -Tag $tags | Out-Null
}
else {
  Write-Host "Static Web App $StaticWebAppName already exists"
}

# Optional custom domain. Create the CNAME Azure returns at your DNS host, then re-run.
if ($CustomDomain) {
  $existing = Get-AzStaticWebAppCustomDomain -Name $StaticWebAppName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
  if (-not ($existing | Where-Object { $_.Name -eq $CustomDomain })) {
    Write-Host "Adding custom domain $CustomDomain"
    New-AzStaticWebAppCustomDomain -Name $StaticWebAppName -ResourceGroupName $ResourceGroupName `
      -DomainName $CustomDomain -ValidationMethod 'cname-delegation' | Out-Null
  }
  else {
    Write-Host "Custom domain $CustomDomain already present"
  }
}

# Deployment token. Paste this into the site repo's GitHub secret AZURE_STATIC_WEB_APPS_API_TOKEN.
# You can also read it from the portal under the app's "Manage deployment token".
$token = (Get-AzStaticWebAppSecret -Name $StaticWebAppName -ResourceGroupName $ResourceGroupName).Property.apiKey

Write-Host ''
Write-Host 'Deployment token (add as GitHub secret AZURE_STATIC_WEB_APPS_API_TOKEN in the site repo):'
Write-Output $token
