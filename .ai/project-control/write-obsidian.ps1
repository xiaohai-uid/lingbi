$srcPath = "c:\codex\worktrees\lingbi-review-v1-mvr\.ai\project-control\v2-draft.md"
$destDir = "C:\Users\a1691\Documents\Obsidian Vault\AI" + [char]0x8F6F + [char]0x4EF6 + [char]0x5DE5 + [char]0x7A0B + [char]0x7CFB + [char]0x7EDF
$destFile = $destDir + "\00-AI" + [char]0x8F6F + [char]0x4EF6 + [char]0x9879 + [char]0x76EE + [char]0x603B + [char]0x63A7 + [char]0x63D0 + [char]0x793A + [char]0x8BCD + "-V2.0.md"

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$content = [System.IO.File]::ReadAllText($srcPath, [System.Text.Encoding]::UTF8)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($destFile, $content, $utf8NoBom)
Write-Output "Written to: $destFile"
Write-Output "File size: $((Get-Item $destFile).Length) bytes"
