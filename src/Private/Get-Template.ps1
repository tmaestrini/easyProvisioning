Function Get-Template {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName
  )

  # Merge contained templates into main config
  function Merge-ContainedTemplates {
    [cmdletbinding()]
    param(
      [Parameter(
        Mandatory = $true,
        HelpMessage = "The main data (config based on the main configuration file)"
      )][hashtable]$Config
    )
  
    if ($Config.ContainsKey("Contains")) {
      $Content = (Get-Content -Path $Config.Contains) -join "`n"
      $ContainedConfig = ConvertFrom-Yaml $Content
  
      # SharePoint
      if ($Config.SharePoint.TenantId -eq $ContainedConfig.SharePoint.TenantId) {
        foreach ($element in $ContainedConfig.SharePoint.Structure) {
          $Config.SharePoint.Structure.Add($element)
        }
      }
    }
  }

  # Starting point
  $ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ../../tenants/$TemplateName
  if (-not(Test-Path -Path $ConfigPath -PathType Leaf)) {
    Write-Error "No template found for '$Tenant'" -ErrorAction Stop
  }

  $Content = (Get-Content -Path $ConfigPath) -join "`n"
  $Config = ConvertFrom-Yaml $Content
  
  Merge-ContainedTemplates -Config $Config
  return $Config
}
