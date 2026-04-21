$results = foreach ($sub in Get-AzSubscription -TenantId (Get-AzContext).Tenant.Id) {
    $resp = Invoke-AzRestMethod -Method GET `
        -Path "/subscriptions/$($sub.Id)/providers/microsoft.insights/diagnosticSettings?api-version=2021-05-01-preview"

    if ($resp.StatusCode -ne 200) {
        [pscustomobject]@{
            Subscription   = $sub.Name
            SubscriptionId = $sub.Id
            SettingName    = "(error $($resp.StatusCode))"
            WorkspaceId    = $null
            Categories     = $null
        }
        continue
    }

    $settings = ($resp.Content | ConvertFrom-Json).value

    if (-not $settings) {
        [pscustomobject]@{
            Subscription   = $sub.Name
            SubscriptionId = $sub.Id
            SettingName    = '(none)'
            WorkspaceId    = $null
            Categories     = $null
        }
    } else {
        foreach ($s in $settings) {
            [pscustomobject]@{
                Subscription   = $sub.Name
                SubscriptionId = $sub.Id
                SettingName    = $s.name
                WorkspaceId    = $s.properties.workspaceId
                Categories     = ($s.properties.logs | Where-Object enabled | ForEach-Object category) -join ','
            }
        }
    }
}

$results | Sort-Object Subscription | Select-Object `
    Subscription,
    SettingName,
    @{ n = 'Workspace';  e = { if ($_.WorkspaceId) { ($_.WorkspaceId -split '/')[-1] } } },
    @{ n = 'Categories'; e = { $_.Categories } } |
    Format-Table -AutoSize -Wrap