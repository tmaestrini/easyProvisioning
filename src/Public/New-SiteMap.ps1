function New-Sitemap {

  [cmdletbinding()]
  param(
    [Parameter( Mandatory = $true, HelpMessage = "Full name of the template, including .yml (aka <name>.yml)")]
    [string]$TemplateName,
    [Parameter(Mandatory = $true)]
    [ValidateSet('Mermaid')] $Type
  )

  $template = Get-Template -TemplateName $TemplateName
  if ($null -eq $template.SharePoint.TenantId) { throw "No SharePoint tenant id provided" }
  if ($null -eq $template.SharePoint.Structure) { throw "No SharePoint Structure provided" }

  switch ($Type) {
    'Mermaid' { New-MermaidSitemap -Template $template }
    Default {}
  }
}