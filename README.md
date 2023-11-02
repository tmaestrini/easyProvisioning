## Installation
```powershell
Install-Module -Name powershell-yaml, PnP.PowerShell -Scope CurrentUser
Install-Module -Name PnP.PowerShell -RequiredVersion 2.2.0 -Scope CurrentUser
```


## Usage
```powershell
Import-Module .\src\Provisioning.psm1 -Force
Start-Provisioning -TemplateName "standard.yml"

# To test your template, simply call
Test-Template -TemplateName "standard.yml"
```