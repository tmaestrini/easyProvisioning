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
    
    $createdSite = $null
    try {
      switch ($SPOTemplateConfigStructure.values.Type) {
        "Communication" { $createdSite = New-PnPSite -Wait -Type CommunicationSite @atts -SiteDesign $SPOTemplateConfigStructure.values.Template -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
        "Team" { $createdSite = New-PnPSite -Wait -Type TeamSite @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
        "SPOTeam" { $createdSite = New-PnPSite -Wait -Type TeamSiteWithoutMicrosoft365Group @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
        Default {}
      }

      Write-Host $($createdSite) -NoNewline
      Write-Host " ✔︎ OK" -ForegroundColor DarkGreen
      return (Connect-PnPOnline -Url $createdSite -ReturnConnection -Interactive)
    }
    catch {
      <#Do this if a terminating exception happens#>
      Write-Host " ❌ failed: $($_)" -ForegroundColor Red      
    }

  }

  Function Add-SiteContentOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [Object[]]$SPOTemplateContentConfig) {
    foreach ($siteContent in $SPOTemplateContentConfig) {
      try {
        Write-Host "⎿ Creating content <$($siteContent.keys)>: '$($siteContent.values.Title)'" -NoNewline
        $quickLaunch3 = $siteContent.values.OnQuickLaunch -and $siteContent.values.OnQuickLaunch -eq $true ? $true : $false
        $list = New-PnPList -Template $siteContent.keys -Title $siteContent.values.Title -OnQuickLaunch:$quickLaunch -Connection $siteConnection
        Write-Host " ✔︎ OK" -ForegroundColor DarkGreen
      }
      catch {
        Write-Host " ❌ failed: $($_)" -ForegroundColor Red      
      }
    }
  }

  Function Invoke-PnPSiteTemplateOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection) {
    throw "Invoke-PnPSiteTemplateOnTarget not implemented yet"
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
    if ($siteStructure.values.'Provisioning Template') { Invoke-PnPSiteTemplateOnTarget -siteConnection $newSiteConnection }
  } 
}