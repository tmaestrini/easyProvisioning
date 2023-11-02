Function Disconnect-SPOAdminUrl {

  if ($global:SPOAdminConnection) { $global:SPOAdminConnection = $null }
  Write-Host "Disconnected from SharePoint"
}
