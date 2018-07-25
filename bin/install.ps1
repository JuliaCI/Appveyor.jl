[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# If there's a newer build queued for the same PR, cancel this one
if ($env:APPVEYOR_PULL_REQUEST_NUMBER -and $env:APPVEYOR_BUILD_NUMBER -ne ((Invoke-RestMethod `
    https://ci.appveyor.com/api/projects/$env:APPVEYOR_ACCOUNT_NAME/$env:APPVEYOR_PROJECT_SLUG/history?recordsNumber=50).builds | `
    Where-Object pullRequestId -eq $env:APPVEYOR_PULL_REQUEST_NUMBER)[0].buildNumber) { `
    throw "There are newer queued builds for this pull request, failing early." }

# Set version and julia_url
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
    $julia_version = [Version]"0.7"
    $julia_url = "https://julialangnightlies-s3.julialang.org/bin/winnt/$platform/julia-latest-win$wordsize.exe"
} else {
    if ($env:JULIA_VERSION -eq 'release') {
        $julia_version = [Version]"0.6"
    } elseif ($env:JULIA_VERSION -match "\d*\.\d*") {
        $julia_version = [Version]$env:JULIA_VERSION
    } else {
        throw "Unsupported Julia version $env.JULIA_VERSION"
    }
    $julia_url = "https://julialang-s3.julialang.org/bin/winnt/$platform/$julia_version/julia-$julia_version-latest-win$wordsize.exe"
}


Write-Host "Installing Julia..."

# Download most Julia Windows binary
(new-object net.webclient).DownloadFile($julia_url, "C:\projects\julia-binary.exe")

# Install Julia
Start-Process -FilePath "C:\projects\julia-binary.exe" -ArgumentList "/S /D=C:\projects\julia" -NoNewWindow -Wait

# Append to PATH
$env:PATH += ";C:\projects\julia\bin"

if (($julia_version -ge [Version]"0.7") -and (Test-Path "Project.toml")) {
    $env:JULIA_PROJECT = "@." # TODO: change this to --project="@."
    $env:JL_BUILD_SCRIPT = "using Pkg; Pkg.build()"
    $env:JL_TEST_SCRIPT = "using Pkg; Pkg.test(coverage=true)"
} else {
    # Set projectname
    $projectname = $env:APPVEYOR_PROJECT_NAME -replace '\.jl$',''
    $env:JL_BUILD_SCRIPT = "Pkg.clone(pwd(), \`"$projectname\`"); Pkg.build(\`"$projectname\`")"
    $env:JL_TEST_SCRIPT = "Pkg.test(\`"$projectname\`", coverage=true)"
}

if ($julia_version -ge [Version]"0.7") {
    julia -e 'using InteractiveUtils; versioninfo()'
} else {
    julia -e 'versioninfo()'
}
