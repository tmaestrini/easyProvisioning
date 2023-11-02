Function Start-Provisioning {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName,
    [Parameter(
      Mandatory = $false
    )][switch]$KeepConnectionsAlive
  )

  try {
    $template = Get-Template -TemplateName $TemplateName
    Add-SPOStructure -SPOTemplateConfig $template.SharePoint -KeepConnectionsAlive:$KeepConnectionsAlive
  }
  catch {
    $_
  }
}