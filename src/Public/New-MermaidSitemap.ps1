function New-MermaidSitemap {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName
  )

  $template = Get-Template -TemplateName $TemplateName
  if ($null -eq $template.SharePoint.TenantId) { throw "No SharePoint tenant id provided" }
  if ($null -eq $template.SharePoint.Structure) { throw "No SharePoint Structure provided" }
  
  # Create sites and content
  $sitemapContent = @()
  $sitemapRelations = @()

  foreach ($siteStructure in $template.SharePoint.Structure) {
    $node = $siteStructure.values.Type -eq 'Communication' ? "$($siteStructure.keys)(%content%):::CommSite" : $siteStructure.values.Type -eq 'Team' ? "$($siteStructure.keys)[%content%]:::TeamSite" : "$($siteStructure.keys)>%content%]:::SPOTeamSite"
    $node = $siteStructure.values.IsHub -eq $true ? $node.Replace('%content%', 'fa:fa-home %content%') : $node
    $node = $node.Replace('%content%', "$($siteStructure.keys)<br/>$($siteStructure.values.Url)")
    $sitemapContent += "$node`n"
    
    if ($siteStructure.values.ConnectedHubsite) {
      $sitemapContent += "$($siteStructure.values.ConnectedHubsite)[[fa:fa-home $($siteStructure.values.ConnectedHubsite)]]`n"
      $sitemapRelations += "$($siteStructure.values.ConnectedHubsite) --> $($siteStructure.keys)`n"
    }
  }
    
  # Prepare output and populate template
  $Binding = @{
    sitemapContent    = $sitemapContent
    sitemapRelations = $sitemapRelations
  }

  $sitemapDirectory = Join-Path -Path $PSScriptRoot -ChildPath ../../templates
  $sitemapPath = Join-Path -Path $sitemapDirectory -ChildPath "$($TemplateName).sitemap"

  $sitemapTemplatePath = Join-Path -Path $PSScriptRoot -ChildPath ../../artifacts/sitemapTemplate.eps -Resolve
  $sitemapConfig = Invoke-EpsTemplate -Path $sitemapTemplatePath -Binding $Binding
  $sitemapConfig | Out-File -FilePath $sitemapPath -NoNewline
}