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
    $type = $SPOTemplateConfigStructure.Hub ? "Hub" : $SPOTemplateConfigStructure.Site ? "Site" : $null
    if ($null -eq $type) { throw "No or wrong site type provided" }

    $title = $SPOTemplateConfigStructure[$type]
    $isHub = $type -eq "Hub"
    
    Write-Host "⭐️ Creating $($type) '$($title)': " -NoNewline
    $atts = @{
      Title = $title
      Url   = "$($spoUrl)$($SPOTemplateConfigStructure.Url.TrimStart('/'))"
      Lcid  = $SPOTemplateConfigStructure.Lcid ?? 1031
    }
    
    # Create new site
    $createdSite = $null
    try {
      $createdSite = (Get-PnPTenantSite -Identity $atts.Url -Connection $global:SPOAdminConnection -ErrorAction SilentlyContinue).Url
      if ($null -eq $createdSite) {
        switch ($SPOTemplateConfigStructure.Type) {
          "Communication" { 
            $siteDesign = $null -eq $SPOTemplateConfigStructure.Template ? "Blank" : $SPOTemplateConfigStructure.Template
            $atts.SiteDesign = $siteDesign
            $createdSite = New-PnPSite -Wait -Type CommunicationSite @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection 
          }
          "Team" { $createdSite = New-PnPSite -Wait -Type TeamSite @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
          "SPOTeam" { $createdSite = New-PnPSite -Wait -Type TeamSiteWithoutMicrosoft365Group @atts -TimeZone UTCPLUS0100_AMSTERDAM_BERLIN_BERN_ROME_STOCKHOLM_VIENNA -Connection $global:SPOAdminConnection }
          Default { throw "Site type not matching" }
        }
      }

      # Set sharing capability (optional)
      switch ($SPOTemplateConfigStructure.DisableCompanyWideSharingLinks) {
        "True" { $DisableCompanyWideSharingLinks = [Microsoft.Online.SharePoint.TenantAdministration.CompanyWideSharingLinksPolicy]::Disabled }
        "False" { $DisableCompanyWideSharingLinks = [Microsoft.Online.SharePoint.TenantAdministration.CompanyWideSharingLinksPolicy]::NotDisabled }
        Default { $DisableCompanyWideSharingLinks = [Microsoft.Online.SharePoint.TenantAdministration.CompanyWideSharingLinksPolicy]::NotDisabled }
      }
      
      switch ($SPOTemplateConfigStructure.SharingCapability) {
        "ExistingExternalUserSharingOnly" { Set-PnPSite -Identity $createdSite -SharingCapability ExistingExternalUserSharingOnly -DisableCompanyWideSharingLinks $DisableCompanyWideSharingLinks -Connection $global:SPOAdminConnection }
        "ExternalUserAndGuestSharing" { Set-PnPSite -Identity $createdSite -SharingCapability ExternalUserAndGuestSharing -DisableCompanyWideSharingLinks $DisableCompanyWideSharingLinks -Connection $global:SPOAdminConnection }
        "ExternalUserSharingOnly" { Set-PnPSite -Identity $createdSite -SharingCapability ExternalUserSharingOnly -DisableCompanyWideSharingLinks $DisableCompanyWideSharingLinks -Connection $global:SPOAdminConnection }
        "Disabled" { Set-PnPSite -Identity $createdSite -SharingCapability Disabled -DisableCompanyWideSharingLinks $DisableCompanyWideSharingLinks -Connection $global:SPOAdminConnection }
        Default { Set-PnPSite -Identity $createdSite -SharingCapability Disabled -DisableCompanyWideSharingLinks $DisableCompanyWideSharingLinks -Connection $global:SPOAdminConnection }
      }

      Write-Host $($createdSite) -NoNewline
      Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ✘ failed: $($_)" -ForegroundColor Red
      exit 1   
    }

    # Handle Hub association
    if ($isHub -or $SPOTemplateConfigStructure.ConnectedHubsite) {
      try {
        Write-Host "⎿ Handling hub association(s): " -NoNewline
        if ($isHub) { $null = Register-PnPHubSite -Site $createdSite -Connection $global:SPOAdminConnection -ErrorAction SilentlyContinue }
        if ($SPOTemplateConfigStructure.ConnectedHubsite -and $isHub) { 
          $null = Add-PnPHubToHubAssociation -SourceUrl $createdSite -TargetUrl "$($spoUrl)$($SPOTemplateConfigStructure.ConnectedHubsite.TrimStart('/'))" -Connection $global:SPOAdminConnection
        }
        elseif ($SPOTemplateConfigStructure.ConnectedHubsite) { 
          $null = Add-PnPHubSiteAssociation -Site $createdSite -HubSite "$($spoUrl)$($SPOTemplateConfigStructure.ConnectedHubsite.TrimStart('/'))" -Connection $global:SPOAdminConnection
        }
          
        Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
      }
      catch {
        Write-Host " ✘ failed: $($_)" -ForegroundColor Red
      }
    }

    # connect to new site and return connection for further purpose
    return (Connect-PnPOnline -Url $createdSite -ReturnConnection -Interactive)
  }

  Function Set-HomepageLayout([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [Object[]]$SPOStructureSiteTemplateConfig) {
    try {
      Write-Host "⎿ Setting homepage layout to <$($SPOStructureSiteTemplateConfig.HomepageLayout)>: " -NoNewline
      $homepageRefUrl = Get-PnPHomePage -Connection $siteConnection
      $homepage = Get-PnPPage -Identity $homepageRefUrl.Split("/")[-1] -Connection $siteConnection

      if ("Article" -eq $SPOStructureSiteTemplateConfig.HomepageLayout -or
        "Home" -eq $SPOStructureSiteTemplateConfig.HomepageLayout -or
        "SingleWebPartAppPage" -eq $SPOStructureSiteTemplateConfig.HomepageLayout) {
        $null = Set-PnPPage -Identity $homepage -LayoutType $SPOStructureSiteTemplateConfig.HomepageLayout -Connection $siteConnection
      }
      else {
        throw "Homepage layout <$($SPOStructureSiteTemplateConfig.HomepageLayout)> does not exist."
      }
      
      Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ✘ failed: $($_)" -ForegroundColor Red      
    }
  }

  Function Add-SiteContentOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [Object[]]$SPOTemplateContentConfig) {
    foreach ($siteContent in $SPOTemplateContentConfig) {
      # Create libraries
      try {
        $type = Get-SiteContentType -SiteContent $siteContent
        if ($type -eq "Other") { throw "Library Type does not exist." }
        $title = $siteContent[$type]
        
        Write-Host "⎿ Creating content: <$($type)> '$($title)'" -NoNewline
        $quickLaunch = $siteContent.OnQuickLaunch -and $siteContent.OnQuickLaunch -eq $true ? $true : $false

        $objectUrl = ConvertTo-PascalCase $title
        switch ($type) {
          "DocumentLibrary" { $list = New-PnPList -Template DocumentLibrary -Url $objectUrl -Title $title -OnQuickLaunch:$quickLaunch -Connection $siteConnection }
          "MediaLibrary" {
            # This is a special media library by this provisioning engine 😍 
            Enable-PnPFeature -Identity 6e1e5426-2ebd-4871-8027-c5ca86371ead -Scope Site -Force -Connection $siteConnection # VideoAndRichMedia
            Enable-PnPFeature -Identity 4bcccd62-dcaf-46dc-a7d4-e38277ef33f4 -Scope Site -Force -Connection $siteConnection # Asset Library
            Enable-PnPFeature -Identity 3bae86a2-776d-499d-9db8-fa4cdc7884f8 -Scope Site -Force -Connection $siteConnection # Document Set
            
            $list = New-PnPList -Template DocumentLibrary -Url $objectUrl -Title $title -OnQuickLaunch:$quickLaunch -Connection $siteConnection 
            Add-PnPContentTypeToList -List $list -ContentType 0x0101009148F5A04DDD49CBA7127AADA5FB792B -DefaultContentType -Connection $siteConnection 
            Add-PnPContentTypeToList -List $list -ContentType 0x0101009148F5A04DDD49CBA7127AADA5FB792B00291D173ECE694D56B19D111489C4369D -Connection $siteConnection 
            Add-PnPContentTypeToList -List $list -ContentType 0x0101009148F5A04DDD49CBA7127AADA5FB792B00AADE34325A8B49CDA8BB4DB53328F214 -Connection $siteConnection
          }
          "List" { $list = New-PnPList -Template GenericList -Url $objectUrl -Title $title -OnQuickLaunch:$quickLaunch -Connection $siteConnection }
          "EventsList" { $list = New-PnPList -Template Events -Url $objectUrl -Title $title -OnQuickLaunch:$quickLaunch -Connection $siteConnection }
          Default {}
        }
        
        Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
      }
      catch {
        Write-Host " ✘ failed: $($_)" -ForegroundColor Red
      }

      # Create folder structure (if defined)
      try {
        if ($type -in @("DocumentLibrary", "MediaLibrary") -and $siteContent.Folders) { 
          Write-Host "⎿ Creating folder structure:" -NoNewline
          Add-FoldersToList -siteConnection $siteConnection -ContentDoclibFolders $siteContent.Folders `
            -parentPath "$objectUrl"
          Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
        } 
      }
      catch {
        Write-Host " ✘ failed: $($_)" -ForegroundColor Red
      }

      # Apply provisioning template on list
      try {
        if ($siteContent.'Provisioning Template') {
          $provisioningParameters = $siteContent['Provisioning Parameters']
          $provisioningParameters.Title = $title
          $provisioningParameters.Url = $objectUrl

          Invoke-PnPListTemplateOnTarget -listTemplatePath $siteContent.'Provisioning Template' -templateParameters $provisioningParameters `
            -siteConnection $siteConnection 
        }
      }
      catch {
        Write-Host " ✘ failed: $($_)" -ForegroundColor Red
      }
    }
  }

  Function Invoke-PnPSiteTemplateOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [string]$templatePath, [System.Collections.Hashtable]$templateParameters) {
    Write-Host "⎿ Invoking site template (PnP): '$($templatePath)' [started]"
    try {
      Invoke-PnPSiteTemplate -Path $templatePath -Parameters $templateParameters -Connection $siteConnection
      Write-Host " ✔︎ OK" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ✘ failed: $($_)" -ForegroundColor Red
    }
  }

  Function Invoke-PnPListTemplateOnTarget([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [string]$listTemplatePath, [System.Collections.Hashtable]$templateParameters) {
    try {
      # Read and modify the list template according to the list parameters (overwrite values from PnP template)
      $listTemplate = Read-PnPSiteTemplate -Path $listTemplatePath
      $listTemplate.Lists[0].Title = $templateParameters.Title
      $listTemplate.Lists[0].Url = $templateParameters.Url
      $listTemplate.Lists[0].DocumentTemplate = $listTemplate.Lists[0].DocumentTemplate -replace "\/(\w*)\/", "/$($templateParameters.Url)/"
      $listTemplate.Lists[0].DefaultDisplayFormUrl = $listTemplate.Lists[0].DefaultDisplayFormUrl -replace "\/(\w*)\/", "/$($templateParameters.Url)/"
      $listTemplate.Lists[0].DefaultEditFormUrl = $listTemplate.Lists[0].DefaultEditFormUrl -replace "\/(\w*)\/", "/$($templateParameters.Url)/"
      $listTemplate.Lists[0].DefaultNewFormUrl = $listTemplate.Lists[0].DefaultNewFormUrl -replace "\/(\w*)\/", "/$($templateParameters.Url)/"
      $listTemplate.Lists[0].Views | ForEach-Object { 
        $_.SchemaXml = $_.SchemaXml -replace 'Url="{site}\/(\w*)\/', "Url=""{site}/$($templateParameters.Url)/"
      }
      # Invoke the template
      Write-Host "⎿ Invoking list template (PnP): '$($listTemplatePath)' [started]"
      Invoke-PnPSiteTemplate -InputInstance $listTemplate -Handlers Lists -Parameters $templateParameters -Connection $siteConnection
      Write-Host " ✔︎ OK" -ForegroundColor DarkGreen
    }
    catch {
      Write-Host " ✘ failed: $($_)" -ForegroundColor Red
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
    if ($siteStructure.HomepageLayout) {
      Set-HomepageLayout -siteConnection $newSiteConnection -SPOStructureSiteTemplateConfig $siteStructure
    }
    
    Add-SiteContentOnTarget -siteConnection $newSiteConnection -SPOTemplateContentConfig $siteStructure.Content -ErrorAction SilentlyContinue
    if ($siteStructure.'Provisioning Template') {
      Invoke-PnPSiteTemplateOnTarget -templatePath $siteStructure.'Provisioning Template' -templateParameters $siteStructure.'Provisioning Parameters'`
        -siteConnection $newSiteConnection 
    }
    
    if ($siteStructure.CopyHubNavigation) {
      Copy-Hubnavigation -SPOStructureSiteTemplateConfig $siteStructure -SPOBaseUrl $spoUrl
    }
  }

  if (-not $KeepConnectionsAlive) {
    Disconnect-SPOAdminUrl
  }
}
