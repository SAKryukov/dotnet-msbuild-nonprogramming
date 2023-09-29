$DirPath = "."
 get-childitem $DirPath -recurse -include *.sample |
ForEach-Object {
 (Get-Content $_).replace("<","&lt;").replace(">","&gt;") |
 Set-Content $_
 }