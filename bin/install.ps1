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

$julia_path = "C:\julia"
$julia_installer = "C:\julia-installer.exe"

# Check if file exists and is current
# Based on https://stackoverflow.com/a/30129694/392585
if ( -not (Test-Path $julia_path) ) {
    Write-Host "Cache not found, downloading Julia..."
    (New-Object System.Net.WebClient).DownloadFile($julia_url, $julia_installer)
    $install = $true

} else {
    # get the modification time of the directory
    $dt = [system.io.directoryinfo]$julia_path.LastWriteTime
    Write-Host "last modified: $dt"    
    try {
        #use HttpWebRequest to download file
	$webRequest = [System.Net.HttpWebRequest]::Create($julia_url);
        $webRequest.IfModifiedSince = $dt
	$webRequest.Method = "GET";
        [System.Net.HttpWebResponse]$webResponse = $webRequest.GetResponse()

        #Read HTTP result from the $webResponse
        $stream = New-Object System.IO.StreamReader($webResponse.GetResponseStream())
	#Save to file
        Write-Host "Cache out-of-date, downloading Julia..."        
	$stream.ReadToEnd() | Set-Content -Path $julia_installer -Force
        # remove directory
        Remove-Item -Recurse -Force $julia_path
        $install = $true

    } catch [System.Net.WebException] {
        #Check for a 304
        if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::NotModified) {
            Write-Host "Cache current, not downloading."
            $install = $false
        } else {
            throw $_.Exception
        }
    }
}

if (Test-Path $julia_path) {
   if ($install) {
       Remove-Item -Recurse -Force $julia_path
   }
} else {
   $install = $true
}

if ($install) {
    Write-Host "Installing Julia..."
    Start-Process -FilePath $julia_installer -ArgumentList "/S /D=$julia_path" -NoNewWindow -Wait
} else {
    Write-Host "Using cached Julia installation."
}    

# Append to PATH
# to be removed in future
$env:PATH += ";$julia_path\bin"

$env:JULIA_BIN = "$julia_path\bin\julia.exe"

if (($julia_version -ge [Version]"0.7") -and (Test-Path "Project.toml")) {
    $env:JULIA_PROJECT = ".@" # TODO: change this to --project="@."
    $env:JL_BUILD_SCRIPT = "using Pkg; Pkg.build()"
    $env:JL_TEST_SCRIPT = "using Pkg; Pkg.test()"
} else {
    # Set projectname
    $projectname = $env:APPVEYOR_PROJECT_NAME -replace '\.jl$',''
    $env:JL_BUILD_SCRIPT = "Pkg.clone(pwd(), \`"$projectname\`"); Pkg.build(\`"$projectname\`")"
    $env:JL_TEST_SCRIPT = "Pkg.test(\`"$projectname\`")"
}

if ($julia_version -ge [Version]"0.7") {
    julia -e 'using InteractiveUtils; versioninfo()'
} else {
    julia -e 'versioninfo()'
}
