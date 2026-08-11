# iac-cloud-architecture

Infrastructure to stand up the Azure hosting for an Astro blog: a resource group and one **Azure Static Web App** (Standard SKU, for password protection, custom domains, and an SLA). Run it once and you have somewhere to deploy to.

Two equivalent paths are provided, both landing at the same place:

- **`provision.ps1`** - the Az PowerShell module. Reach for this if you already live in PowerShell; it is the same language as the [Build and Secure Microsoft 365](https://www.cloud-architecture.co.uk/blog/) guides.
- **Terraform** (`*.tf`) - declarative and reviewed in a pull request, so the whole thing rebuilds from scratch on demand. This is what I keep for infrastructure projects.

This is the infrastructure behind [cloud-architecture.co.uk](https://www.cloud-architecture.co.uk). The full walkthrough, portal steps and all, is in the post: [How I Built This Site, Step by Step](https://www.cloud-architecture.co.uk/blog/why-this-site-exists/).

Site deployment is **decoupled**: the site repo deploys via its own GitHub Actions workflow using the deployment token these produce. No portal linkage, so either side can be rebuilt without touching the other.

## Deploy with PowerShell

```powershell
Connect-AzAccount
./provision.ps1 -SubscriptionId <your-subscription-id>
# optional: -CustomDomain www.cloud-architecture.co.uk
```

It creates the resource group and Static Web App (idempotent, so re-running is safe), then prints the deployment token to add as the site repo's `AZURE_STATIC_WEB_APPS_API_TOKEN` secret. Requires the `Az.Resources` and `Az.Websites` modules (`Install-Module Az`).

## Prerequisites

- Terraform >= 1.6
- Azure CLI, logged in with `az login`
- `export ARM_SUBSCRIPTION_ID=<your-subscription-id>` (azurerm v4 requires it)

## Deploy with Terraform

```bash
az login
export ARM_SUBSCRIPTION_ID=<your-subscription-id>
terraform init
terraform plan
terraform apply
```

Read the plan before you approve it: it creates exactly two things, the resource group and the Static Web App.

## Wire up the site deploy

Print the deployment token and hand it to the site repo:

```bash
terraform output -raw deployment_token
```

Add the value as a secret named `AZURE_STATIC_WEB_APPS_API_TOKEN` in the site repo, under Settings, Secrets and variables, Actions. Its `Azure/static-web-apps-deploy@v1` workflow then publishes to this Static Web App. The token is scoped to this one app.

## Custom domain (optional)

```hcl
# terraform.tfvars
custom_domain = "www.example.com"
```

Add the CNAME Azure asks for at your DNS host, then `terraform apply` again. The managed TLS certificate is issued and renewed for you.

## Variables

See `variables.tf`. The ones you're most likely to set: `location` (must be a Static Web Apps region), `static_web_app_name`, `sku_tier`/`sku_size`, and `custom_domain`. Copy `terraform.tfvars.example` to `terraform.tfvars` to override the defaults.

## State

State is local by default and holds the deployment token in plaintext, which is why `*.tfstate` and `*.tfvars` are git-ignored: never commit them. This is built to run once, so when you're done you can delete the local state, or keep it if you want to `terraform destroy` later.
