Function Get-Template {
  [cmdletbinding()]
  param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName
  )

  $ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ../../templates/$TemplateName
  if (-not(Test-Path -Path $ConfigPath -PathType Leaf)) {
    Write-Error "No template found for '$Tenant'" -ErrorAction Stop
  }

  $Content = (Get-Content -Path $ConfigPath) -join "`n"
  $Config = ConvertFrom-Yaml $Content
  return $Config
}
