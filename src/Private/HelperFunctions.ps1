Function Assert([bool]$valueToTest, [string]$errorMessage) {
  if ($valueToTest -eq $false) {
    Write-Warning -Message $errorMessage
    Exit 1
  }
}

Function Ensure-Modules() {
  Assert ($null -ne (Get-InstalledModule -Name PnP.Powershell -RequiredVersion 2.2.5 -ErrorAction SilentlyContinue)) "Module 'PnP.Powershell' in version 2.2.0 missing – Please install module first"
  Assert ($null -ne (Get-InstalledModule -Name powershell-yaml -ErrorAction SilentlyContinue)) "Module 'PnP.Powershell' in version 2.2.0 missing – Please install module first"
}

Function ConvertTo-PascalCase([string] $text) {
  $replaceTable = @{"ß" = "ss"; "à" = "a"; "á" = "a"; "â" = "a"; "ã" = "a"; "ä" = "ae"; "å" = "a"; "æ" = "ae"; "ç" = "c"; "è" = "e"; "é" = "e"; "ê" = "e"; "ë" = "e"; "ì" = "i"; "í" = "i"; "î" = "i"; "ï" = "i"; "ð" = "d"; "ñ" = "n"; "ò" = "o"; "ó" = "o"; "ô" = "o"; "õ" = "o"; "ö" = "oe"; "ø" = "o"; "ù" = "u"; "ú" = "u"; "û" = "u"; "ü" = "ue"; "ý" = "y"; "þ" = "p"; "ÿ" = "y" }
  foreach ($key in $replaceTable.Keys) {
    $text = $text -Replace ($key, $replaceTable.$key)
  }
  $textOutput = $text -replace '[^0-9A-Za-z]', ' '
  return (Get-Culture).TextInfo.ToTitleCase($textOutput) -replace ' '
}