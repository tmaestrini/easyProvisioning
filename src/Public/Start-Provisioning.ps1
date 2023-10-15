Function Start-Provisioning {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName  
  )

  try {
    $template = Get-Template -TemplateName $TemplateName
    Add-SPOStructure -SPOTemplateConfig $template.SharePoint
  }
  catch {
    $_
  }
}