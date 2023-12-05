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
  $sitemapHubsites = @()

  foreach ($siteStructure in $template.SharePoint.Structure) {
    $node = $siteStructure.values.Type -eq 'Communication' ? "$($siteStructure.values.Url)(""%content%""):::CommSite" : $siteStructure.values.Type -eq 'Team' ? "$($siteStructure.values.Url)[""%content%""]:::TeamSite" : "$($siteStructure.values.Url)[""%content%""]:::SPOTeamSite"
    # $node = $siteStructure.values.IsHub -eq $true ? $node.Replace('%content%', 'fa:fa-home %content%') : $node
    $node = $siteStructure.values.IsHub -eq $true ? $node.Replace('%content%', '☆ %content%') : $node
    $node = $node.Replace('%content%', "<strong>$($siteStructure.keys)</strong><br/><hr/><small>▷$($siteStructure.values.Url)</small><div style='font-size: 0.8em;display:flex;flex-direction:column;line-height:1em'>%content%</div>")
    
    # handle site content
    foreach ($siteContent in $siteStructure.values.Content) {
      $node = $node.Replace('%content%', "<div style='position: relative;left: 2px;border-left: 0.5px solid black;padding: 0.5em 0 0 0;'>– $($siteContent.values.Title) <br/>   <span style='font-size:0.8em'>$($siteContent.keys)</span> </div>%content%")    
    }
    
    $node = $node.Replace('%content%', "")    
    
    # node is ready – add it to site map
    $sitemapContent += "$node`n"
    
    if ($siteStructure.values.ConnectedHubsite) {
      # $sitemapContent += "$($siteStructure.values.ConnectedHubsite)[[fa:fa-home $($siteStructure.values.ConnectedHubsite)]]`n"
      $sitemapRelations += "$($siteStructure.values.ConnectedHubsite) --> $($siteStructure.values.Url)`n"
    }
  }
    
  # Prepare output and populate template
  $Binding = @{
    sitemapContent   = $sitemapContent
    sitemapRelations = $sitemapRelations
  }

  $sitemapDirectory = Join-Path -Path $PSScriptRoot -ChildPath ../../templates
  $sitemapPath = Join-Path -Path $sitemapDirectory -ChildPath "$($TemplateName).sitemap"

  $sitemapTemplatePath = Join-Path -Path $PSScriptRoot -ChildPath ../../artifacts/sitemapTemplate.eps -Resolve
  $sitemapConfig = Invoke-EpsTemplate -Path $sitemapTemplatePath -Binding $Binding
  $sitemapConfig | Out-File -FilePath $sitemapPath -NoNewline
}