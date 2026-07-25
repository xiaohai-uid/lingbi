$destDir = "C:\Users\a1691\Documents\Obsidian Vault\AI" + [char]0x8F6F + [char]0x4EF6 + [char]0x5DE5 + [char]0x7A0B + [char]0x7CFB + [char]0x7EDF
$files = Get-ChildItem $destDir
foreach ($f in $files) {
    Write-Output "$($f.Name) ($($f.Length) bytes)"
}
$destFile = Join-Path $destDir $files[0].Name
$content = [System.IO.File]::ReadAllText($destFile, [System.Text.Encoding]::UTF8)
Write-Output "---First 300 chars---"
Write-Output $content.Substring(0, [Math]::Min(300, $content.Length))
Write-Output "---Last 100 chars---"
Write-Output $content.Substring([Math]::Max(0, $content.Length - 100))
