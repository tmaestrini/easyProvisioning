Import-Module .\src\Provisioning.psm1 -Force
$siteConn = Connect-PnPOnline "https://[tenantname].sharepoint.com/sites/[sitename]" -Interactive -ReturnConnection
Add-FolderStructureToLibrary -TemplateName "[tenantname].yml" -siteConnection $siteConn -WhatIf
