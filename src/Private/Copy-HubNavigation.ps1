Function Copy-Hubnavigation {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true
    )][hashtable]$SPOStructureSiteTemplateConfig,
    [Parameter(
      Mandatory = $true
    )][string]$SPOBaseUrl
  )

  Function Get-ToplevelHubnavigation([PnP.PowerShell.Commands.Base.PnPConnection]$sourceSiteConn) {
    try {
      $hubsiteNavigation = Get-PnPNavigationNode -Location TopNavigationBar -Connection $sourceSiteConn
      return $hubsiteNavigation
    }
    catch {
      Write-Host " ✘ failed: $($_)" -ForegroundColor Red
    }
  }

  Function New-HubnavigationElement([Object]$naviItem, [Object]$parentItem, [PnP.PowerShell.Commands.Base.PnPConnection]$destSiteConn, [PnP.PowerShell.Commands.Base.PnPConnection]$sourceSiteConn) {
    # construct path based on given relative url of item
    $naviItem.Url = $naviItem.Url -eq "http://linkless.header/" ? "http://linkless.header/" : ($naviItem.Url.StartsWith("https://") ? $naviItem.Url : "$($naviItem.Context.Url)$($naviItem.Url.TrimStart('/'))")
    if ($null -ne $parentItem) {
      $node = Add-PnPNavigationNode -Location TopNavigationBar -Title $naviItem.Title -Url $naviItem.Url -Parent $parentItem.Id -Connection $destSiteConn
    }
    else { 
      $node = Add-PnPNavigationNode -Location TopNavigationBar -Title $naviItem.Title -Url $naviItem.Url -Connection $destSiteConn 
    }

    # handle child nodes (recursively)
    if ($null -ne $naviItem.Children) {
      foreach ($childNaviItem in $naviItem.Children) {
        # get the details about the node:
        $childNaviItem = Get-PnPNavigationNode -Id $childNaviItem.Id -Connection $connHubsiteSource
        New-HubnavigationElement -naviItem $childNaviItem -parentItem $node -destSiteConn $destSiteConn
      }
    }     
  }

  if ($null -eq $SPOStructureSiteTemplateConfig.CopyHubNavigation) { throw "No Source Hubsite Url provided" }
  if ($null -eq $SPOStructureSiteTemplateConfig.Url) { throw "No Destination Hubsite Url provided" }
  
  $spoUrlSource = "$($SPOBaseUrl)$($SPOStructureSiteTemplateConfig.CopyHubNavigation)"
  $spoUrlDestination = "$($SPOBaseUrl)$($SPOStructureSiteTemplateConfig.Url)"

  $connHubsiteSource = Connect-PnPOnline -Url $spoUrlSource -ReturnConnection -Interactive
  $connHubSiteDest = Connect-PnPOnline -Url $spoUrlDestination -Interactive -ReturnConnection

  try {
    # Delete all existing nodes:
    Remove-PnPNavigationNode -Force -All -Connection $connHubSiteDest

    Write-Host "⎿  Copying consistent hub navigation from '$($connHubsiteSource.Url)': " -NoNewline
    $navigation = Get-ToplevelHubnavigation -sourceSiteConn $connHubsiteSource
    foreach ($naviItem in $navigation) {
      # get the details about the node:
      $naviItem = Get-PnPNavigationNode -Id $naviItem.Id -Connection $connHubsiteSource 
      New-HubnavigationElement -naviItem $naviItem -parentItem $null -destSiteConn $connHubSiteDest -sourceSiteConn $connHubsiteSource
    }
    Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
  }
  catch {
    Write-Host " ✘ failed: $($_)" -ForegroundColor Red
  }

}