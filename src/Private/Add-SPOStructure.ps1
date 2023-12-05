Function Add-SPOStructure {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true
    )][hashtable]$SPOTemplateConfig,  
    [Parameter(
      Mandatory = $false
    )][switch]$KeepConnectionsAlive  
  )

  Function New-Site([hashtable]$SPOTemplateConfigStructure) {
    Write-Host "⭐️ Creating site '$($SPOTemplateConfigStructure.keys)': " -NoNewline
    $atts = @{
      Title = $SPOTemplateConfigStructure.keys
      Url   = "$($spoUrl)$($SPOTemplateConfigStructure.values.Url.TrimStart('/'))"
      Lcid  = $SPOTemplateConfigStructure.values.Lcid ?? 1031
    }
    
    # Create new site
    $createdSite = $null
    try {
      $createdSite = (Get-PnPTenantSite -Identity $atts.Url -Connection $global:SPOAdminConnection -ErrorAction SilentlyContinue).Url
      if ($null -eq $createdSite) {
        switch ($SPOTemplateConfigStructure.values.Type) {
          "Communication" { $createdSite = New-PnPSite -Wait -Type CommunicationSite @atts -SiteDesign $SPOTemplateConfigStructure.values.Template -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
          "Team" { $createdSite = New-PnPSite -Wait -Type TeamSite @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
          "SPOTeam" { $createdSite = New-PnPSite -Wait -Type TeamSiteWithoutMicrosoft365Group @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
          Default { throw "Site type not matching" }
        }
      }
      Write-Host $($createdSite) -NoNewline
      Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ❌ failed: $($_)" -ForegroundColor Red
      exit 1   
    }

    # Handle Hub association
    if ($SPOTemplateConfigStructure.values.IsHub -or $SPOTemplateConfigStructure.values.ConnectedHubsite) {
      try {
        Write-Host "⎿ Handling hub association(s): " -NoNewline
        if ($SPOTemplateConfigStructure.values.IsHub) { $null = Register-PnPHubSite -Site $createdSite -Connection $global:SPOAdminConnection -ErrorAction SilentlyContinue }
        if ($SPOTemplateConfigStructure.values.ConnectedHubsite -and $SPOTemplateConfigStructure.values.IsHub) { 
          $null = Add-PnPHubToHubAssociation -SourceUrl $createdSite -TargetUrl "$($spoUrl)$($SPOTemplateConfigStructure.values.ConnectedHubsite.TrimStart('/'))" -Connection $global:SPOAdminConnection
        }
        elseif ($SPOTemplateConfigStructure.values.ConnectedHubsite) { 
          $null = Add-PnPHubSiteAssociation -Site $createdSite -HubSite "$($spoUrl)$($SPOTemplateConfigStructure.values.ConnectedHubsite.TrimStart('/'))" -Connection $global:SPOAdminConnection
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

  Function Set-HomepageLayout([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [Object[]]$SPOStructureSiteTemplateConfig) {
    try {
      Write-Host "⎿ Setting homepage layout to <$($SPOStructureSiteTemplateConfig.values.HomepageLayout)>: " -NoNewline
      $homepageRefUrl = Get-PnPHomePage -Connection $siteConnection
      $homepage = Get-PnPPage -Identity $homepageRefUrl.Split("/")[-1] -Connection $siteConnection

      if ("Article" -eq $SPOStructureSiteTemplateConfig.values.HomepageLayout -or
        "Home" -eq $SPOStructureSiteTemplateConfig.values.HomepageLayout -or
        "SingleWebPartAppPage" -eq $SPOStructureSiteTemplateConfig.values.HomepageLayout) {
        $null = Set-PnPPage -Identity $homepage -LayoutType $SPOStructureSiteTemplateConfig.values.HomepageLayout -Connection $siteConnection
      }
      else {
        throw "Homepage layout <$($SPOStructureSiteTemplateConfig.values.HomepageLayout)> does not exist."
      }
      
      Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ❌ failed: $($_)" -ForegroundColor Red      
    }
  }

  Function Add-SiteContentOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [Object[]]$SPOTemplateContentConfig) {
    foreach ($siteContent in $SPOTemplateContentConfig) {
      # Create libraries
      try {
        Write-Host "⎿ Creating content <$($siteContent.keys)>: '$($siteContent.values.Title)'" -NoNewline
        $quickLaunch = $siteContent.values.OnQuickLaunch -and $siteContent.values.OnQuickLaunch -eq $true ? $true : $false

        $objectUrl = ConvertTo-PascalCase $siteContent.values.Title
        switch ($siteContent.keys) {
          "DocumentLibrary" { $list = New-PnPList -Template DocumentLibrary -Url $objectUrl -Title $siteContent.values.Title -OnQuickLaunch:$quickLaunch -Connection $siteConnection }
          "MediaLibrary" {
            # This is a special media library by this provisioning engine 😍 
            Enable-PnPFeature -Identity 6e1e5426-2ebd-4871-8027-c5ca86371ead -Scope Site -Force -Connection $siteConnection # VideoAndRichMedia
            Enable-PnPFeature -Identity 4bcccd62-dcaf-46dc-a7d4-e38277ef33f4 -Scope Site -Force -Connection $siteConnection # Asset Library
            Enable-PnPFeature -Identity 3bae86a2-776d-499d-9db8-fa4cdc7884f8 -Scope Site -Force -Connection $siteConnection # Document Set
            
            $list = New-PnPList -Template DocumentLibrary -Url $objectUrl -Title $siteContent.values.Title -OnQuickLaunch:$quickLaunch -Connection $siteConnection 
            Add-PnPContentTypeToList -List $list -ContentType 0x0101009148F5A04DDD49CBA7127AADA5FB792B -DefaultContentType -Connection $siteConnection 
            Add-PnPContentTypeToList -List $list -ContentType 0x0101009148F5A04DDD49CBA7127AADA5FB792B00291D173ECE694D56B19D111489C4369D -Connection $siteConnection 
            Add-PnPContentTypeToList -List $list -ContentType 0x0101009148F5A04DDD49CBA7127AADA5FB792B00AADE34325A8B49CDA8BB4DB53328F214 -Connection $siteConnection
          }
          "List" { $list = New-PnPList -Template GenericList -Url $objectUrl -Title $siteContent.values.Title -OnQuickLaunch:$quickLaunch -Connection $siteConnection }
          "EventsList" { $list = New-PnPList -Template Events -Url $objectUrl -Title $siteContent.values.Title -OnQuickLaunch:$quickLaunch -Connection $siteConnection }
          Default {}
        }
        
        Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
      }
      catch {
        Write-Host " ❌ failed: $($_)" -ForegroundColor Red
      }

      # Create folder structure (if defined)
      try {
        if (($siteContent.keys -eq "DocumentLibrary" -or $siteContent.keys -eq "MediaLibrary") -and $siteContent.values.Folders) { 
          Write-Host "⎿ Creating folder structure:" -NoNewline
          Add-FoldersToList -siteConnection $siteConnection -ContentDoclibFolders $siteContent.values.Folders `
            -parentPath "$objectUrl" #-WhatIf
          Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
        } 
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
    if ($siteStructure.Values.HomepageLayout) {
      Set-HomepageLayout -siteConnection $newSiteConnection -SPOStructureSiteTemplateConfig $siteStructure
    }
    
    Add-SiteContentOnTarget -siteConnection $newSiteConnection -SPOTemplateContentConfig $siteStructure.Values.Content

    if ($siteStructure.Values.'Provisioning Template') {
      Invoke-PnPSiteTemplateOnTarget -templatePath $siteStructure.Values.'Provisioning Template' -templateParameters $siteStructure.Values.'Provisioning Parameters'`
        -siteConnection $newSiteConnection 
    }

    if ($siteStructure.Values.CopyHubNavigation) {
      Copy-Hubnavigation -SPOStructureSiteTemplateConfig $siteStructure -SPOBaseUrl $spoUrl
    }
  }

  if (-not $KeepConnectionsAlive) {
    Disconnect-SPOAdminUrl
  }
}
