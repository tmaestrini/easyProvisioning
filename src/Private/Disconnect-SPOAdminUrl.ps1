Function Disconnect-SPOAdminUrl {

  Write-Host "Disconnect from SharePoint" -NoNewline
  if ($global:SPOAdminConnection) { 
    Disconnect-PnPOnline
    $global:SPOAdminConnection = $null 
  }
  Write-Host " ✔ Done" -ForegroundColor DarkGreen
}
