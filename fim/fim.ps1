Function Calculate-File-Checksum($filepath) {
    $filechecksum = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filechecksum
}
Function Remove-Existing-Baseline() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        # if pre exist, then delete
        Remove-Item -Path .\baseline.txt
    }
}


Write-Host ""
Write-Host "What would you like to do?"
Write-Host ""
Write-Host "A) Collect new Baseline?"
Write-Host "B) Start monitoring files ?"
Write-Host ""
$response = Read-Host -Prompt "Please enter 'A' or 'B'"
Write-Host ""

if ($response -eq "A".ToUpper()) {
    Remove-Existing-Baseline
    #collect files
    $files = Get-ChildItem -Path .\Files
    # calculate the hash
    foreach ($f in $files) {
        $checksum = Calculate-File-Checksum $f.FullName
        "$($checksum.Path)|$($checksum.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
    
}

elseif ($response -eq "B".ToUpper()) {
    
    $fileChecksumDictionary = @{}
    $filePathsAndChecksums = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndChecksums) {
         $fileChecksumDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    while ($true) {
        Start-Sleep -Seconds 1   
        $files = Get-ChildItem -Path .\Files
        foreach ($f in $files) {
            $checksum = Calculate-File-Checksum $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
            if ($fileChecksumDictionary[$checksum.Path] -eq $null) {
                # new file 
                Write-Host "$($checksum.Path) has been created!" -ForegroundColor Green
            }
            else {

                # new file changed
                if ($fileChecksumDictionary[$checksum.Path] -eq $checksum.Hash) {
                    # file not changed
                }
                else {
                    # notify the user
                    Write-Host "$($checksum.Path) has changed!!!" -ForegroundColor Blue
                }
            }
        }

        foreach ($key in $fileChecksumDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
    }
}
