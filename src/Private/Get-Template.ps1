Function Get-Template {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName
  )

  $MainConfig = @{ }

  # Merge contained templates into main config
  function Merge-ContainedTemplates {
    [cmdletbinding()]
    param(
      [Parameter(
        Mandatory = $true,
        HelpMessage = "The main data (config based on the main configuration file)"
      )][hashtable]$Config
    )
      
    if ($Config.ContainsKey("Contains") -and ($Config.Contains -is [System.Collections.IList])) {
      foreach ($ContainedPath in $Config.Contains) {
        $Content = (Get-Content -Path $ContainedPath) -join "`n"
        $ContainedConfig = ConvertFrom-Yaml $Content
  
        # SharePoint
        if ($MainConfig.SharePoint.TenantId -eq $ContainedConfig.SharePoint.TenantId) {
          foreach ($element in $ContainedConfig.SharePoint.Structure) {
            $MainConfig.SharePoint.Structure.Add($element)
          }
        }

        Merge-ContainedTemplates -Config $ContainedConfig
      }
    }
  }

  # Starting point
  $ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ../../tenants/$TemplateName
  if (-not(Test-Path -Path $ConfigPath -PathType Leaf)) {
    Write-Error "No template found for '$Tenant'" -ErrorAction Stop
  }

  $Content = (Get-Content -Path $ConfigPath) -join "`n"
  $MainConfig = ConvertFrom-Yaml $Content
  
  Merge-ContainedTemplates -Config $MainConfig
  return $MainConfig
}
