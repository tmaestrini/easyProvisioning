Function Assert([bool]$valueToTest, [string]$errorMessage) {
  if ($valueToTest -eq $false) {
    Write-Warning -Message $errorMessage
    Exit 1
  }
}

Function Ensure-Modules() {
  Assert ($null -ne (Get-InstalledModule -Name PnP.Powershell -RequiredVersion 2.2.5 -ErrorAction SilentlyContinue)) "Module 'PnP.Powershell' in version 2.2.0 missing – Please install module first"
  Assert ($null -ne (Get-InstalledModule -Name powershell-yaml -ErrorAction SilentlyContinue)) "Module 'PnP.Powershell' in version 2.2.0 missing – Please install module first"
}