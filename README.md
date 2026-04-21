# Azure Activity Log Sentinel audit

PowerShell script to audit Azure Activity Log diagnostic settings across **all subscriptions** in a tenant and verify they are exported to Microsoft Sentinel / Log Analytics.

The Azure portal only shows Activity Log export settings **one subscription at a time** (Activity Log → *Export activity logs* → *Edit Settings*). This script gives you a single, tenant-wide view so you can quickly spot subscriptions that are missing, misconfigured, or sending to the wrong workspace.

## What it reports

For every subscription visible to the signed-in user:

| Column       | Description                                                                 |
| ------------ | --------------------------------------------------------------------------- |
| `Subscription` | Subscription display name                                                 |
| `SettingName`  | Name of the diagnostic setting (`(none)` if no export is configured)      |
| `Workspace`    | Target Log Analytics workspace name (the workspace Sentinel is enabled on)|
| `Categories`   | Enabled Activity Log categories (e.g. `Administrative,Security,Policy…`)  |

The full `WorkspaceId` (ARM resource ID) is preserved in the `$results` variable for CSV export.

## Prerequisites

- An Azure account with at least **Reader** on the subscriptions you want to audit.
- One of:
  - **Azure Cloud Shell** (PowerShell) — recommended, nothing to install, already authenticated.
  - Local **PowerShell 7+** with the `Az.Accounts` module installed (`Install-Module Az.Accounts`).

## How to run

### Option 1 — Azure Cloud Shell (easiest)

1. Open <https://shell.azure.com> and switch to **PowerShell**.
2. Upload `AzActivityLoggingCheck.ps1` via the *Manage files → Upload* button, **or** paste the script contents directly into the shell.
3. Run it:

   ```powershell
   ./AzActivityLoggingCheck.ps1
   ```

### Option 2 — Local PowerShell

```powershell
Connect-AzAccount -TenantId <your-tenant-id>
./AzActivityLoggingCheck.ps1
```

### Export to CSV

After running the script, `$results` still holds the full data (including full workspace resource IDs):

```powershell
$results | Export-Csv -Path ./activity-log-export.csv -NoTypeInformation
```

## How it works

The script calls the ARM REST API directly:

```
GET /subscriptions/{id}/providers/microsoft.insights/diagnosticSettings?api-version=2021-05-01-preview
```

via `Invoke-AzRestMethod`. This avoids `Set-AzContext` per subscription (faster) and sidesteps the upcoming breaking-change warnings on `Get-AzDiagnosticSetting` (Az 15 / Az.Monitor 7).

## Notes & limitations

- Subscription-level diagnostic settings are **not** queryable via Azure Resource Graph today — that's why this script iterates subscriptions.
- Cloud Shell is bound to a single tenant. For multi-tenant audits, run locally and `Connect-AzAccount -TenantId <id>` for each tenant.
- Subscriptions the caller can't read are returned with `(error 403)` in `SettingName`.
