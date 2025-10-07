$startTime = Get-Date

$ErrorActionPreference = "Stop"

# Load environment variables from .env file
Get-Content ".env" -ErrorAction SilentlyContinue | ForEach-Object {
    $name, $value = $_.split('=')
    if ($value) {
        Set-Content env:\$name $value
    }
}

$AmongUsDir = "AmongUs"

function Clear-Up {
    Remove-Item -Recurse -Force "DepotDownloader.zip" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "DepotDownloader" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "BepInEx.zip" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $AmongUsDir -ErrorAction SilentlyContinue
}

Clear-Up

# Download and run DepotDownloader
Invoke-WebRequest "https://github.com/SteamRE/DepotDownloader/releases/latest/download/DepotDownloader-windows-x64.zip" -OutFile "DepotDownloader.zip"
Expand-Archive "DepotDownloader.zip" -DestinationPath "DepotDownloader"

./DepotDownloader/DepotDownloader.exe -app $Env:AMONG_US_APP_ID -depot $Env:AMONG_US_DEPOT_ID -manifest $Env:AMONG_US_MANIFEST -username $Env:STEAM_USERNAME -password $Env:STEAM_PASSWORD -dir $AmongUsDir

# Download BepInEx and mods listed in .env file
Invoke-WebRequest $Env:BEPINEX_DOWNLOAD_URL -OutFile "BepInEx.zip"
Expand-Archive "BepInEx.zip" -DestinationPath $AmongUsDir

$counter = 0
$Env:MODS_DOWNLOAD_URL -split "," | ForEach-Object -Process {
    Write-Output $_
    Invoke-WebRequest $_ -OutFile ("$($AmongUsDir)\BepInEx\plugins\$($counter).dll")
    $counter++
}

# Initialise dump directory before Dumpostor complains
New-Item -ItemType Directory -Path "$($AmongUsDir)\dump"

# Run AmongUs, waiting until it has finished
$AmongUsPid = Start-Process "$($AmongUsDir)\Among Us.exe" -ArgumentList "-batchmode -nographics" -PassThru
Wait-Process -InputObject $AmongUsPid

# Copy dump outputs to CWD
Remove-Item -Recurse -Force "dump" -ErrorAction SilentlyContinue
Copy-Item -Recurse "$($AmongUsDir)/dump" -Destination "."

Clear-Up

$endTime = Get-Date
$executionTime = $endTime - $startTime
Write-Output "[Artifact] Dumped data in $($executionTime.TotalSeconds) seconds"