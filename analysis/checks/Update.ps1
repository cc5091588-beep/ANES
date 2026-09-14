# Maintainer only: review intentional changes before refreshing the manifest.
# By default, show a preview. -Write changes Files.csv and nothing else.
param(
    [string]$ArchiveRoot = (Join-Path $PSScriptRoot '../..'),
    [string[]]$AddPaths = @(),
    [switch]$Write
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $ArchiveRoot).Path.TrimEnd('\', '/')
$manifestPath = Join-Path $resolvedRoot 'analysis/checks/Files.csv'
$oldRows = @(Import-Csv -LiteralPath $manifestPath)
if ($oldRows.Count -eq 0) { throw 'The current manifest is empty.' }
if ((@($oldRows[0].PSObject.Properties.Name) -join ',') -ne 'Path,Size_bytes,SHA256') {
    throw 'Unexpected manifest columns.'
}

$paths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$oldByPath = @{}
foreach ($row in $oldRows) {
    if (-not $paths.Add($row.Path)) { throw ('Duplicate manifest path: ' + $row.Path) }
    if ($row.SHA256 -notmatch '^[0-9a-fA-F]{64}$' -or $row.Size_bytes -notmatch '^\d+$') {
        throw ('Invalid manifest record: ' + $row.Path)
    }
    $oldByPath[$row.Path] = $row
}
foreach ($path in $AddPaths) { [void]$paths.Add($path) }

$newRows = [System.Collections.Generic.List[object]]::new()
$changes = [System.Collections.Generic.List[object]]::new()
foreach ($path in ($paths | Sort-Object)) {
    if ([string]::IsNullOrWhiteSpace($path) -or $path.Contains('\') -or $path.Contains('//') -or
        [IO.Path]::IsPathRooted($path) -or $path -match '(^|/)\.\.?(/|$)' -or
        $path.Contains(':')) { throw ('Use a repository-relative path with forward slashes: ' + $path) }
    if ($path -ieq 'analysis/checks/Files.csv') { throw 'The manifest must not include itself.' }
    if ($path -match '(^|/)(\.git|\.Rproj\.user)(/|$)|(^|/)(\.Renviron|\.RData|\.Rhistory)$|^runs/|^analysis/renv/(library|cache|staging)/|^analysis/data/(raw|extracted|cleaned|analysis_ready)/|^analysis/config/anes_cdf_path\.txt$') {
        throw ('Private or generated local path is not allowed: ' + $path)
    }
    $target = [IO.Path]::GetFullPath((Join-Path $resolvedRoot $path))
    if (-not $target.StartsWith($resolvedRoot + [IO.Path]::DirectorySeparatorChar,
                               [StringComparison]::OrdinalIgnoreCase)) {
        throw ('Path outside repository: ' + $path)
    }
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        throw ('Listed file is missing; no manifest was written: ' + $path)
    }
    $cursor = Get-Item -LiteralPath $target -Force
    while ($cursor.FullName.TrimEnd('\', '/') -ne $resolvedRoot) {
        if ($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw ('Linked files or directories must not enter the manifest: ' + $path)
        }
        $cursor = Get-Item -LiteralPath (Split-Path -Parent $cursor.FullName) -Force
    }
    $new = [PSCustomObject]@{
        Path = $path
        Size_bytes = (Get-Item -LiteralPath $target -Force).Length
        SHA256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $newRows.Add($new)
    $old = $oldByPath[$path]
    if ($null -eq $old -or [long]$old.Size_bytes -ne $new.Size_bytes -or
        $old.SHA256 -ne $new.SHA256) {
        $changes.Add([PSCustomObject]@{
            Path = $path
            Change = $(if ($null -eq $old) { 'ADD' } else { 'UPDATE' })
            Old_bytes = $(if ($null -eq $old) { $null } else { $old.Size_bytes })
            New_bytes = $new.Size_bytes
            Old_SHA256 = $(if ($null -eq $old) { $null } else { $old.SHA256 })
            New_SHA256 = $new.SHA256
        })
    }
}

if ($changes.Count) { $changes | Format-List | Out-Host }
if (-not $Write) {
    Write-Output ('PREVIEW: ' + $changes.Count + ' changes; no files written. Use -Write only after review.')
    exit 0
}
if (-not $changes.Count) { Write-Output 'No manifest changes needed.'; exit 0 }
$csv = @($newRows | ConvertTo-Csv -NoTypeInformation)
[IO.File]::WriteAllText($manifestPath, (($csv -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
& (Join-Path $PSScriptRoot 'Files.ps1') -ArchiveRoot $resolvedRoot
Write-Output ('Updated Files.csv for ' + $newRows.Count + ' files. This is not a model rerun.')
