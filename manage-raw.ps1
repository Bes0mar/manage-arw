$raw_ext = "ARW" # RAW file type to process
$compressed_ext = "JPG" # compressed file type to match RAW files to
$nomatch = "Orphans" # folder name for RAW-files that do not have a match
$rawfolder = "$raw_ext" # name for folder to put RAW-files in

# check if there are any folders with raw-files
$folders = $(Get-ChildItem -Directory) | Where-Object { -not $($($(Get-ChildItem -File -Filter $_"/*.$raw_ext")).Count) -eq 0 }
# inform user if there are folders with unmoved raw-files
if ( $folders ) {
    Write-Host `n"The following folders contain $raw_ext files that have not been moved a $rawfolder folder" -ForegroundColor DarkYellow
    Write-Host `t$folders
    $answer = Read-Host "Move files to $rawfolder? (y/n)"
    if ($answer -eq "y") { 
        foreach ($folder in $folders) {
            Set-Location $folder
            # current absolute location
            if ( -not (Test-Path $rawfolder) ) { New-Item -ItemType Directory -Path $rawfolder }
            Move-Item $(Get-ChildItem -File -Filter "*.$raw_ext") $($rawfolder) -Force
            Set-Location ..
            Write-Host "Files moved to $rawfolder" -ForegroundColor DarkGreen
        }
    }
} 

function filter_raw {
    Write-Host `n`n
    # get input argument (path to folder to process) and move to it
    $folder = Read-Host "Folder to process"
    # check if folder exists
    if ( -not (Test-Path $folder) ) { Write-Host "Folder $folder does not exist`n" -ForegroundColor DarkYellow; filter_raw }
    Set-Location $folder
    # find all raw-files that do not have a compressed file with the same name
    $files = $(Get-ChildItem -File -Filter "*.$raw_ext" | Where-Object { -not (Test-Path "$($_.BaseName).$compressed_ext")})
    if ( Test-Path $rawfolder ) { $files_in_rawfolder = $(Get-ChildItem -File -Filter "*.$raw_ext" -Path $rawfolder | Where-Object { -not (Test-Path "$($_.BaseName).$compressed_ext")}) }
    # output files found
    Write-Host $files $files_in_rawfolder
    # ask user if they want to delete the files (default is no)
    if ( $files.Count -eq 0 -and $files_in_rawfolder.Count -eq 0 ) { Write-Host "No files to process" -ForegroundColor DarkYellow; Set-Location ..; filter_raw }
    $answer = Read-Host "Delete $($folder.Count + $files_in_rawfolder.Count -1) files? (y/n)"
    # if answer is no ask if they want to move the files to a new folder (default is no)
    if ( $answer -ne "y" ) {
        $answer = Read-Host "Move files to a new folder? (y/n)"
        # if answer is yes create a new folder and move the files to it
        if ( $answer -eq "y" ) {
            if ( -not (Test-Path $nomatch) ) { New-Item -ItemType Directory -Path $nomatch }
            if ( $files ) { Move-Item $files $nomatch -Force }
            if ( $files_in_rawfolder ) { 
                Set-Location $rawfolder
                Move-Item $files_in_rawfolder "../$nomatch" -Force
                Set-Location ..
            }
            Write-Host "Files moved" -ForegroundColor DarkGreen
        }
    }
    else { # delete the files
        if ( $files ) { Remove-Item $files }
        if ( $files_in_rawfolder ) { 
            Set-Location $rawfolder
            Remove-Item $files_in_rawfolder
            Set-Location ..
        }
        Write-Host "Files deleted" -ForegroundColor DarkGreen
    }
    Set-Location ..
    # ask user if they want to procress another folder
    $answer = Read-Host `n"Process another folder? (y/n)"
    if ( $answer -eq "y" ) { filter_raw }
    else { Write-Host `n`n"Goodbye" -ForegroundColor DarkYellow; exit 0 }
}

filter_raw
