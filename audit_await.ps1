$base = "c:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\AethelgardPrototype\scripts"
$outFile = "c:\Users\BHASKAR BAHUKHANDI\OneDrive\Desktop\Ultimate project\audit_results.txt"
$files = Get-ChildItem -Path $base -Recurse -Filter "*.gd"
$output = @()

foreach ($f in $files) {
    $content = Get-Content $f.FullName
    $bad = @()
    $total_awaits = 0
    for ($i = 0; $i -lt $content.Count; $i++) {
        # Match: await get_tree(), await tween.finished, await *.finished, await create_tween
        if ($content[$i] -match 'await\s+(get_tree\(\)|.*\.finished|.*create_tween)') {
            $total_awaits++
            
            # Skip if this is a multi-line await (continuation line with just .timeout or similar)
            $line = $content[$i].Trim()
            
            # Check if next 1-4 non-empty lines contain is_inside_tree guard
            $ok = $false
            for ($j = $i+1; $j -lt [Math]::Min($i+5,$content.Count); $j++) {
                $n = $content[$j].Trim()
                if ($n -eq '') { continue }
                # Also allow multi-line await continuations like ).timeout
                if ($n -match '^\)\.timeout' -or $n -match '^\)\.finished') { continue }
                if ($n -match 'is_inside_tree|is_instance_valid') { $ok = $true }
                break
            }
            if (-not $ok) { $bad += "$($i+1):$line" }
        }
    }
    if ($bad.Count -gt 0) {
        $rp = $f.Name
        $rel = $f.FullName.Substring($base.Length + 1)
        $output += "FILE: $rel"
        $output += "  UNGUARDED: $($bad.Count) / TOTAL AWAIT: $total_awaits"
        foreach ($b in $bad) {
            $output += "    $b"
        }
        $output += ""
    }
}

$output | Out-File -FilePath $outFile -Encoding utf8
Write-Output "Done"
