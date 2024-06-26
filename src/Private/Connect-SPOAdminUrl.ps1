Function Connect-SPOAdminUrl {
  param(
    [Parameter(Mandatory = $true)][string]$Url
  )

  if ($global:SPOAdminConnection) { return }
  
  Write-Host "Please log into SPO Admin Center with credentials <$($SPOTemplateConfig.AdminUPN)>. Press <ENTER> to proceed..." -NoNewline
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  
  Connect-PnPOnline -Url $Url -Interactive # add this to suppress the always opening authentication prompt
  $global:SPOAdminConnection = Connect-PnPOnline -Url $Url -Interactive -ReturnConnection
  if ($null -eq $global:SPOAdminConnection) { throw "✘ failed!" }
  Write-Host " ✔︎ OK" -ForegroundColor DarkGreen
}
