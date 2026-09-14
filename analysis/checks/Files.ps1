param([string]$ArchiveRoot = (Join-Path $PSScriptRoot '../..'))
$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $ArchiveRoot).Path.TrimEnd('\','/')
$rows = Import-Csv -LiteralPath (Join-Path $resolvedRoot 'analysis/checks/Files.csv')
$failures = [System.Collections.Generic.List[string]]::new()
foreach ($row in $rows) {
    $target = [IO.Path]::GetFullPath((Join-Path $resolvedRoot $row.Path))
    if (-not $target.StartsWith($resolvedRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path outside archive: $($row.Path)"
    }
    if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
        $failures.Add('MISSING: ' + $row.Path)
        continue
    }
    if ((Get-Item -LiteralPath $target).Length -ne [long]$row.Size_bytes) { $failures.Add('SIZE: ' + $row.Path) }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $row.SHA256) {
        $failures.Add('HASH: ' + $row.Path)
    }
}
if ($failures.Count) { $failures | Write-Output; throw 'File verification failed' }
Write-Output ('PASS: ' + $rows.Count + ' packaged files match SHA-256 manifest. This is not a model rerun.')
