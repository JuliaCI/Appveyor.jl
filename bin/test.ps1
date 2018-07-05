if (($version -ge [Version]"0.7") -and (Test-Path "Project.toml")) {
    julia -e "using Pkg; Pkg.test()"
} else {
    julia -e "Pkg.test(\`"$projectname\`")"
}
