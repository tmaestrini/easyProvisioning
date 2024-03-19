Function Add-FoldersToList([PnP.PowerShell.Commands.Base.PnPConnection]$siteConnection, [Object[]]$ContentDoclibFolders, [string]$parentPath, [switch]$WhatIf) {
  foreach ($folder in $ContentDoclibFolders) {
    try {
      # 👇 leaf with subfolder structure
      if ($folder -is [System.Collections.Hashtable]) {
        if ($WhatIf.IsPresent) { Write-Host "`n$parentPath/$($folder.Keys)" -NoNewline }
        else { $f = Add-PnPFolder -Name $folder.Keys -Folder $parentPath -Connection $siteConnection -ErrorAction SilentlyContinue }
        Add-FoldersToList -ContentDoclibFolders $folder.values -parentPath "$parentPath/$($folder.Keys)" `
          -siteConnection $siteConnection -WhatIf:$WhatIf 
      }
      # 👇 Simple leaf with no subfolders
      elseif ($folder -is [string]) {
        if ($WhatIf.IsPresent) { Write-Host "`n$parentPath/$folder" -NoNewline }
        else { $f = Add-PnPFolder -Name $folder -Folder $parentPath -Connection $siteConnection -ErrorAction SilentlyContinue }
      }
      # 👇 subfolder structure
      elseif ($folder -is [System.Collections.IList]) {
        foreach ($item in $folder) {
          # contains more folders
          if ($item.Values) { 
            if ($WhatIf.IsPresent) { Write-Host "`n$parentPath/$($item.Keys)" -NoNewline}
            else { $f = Add-PnPFolder -Name $item.Keys -Folder $parentPath -Connection $siteConnection -ErrorAction SilentlyContinue }
            Add-FoldersToList -ContentDoclibFolders $item.Values -parentPath "$parentPath/$($item.Keys)" `
              -siteConnection $siteConnection -WhatIf:$WhatIf
          }
          # 👇 simple leaf with no subfolders
          else {
            if ($WhatIf.IsPresent) { Write-Host "`n$parentPath/$($item)" -NoNewline }
            else { $f = Add-PnPFolder -Name $item -Folder $parentPath -Connection $siteConnection -ErrorAction SilentlyContinue }
          }
        }
      }
    }
    catch {
      throw $_
    }
  }
}
