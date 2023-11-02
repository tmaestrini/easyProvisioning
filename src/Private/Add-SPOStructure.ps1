Function Add-SPOStructure {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true
    )][hashtable]$SPOTemplateConfig  
  )

  Function New-Site([hashtable]$SPOTemplateConfigStructure) {
    Write-Host "Creating site '$($SPOTemplateConfigStructure.keys)': " -NoNewline
    $atts = @{
      Title = $SPOTemplateConfigStructure.keys
      Url   = "$($spoUrl)$($SPOTemplateConfigStructure.values.Url)"
      Lcid  = $SPOTemplateConfigStructure.values.Lcid ?? 1031
    }
    
    # Create new site
    $createdSite = $null
    try {
      switch ($SPOTemplateConfigStructure.values.Type) {
        "Communication" { $createdSite = New-PnPSite -Wait -Type CommunicationSite @atts -SiteDesign $SPOTemplateConfigStructure.values.Template -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
        "Team" { $createdSite = New-PnPSite -Wait -Type TeamSite @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
        "SPOTeam" { $createdSite = New-PnPSite -Wait -Type TeamSiteWithoutMicrosoft365Group @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
        Default {}
      }

      Write-Host $($createdSite) -NoNewline
      Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ❌ failed: $($_)" -ForegroundColor Red      
    }

    # Handle Hub association
    if ($SPOTemplateConfigStructure.values.IsHub -or $SPOTemplateConfigStructure.values.ConnectedHubsite) {
      try {
        Write-Host "⎿ Handling hub association(s): " -NoNewline
        if ($SPOTemplateConfigStructure.values.IsHub) { Register-PnPHubSite -Site $createdSite -Connection $global:SPOAdminConnection }
        if ($SPOTemplateConfigStructure.values.ConnectedHubsite -and $SPOTemplateConfigStructure.values.IsHub) { 
          Add-PnPHubToHubAssociation -SourceUrl $createdSite -TargetUrl $SPOTemplateConfigStructure.values.ConnectedHubsite -Connection $global:SPOAdminConnection
        }
        if ($SPOTemplateConfigStructure.values.ConnectedHubsite) { 
          Add-PnPHubSiteAssociation -Site $createdSite -HubSite $SPOTemplateConfigStructure.values.ConnectedHubsite -Connection $global:SPOAdminConnection
        }
          
        Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
      }
      catch {
        Write-Host " ❌ failed: $($_)" -ForegroundColor Red
      }
    }

    # connect to new site and return connection for further purpose
    return (Connect-PnPOnline -Url $createdSite -ReturnConnection -Interactive)
  }

  Function Add-SiteContentOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [Object[]]$SPOTemplateContentConfig) {
    foreach ($siteContent in $SPOTemplateContentConfig) {
      try {
        Write-Host "⎿ Creating content <$($siteContent.keys)>: '$($siteContent.values.Title)'" -NoNewline
        $quickLaunch = $siteContent.values.OnQuickLaunch -and $siteContent.values.OnQuickLaunch -eq $true ? $true : $false
        $list = New-PnPList -Template $siteContent.keys -Title $siteContent.values.Title -OnQuickLaunch:$quickLaunch -Connection $siteConnection
        Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
      }
      catch {
        Write-Host " ❌ failed: $($_)" -ForegroundColor Red
      }
    }
  }

  Function Invoke-PnPSiteTemplateOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [string]$templatePath, [hashtable]$templateParameters) {
    Write-Host "⎿ Invoking site template (PnP): '$($templatePath)' [started]"
    try {
      Invoke-PnPSiteTemplate -Path $templatePath -Parameters $templateParameters -Connection $siteConnection
      Write-Host "⎿ Invoking site template (PnP): '$($templatePath)'" -NoNewline
      Write-Host " ✔︎ OK" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ❌ failed: $($_)" -ForegroundColor Red
    }
  }

  if ($null -eq $SPOTemplateConfig.TenantId) { throw "No SharePoint tenant id provided" }
  if ($null -eq $SPOTemplateConfig.Structure) { throw "No SharePoint Structure provided" }

  # Start provisioning
  $spoUrl = [System.UriBuilder]::new("https", "$($SPOTemplateConfig.TenantId).sharepoint.com")
  $spoAdminUrl = [System.UriBuilder]::new("https", "$($SPOTemplateConfig.TenantId)-admin.sharepoint.com")
  Connect-SPOAdminUrl -Url $spoAdminUrl

  # Create sites and content
  foreach ($siteStructure in $SPOTemplateConfig.Structure) {
    $newSiteConnection = New-Site -SPOTemplateConfigStructure $siteStructure
    Add-SiteContentOnTarget -siteConnection $newSiteConnection -SPOTemplateContentConfig $siteStructure.values.Content
    if ($siteStructure.values.'Provisioning Template') {
      Invoke-PnPSiteTemplateOnTarget -templatePath $siteStructure.values.'Provisioning Template' -templateParameters $siteStructure.values.'Provisioning Parameters'`
        -siteConnection $newSiteConnection 
    }
  }
}