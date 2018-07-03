[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# If there's a newer build queued for the same PR, cancel this one
if ($env:APPVEYOR_PULL_REQUEST_NUMBER -and $env:APPVEYOR_BUILD_NUMBER -ne ((Invoke-RestMethod `
    https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/history?recordsNumber=50).builds | `
    Where-Object pullRequestId -eq $env:APPVEYOR_PULL_REQUEST_NUMBER)[0].buildNumber) { `
    throw "There are newer queued builds for this pull request, failing early." }

# Set Julia URL
if ($env:PLATFORM -eq "x86") {
    $platform = "x86"
    $wordsize = "32"
} elseif ($env:PLATFORM -eq "x64") {
    $platform = "x64"
    $wordsize = "64"
} else {
    throw "No platform specified"
}

if ($env:JULIA_VERSION -eq 'latest') {
    $julia_url = "https://julialangnightlies-s3.julialang.org/bin/winnt/$platform/julia-latest-win$wordsize.exe"
} else {
    if ($env:JULIA_VERSION -eq 'release') {
        $version = "0.6"
    } elseif ($env:JULIA_VERSION -match "\d*\.\d*") {
        $version = $env:JULIA_VERSION
    } else {
        throw "Unsupported Julia version $env.JULIA_VERSION"
    }
    $julia_url = "https://julialang-s3.julialang.org/bin/winnt/$platform/$version/julia-$version-latest-win$wordsize.exe"
}


Write-Host "Installing Julia..." -NoNewLine

# Download most Julia Windows binary
(new-object net.webclient).DownloadFile($julia_url, "C:\projects\julia-binary.exe")

# Install Julia
Start-Process -FilePath "C:\projects\julia-binary.exe" -ArgumentList "/S /D=C:\projects\julia" -NoNewWindow -Wait

# Append to PATH
$env:PATH += ";C:\projects\julia\bin"

julia -e 'versioninfo()'

