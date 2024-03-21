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
    $siteType = $siteStructure.Hub ? "Hub" : $siteStructure.Site ? "Site" : $null
    if ($null -eq $siteType) { throw "No or wrong site type provided" }

    $title = $siteStructure[$siteType]
    $isHub = $siteType -eq "Hub"

    # handle site header in new node
    $node = $siteStructure.Type -eq 'Communication' ? "$($siteStructure.Url)(""%header%""):::CommSite" 
    : $siteStructure.Type -eq 'Team' ? "$($siteStructure.Url)[""%header%""]:::TeamSite" 
    : "$($siteStructure.Url)[""%header%""]:::SPOTeamSite"
    $node = $isHub -eq $true ? $node.Replace('%header%', '☆ %header%') : $node
    $node = $node.Replace('%header%', "<strong>$($title)</strong><br/><hr/>%url%")
    $node = $node.Replace('%url%', "<small>▷$($siteStructure.Url)</small><div style='font-size: 0.8em;display:flex;flex-direction:column;line-height:1em'>%content%</div>")
    
    # handle site content
    foreach ($siteContent in $siteStructure.Content) {
      $type = Get-SiteContentType -SiteContent $siteContent
      if ($type -eq "Other") { throw "Library type does not exist." }
      $contentTitle = $siteContent[$type]

      $node = $node.Replace('%content%', "<div style='position: relative;left: 2px;border-left: 0.5px solid black;padding: 0.5em 0 0 0;'>– $($contentTitle) <br/>   <span style='font-size:0.8em'>$($siteContent.keys)</span> </div>%content%")    
    }
    
    $node = $node.Replace('%content%', "") 
    
    # node is ready – add it to site map
    $spacing = ($sitemapContent.Length -eq 0) ? "" : "`n    "
    $sitemapContent += "$spacing$node"
    
    if ($siteStructure.ConnectedHubsite) {
      $spacing = ($sitemapRelations.Length -eq 0) ? "" : "`n    "
      $sitemapRelations += "$spacing$($siteStructure.ConnectedHubsite) --> $($siteStructure.Url)"
    }
  }
    
  # Prepare output and populate template
  $Binding = @{
    sitemapContent   = $sitemapContent
    sitemapRelations = $sitemapRelations
  }

  $sitemapDirectory = Join-Path -Path $PSScriptRoot -ChildPath ../../tenants
  $sitemapPath = Join-Path -Path $sitemapDirectory -ChildPath "$($TemplateName -replace '(^.*)(\.yml)', '$1.sitemap.mmd')"

  $sitemapTemplatePath = Join-Path -Path $PSScriptRoot -ChildPath ../../assets/sitemapTemplate.eps -Resolve
  $sitemapConfig = Invoke-EpsTemplate -Path $sitemapTemplatePath -Binding $Binding
  $sitemapConfig | Out-File -FilePath $sitemapPath -NoNewline
}