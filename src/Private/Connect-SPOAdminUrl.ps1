Function Connect-SPOAdminUrl {
  param(
    [Parameter(Mandatory = $true)][string]$Url
  )

  if ($global:SPOAdminConnection) { return }
  
  Write-Host "Please log into SPO Admin Center with credentials <$($SPOTemplateConfig.AdminUPN)>. Press <ENTER> to proceed..." -NoNewline
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
  $global:SPOAdminConnection = Connect-PnPOnline -Url $SPOTemplateConfig.AdminUrl -Interactive -ReturnConnection
  if ($null -eq $global:AdminConnection) { throw "❌ failed!" }
  Write-Host " ✔︎ OK" -ForegroundColor DarkGreen
}
