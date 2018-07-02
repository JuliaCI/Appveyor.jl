[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# If there's a newer build queued for the same PR, cancel this one
if ($env:APPVEYOR_PULL_REQUEST_NUMBER -and $env:APPVEYOR_BUILD_NUMBER -ne ((Invoke-RestMethod `
    https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/history?recordsNumber=50).builds | `
    Where-Object pullRequestId -eq $env:APPVEYOR_PULL_REQUEST_NUMBER)[0].buildNumber) { `
    throw "There are newer queued builds for this pull request, failing early." }

# Set Julia URL
if ($env:PLATFORM -eq "x86") {
    $wordsize = "32"
} elseif ($env:PLATFORM -eq "x64") {
    $wordsize = "64"
} else {
    throw "No platform specified"
}

if ($env:JULIA_VERSION -eq 'latest') {
    $julia_url = "https://julialangnightlies-s3.julialang.org/bin/winnt/$env:PLATFORM/julia-latest-win$wordsize.exe"
} elseif ($env:JULIA_VERSION -match "\d*\.\d*") {
    $julia_url = "https://julialang-s3.julialang.org/bin/winnt/$env:PLATFORM/$env:JULIA_VERSION/julia-$env:JULIA_VERSION-latest-win$wordsize.exe"
} else {
    throw "Unsupported Julia version $env.JULIA_VERSION"
}

# Download most recent Julia Windows binary
(new-object net.webclient).DownloadFile(
    $julia_url,
    "C:\projects\julia-binary.exe")

# Install Julia
Start-Process -FilePath "C:\projects\julia-binary.exe" -ArgumentList "/S /D=C:\projects\julia" -NoNewWindow -Wait

# Append to PATH
$env:PATH += ";C:\projects\julia\bin"

Start-Process julia -ArgumentList "-e 'versioninfo()'" -NoNewWindow -Wait

