# Appveyor.jl

[![Build status](https://ci.appveyor.com/api/projects/status/rbca6b6qclxqdhwx/branch/master?svg=true)](https://ci.appveyor.com/project/simonbyrne/appveyor-jl)

This contains a "universal" Appveyor script for Julia repositories, making it easier to set up matrix builds and keep URLs up-to-date.

# Usage

Replace your `appveyor.yml` file with the following:

```
environment:
  matrix:
  - julia_version: 0.6
  - julia_version: 0.7
  - julia_version: latest

platform:
  - x86
  - x64

## uncomment the following lines to allow failures on nightly julia
## (tests will run but not make your overall status red)
#matrix:
#  allow_failures:
#  - julia_version: latest

branches:
  only:
    - master
    - /release-.*/

notifications:
  - provider: Email
    on_build_success: false
    on_build_failure: false
    on_build_status_changed: false

install:
  - ps: iex ((new-object net.webclient).DownloadString("https://raw.githubusercontent.com/JuliaCI/Appveyor.jl/master/bin/install.ps1"))

build_script:
  - echo "%JL_BUILD_SCRIPT%"
  - julia -e "%JL_BUILD_SCRIPT%"

test_script:
  - echo "%JL_TEST_SCRIPT%"
  - julia -e "%JL_TEST_SCRIPT%"

cache:
  - C:\julia -> appveyor.yml
```

Adjust version numbers as needed.
