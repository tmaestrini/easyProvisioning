Function Test-Template {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName  
  )

  try {
    $template = Get-Template -TemplateName $TemplateName
    $standardPrefs = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    Assert ($null -ne $template.Tenant) "Missing tenant configuration. Please check template configuration file"
    Assert ($null -ne $template.SharePoint) "Missing SharePoint configuration. Please check template configuration file"
    Assert ($null -ne $template.SharePoint.TenantId) "Missing SharePoint tenant identifier in configuration. Please check template configuration file"
    Assert ($null -ne $template.SharePoint.AdminUpn) "Missing UPN for admin account in configuration. Please check template configuration file"
    Assert ($null -ne [mailaddress]$template.SharePoint.AdminUpn) "admin account is not UPN. Please check template configuration file"
    
    foreach ($siteStructure in $template.Structure) {
      $siteName = $siteStructure.keys
      Assert ($null -ne $siteStructure.values.Url) "Missing URL for site structure '$($siteName)'. Please check template configuration file"
      Assert ($null -ne $siteStructure.values.Type) "Missing type for site structure '$($siteName)'. Please check template configuration file"
      Assert ($null -ne $siteStructure.values.Template) "Missing template definition for site structure '$($siteName)'. Please check template configuration file"
    }

    $ErrorActionPreference = $standardPrefs;
  }
  catch {
    $_
  }
}