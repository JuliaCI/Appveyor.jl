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

$julia_installer = "C:\projects\julia-installer.exe"
$julia_path = "C:\julia"

Write-Host "Installing Julia..."

# Download most Julia Windows binary
(new-object net.webclient).DownloadFile($julia_url, $julia_installer)

# Install Julia
Start-Process -FilePath $julia_installer -ArgumentList "/S /D=$julia_path" -NoNewWindow -Wait

if ($julia_version -ge [Version]"0.7") {
    if (Test-Path "Project.toml") {
        $env:JULIA_PROJECT = "@." # TODO: change this to --project="@."
        $env:JL_BUILD_SCRIPT = "using Pkg; Pkg.build()"
        $env:JL_TEST_SCRIPT = "using Pkg; Pkg.test(coverage=true)"
        $env:JL_CODECOV_SCRIPT = "using Pkg; Pkg.add(\`"Coverage\`"); using Coverage; Codecov.submit(process_folder())"
    } else {
        $projectname = $env:APPVEYOR_PROJECT_NAME -replace '\.jl$',''
        $env:JL_BUILD_SCRIPT = "using Pkg; Pkg.clone(pwd(), \`"$projectname\`"); Pkg.build(\`"$projectname\`")"
        $env:JL_TEST_SCRIPT = "using Pkg; Pkg.test(\`"$projectname\`", coverage=true)"
        $env:JL_CODECOV_SCRIPT = "using Pkg; cd(Pkg.dir(\`"$projectname\`")); Pkg.add(\`"Coverage\`"); using Coverage; Codecov.submit(process_folder())"
    }
} else {
    $projectname = $env:APPVEYOR_PROJECT_NAME -replace '\.jl$',''    
    $env:JL_BUILD_SCRIPT = "Pkg.clone(pwd(), \`"$projectname\`"); Pkg.build(\`"$projectname\`")"
    $env:JL_TEST_SCRIPT = "Pkg.test(\`"$projectname\`", coverage=true)"
    $env:JL_CODECOV_SCRIPT = "cd(Pkg.dir(\`"$projectname\`")); Pkg.add(\`"Coverage\`"); using Coverage; Codecov.submit(process_folder())"
}

if ($julia_version -ge [Version]"0.7") {
    C:\julia\bin\julia -e 'using InteractiveUtils; versioninfo()'
} else {
    C:\julia\bin\julia -e 'versioninfo()'
}
