# Setting the TLS protocol to 1.2 instead of the default 1.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Powershell script to download PKHeX and Plugins (stable)
Write-Host "PKHeX and PKHeX-Plugins downloader (stable releases)"
Write-Host "Please report any issues with this setup file via GitHub issues at https://github.com/santacrab2/PKHeX-Plugins/issues"
Write-Host ""
Write-Host ""

# check network path locations
$networkPaths = @("OneDrive", "Dropbox", "Mega")
for ($i=0; $i -lt $networkPaths.Length; $i++) {
    $path = $networkPaths[$i]
    $currDir = Get-Location
    if ($currDir.Path.Contains($path)) {
        Write-Host "WARNING: $path is detected on your system. Please move the setup file to a different location before running the program."
        Read-Host "Press Enter to exit"
        exit
    }
}

# set headers
$headers = @{
"method"="GET"
  "authority"="projectpokemon.org"
  "scheme"="https"
  "path"="/home/files/file/1-pkhex/"
  "cache-control"="max-age=0"
  "upgrade-insecure-requests"="1"
  "user-agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.83 Safari/537.36"
  "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
  "sec-fetch-site"="same-origin"
  "sec-fetch-mode"="navigate"
  "sec-fetch-user"="?1"
  "sec-fetch-dest"="document"
  "referer"="https://projectpokemon.org/home/files/"
  "accept-encoding"="gzip, deflate, br"
  "accept-language"="en-US,en;q=0.9"
};

# close any open instances of PKHeX that may prevent updating the file
if ((get-process "pkhex" -ea SilentlyContinue) -ne $Null) {Stop-Process -processname "pkhex"}

# get latest stable plugins
$pluginsrepo = "santacrab2/PKHeX-Plugins"
$baserepo = "kwsch/PKHeX"
$file = "PKHeX-Plugins.zip"
$releases = "https://api.github.com/repos/$pluginsrepo/releases"
$basereleases = "https://api.github.com/repos/$baserepo/releases"

Write-Host "Determining latest plugin release ..."
$tag = (Invoke-WebRequest $releases -UseBasicParsing | ConvertFrom-Json)[0].tag_name
$basetag = (Invoke-WebRequest $basereleases -UseBasicParsing | ConvertFrom-Json)[0].tag_name
if (!$tag.Equals($basetag)) {
    Write-Host "Auto-Legality Mod for the latest stable PKHeX has not been released yet."
    Write-Host "Please wait for a new PKHeX-Plugins release before using this setup file."
    Write-Host "Alternatively, consider reading the wiki to manually setup ALM with an older PKHeX build."
    Read-Host "Press Enter to exit"
    exit
}

# get the correct page for the tag
$BasePKHeX = ((Invoke-WebRequest -Uri "https://projectpokemon.org/home/files/file/1-pkhex/" -Headers $headers -UseBasicParsing -SessionVariable "Session").Links | Where-Object {$_.href -like "https://projectpokemon.org/home/files/file/1-pkhex/?do=download*"}).href.replace("&amp;", "&")

# get cookies after making a webrequest to the official download site
$url = $BasePKHeX
$cookie = $Session.Cookies.GetCookies("https://projectpokemon.org/home/files/file/1-pkhex/")[0].Name + "=" + $Session.Cookies.GetCookies("https://projectpokemon.org/home/files/file/1-pkhex/")[0].Value + "; " + $Session.Cookies.GetCookies("https://projectpokemon.org/home/files/file/1-pkhex/")[1].Name + "=" + $Session.Cookies.GetCookies("https://projectpokemon.org/home/files/file/1-pkhex/")[1].Value + "; ips4_ipsTimezone=Asia/Singapore; ips4_hasJS=true" 

# set cookies and ddl path to the header
$headers.cookie = $cookie
$headers.path = $url

# download as PKHeX.zip
Write-Host "Downloading latest PKHeX Release (stable) from https://projectpokemon.org/home/files/file/1-pkhex/ ..."
Invoke-WebRequest $url -OutFile "PKHeX.zip" -Headers $headers -WebSession $session -Method Get -ContentType "application/zip" -UseBasicParsing

# download as PKHeX-Plugins.zip
Write-Host Downloading latest PKHeX-Plugin Release: $tag
$download = "https://github.com/$pluginsrepo/releases/download/$tag/$file"

Invoke-WebRequest $download -OutFile $file -ContentType "application/zip" -UseBasicParsing

# cleanup old files if they exist
Write-Host Cleaning up previous releases if they exist ...
Remove-Item plugins/AutoModPlugins.* -ErrorAction Ignore
Remove-Item plugins/PKHeX.Core.AutoMod.* -ErrorAction Ignore
Remove-Item plugins/QRPlugins.* -ErrorAction Ignore
Remove-Item PKHeX.exe -ErrorAction Ignore
Remove-Item PKHeX.Core.* -ErrorAction Ignore
Remove-Item PKHeX.exe.* -ErrorAction Ignore
Remove-Item PKHeX.pdb -ErrorAction Ignore
Remove-Item PKHeX.Drawing.* -ErrorAction Ignore
Remove-Item QRCoder.dll -ErrorAction Ignore


# Extract pkhex
Write-Host Extracting PKHeX ...
Expand-Archive -Path PKHeX.zip -DestinationPath $pwd

# Delete zip file
Write-Host Deleting PKHeX.zip ...
Remove-Item PKHeX.zip

# Unblock plugins and extract
dir PKHeX-Plugins*.zip | Unblock-File
New-Item -ItemType Directory -Force -Path plugins | Out-Null
Write-Host Extracting Plugins ...
Expand-Archive -Path PKHeX-Plugins*.zip -Force -DestinationPath plugins
Write-Host Deleting Plugins ...
Remove-Item PKHeX-Plugins*.zip

#Finish up script
Read-Host -Prompt "Press Enter to exit"