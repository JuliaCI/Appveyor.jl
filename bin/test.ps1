if (($version -ge [Version]"0.7") -and (Test-Path "Project.toml")) {
    cmd /c julia -e "using Pkg; Pkg.test()"
} else {
    cmd /c julia -e "Pkg.test(\`"$projectname\`")"
}
