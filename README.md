## Installation
```powershell
Install-Module -Name powershell-yaml, PnP.PowerShell -Scope CurrentUser
```


## Usage
```powershell
Import-Module .\src\Provisioning.psm1 -Force

Start-Provisioning -TemplateName "standard.yml"
```