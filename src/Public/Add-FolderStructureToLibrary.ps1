function Add-FolderStructureToLibrary {
  [cmdletbinding()]
  param(
    [Parameter(
      Mandatory = $true,
      HelpMessage = "Full name of the template, including .yml (aka <name>.yml)"
    )][string]$TemplateName,
    [Parameter(
      HelpMessage = "The connection to the site where the folders should be created"
    )][PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection,
    [Parameter(
      HelpMessage = "Simulates the creation of folder path without actually creating them"
    )][switch]$WhatIf
  )

  $template = Get-Template -TemplateName $TemplateName
  if ($null -eq $template.SharePoint.TenantId) { throw "No SharePoint tenant id provided" }
  if ($null -eq $template.SharePoint.Structure) { throw "No SharePoint Structure provided" }

  try {
    $filteredSitesFromStructure = $template.SharePoint.Structure |? { $siteConnection.Url -like "*$($_.Url)" }
    foreach ($siteStructure in $filteredSitesFromStructure) {
      $type = $siteStructure.Hub ? "Hub" : $siteStructure.Site ? "Site" : $null
      if ($null -eq $type) { throw "No or wrong site type provided" }
      
      $siteTitle = $siteStructure[$type]
      foreach ($siteContent in $siteStructure.Content) {
        $type = Get-SiteContentType -SiteContent $siteContent
        if ($type -eq "Other") { throw "Library Type does not exist." }
        $title = $siteContent[$type]

        if ($type -in @("DocumentLibrary", "MediaLibrary") -and $siteContent.Folders) { 
        # if ($null -ne $siteContent.Folders) {    
          Write-Host "⭐️ $($siteTitle) – creating folder structure in $($title):" -NoNewline
          $objectUrl = ConvertTo-PascalCase $title
          Add-FoldersToList -ContentDoclibFolders $siteContent.Folders `
            -parentPath "$objectUrl" -siteConnection $siteConnection -WhatIf:$WhatIf
          Write-Host " ✔︎ Done" -ForegroundColor DarkGreen
        }
      }
    }
  }
  catch {
    $_
  }
}