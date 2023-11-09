Function Sync-Hubnavigation {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName
  )

  try {
    $template = Get-Template -TemplateName $TemplateName
    $spoBaseUrl = [System.UriBuilder]::new("https", "$($template.SharePoint.TenantId).sharepoint.com")

    Clear-Host
    Write-Host "Starting sync of hub navigation"
    foreach ($siteStructure in $template.SharePoint.Structure) {
      if ($null -ne $siteStructure.Values.CopyHubNavigation) {
        Write-Host "⭐️ Site '$($siteStructure.Values.Url)'"
        Copy-Hubnavigation -SPOStructureSiteTemplateConfig $siteStructure -SPOBaseUrl $spoBaseUrl
      }
    }
  }
  catch {
    $_
  }
}