function New-MermaidSitemap {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "The template (acts as sitemap source)"
    )][hashtable]$Template  
  )
  
  # Create sites and content
  $sitemapContent = @()
  $sitemapRelations = @()

  foreach ($siteStructure in $Template.SharePoint.Structure) {
    # handle site header in new node
    $node = $siteStructure.values.Type -eq 'Communication' ? "$($siteStructure.values.Url)(""%header%""):::CommSite" 
    : $siteStructure.values.Type -eq 'Team' ? "$($siteStructure.values.Url)[""%header%""]:::TeamSite" 
    : "$($siteStructure.values.Url)[""%header%""]:::SPOTeamSite"
    $node = $siteStructure.values.IsHub -eq $true ? $node.Replace('%header%', '☆ %header%') : $node
    $node = $node.Replace('%header%', "<strong>$($siteStructure.keys)</strong><br/><hr/>%url%")
    $node = $node.Replace('%url%', "<small>▷$($siteStructure.values.Url)</small><div style='font-size: 0.8em;display:flex;flex-direction:column;line-height:1em'>%content%</div>")
    
    # handle site content
    foreach ($siteContent in $siteStructure.values.Content) {
      $node = $node.Replace('%content%', "<div style='position: relative;left: 2px;border-left: 0.5px solid black;padding: 0.5em 0 0 0;'>– $($siteContent.values.Title) <br/>   <span style='font-size:0.8em'>$($siteContent.keys)</span> </div>%content%")    
    }
    
    $node = $node.Replace('%content%', "") 
    
    # node is ready – add it to site map
    $spacing = ($sitemapContent.Length -eq 0) ? "" : "`n    "
    $sitemapContent += "$spacing$node"
    
    if ($siteStructure.values.ConnectedHubsite) {
      $spacing = ($sitemapRelations.Length -eq 0) ? "" : "`n    "
      $sitemapRelations += "$spacing$($siteStructure.values.ConnectedHubsite) --> $($siteStructure.values.Url)"
    }
  }
    
  # Prepare output and populate template
  $Binding = @{
    sitemapContent   = $sitemapContent
    sitemapRelations = $sitemapRelations
  }

  $sitemapDirectory = Join-Path -Path $PSScriptRoot -ChildPath ../../templates
  $sitemapPath = Join-Path -Path $sitemapDirectory -ChildPath "$($TemplateName -replace '(^.*)(\.yml)', '$1.sitemap.mmd')"

  $sitemapTemplatePath = Join-Path -Path $PSScriptRoot -ChildPath ../../artifacts/sitemapTemplate.eps -Resolve
  $sitemapConfig = Invoke-EpsTemplate -Path $sitemapTemplatePath -Binding $Binding
  $sitemapConfig | Out-File -FilePath $sitemapPath -NoNewline
}