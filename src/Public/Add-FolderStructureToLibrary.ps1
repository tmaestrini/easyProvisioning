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
    foreach ($siteStructure in $template.SharePoint.Structure) {
      foreach ($siteContent in $siteStructure.Content) {
        if ($null -ne $siteContent.Folders) {
          $type = $SPOTemplateConfigStructure.Hub ? "Hub" : $SPOTemplateConfigStructure.Site ? "Site" : $null
          if ($null -eq $type) { throw "No or wrong site type provided" }
  
          $title = $SPOTemplateConfigStructure[$type]
          $isHub = $type -eq "Hub"
      
          Write-Host "⭐️ $($siteContent.Values.Title) – creating folder structure:" -NoNewline
          $objectUrl = ConvertTo-PascalCase $siteContent.values.Title
          Add-FoldersToList -ContentDoclibFolders $siteContent.values.Folders `
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