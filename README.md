# Appveyor.jl

[![Build status](https://ci.appveyor.com/api/projects/status/rbca6b6qclxqdhwx/branch/version-1?svg=true)](https://ci.appveyor.com/project/simonbyrne/appveyor-jl)

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
  - x86 # 32-bit
  - x64 # 64-bit

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
  - ps: iex ((new-object net.webclient).DownloadString("https://raw.githubusercontent.com/JuliaCI/Appveyor.jl/version-1/bin/install.ps1"))

build_script:
  - echo "%JL_BUILD_SCRIPT%"
  - C:\julia\bin\julia -e "%JL_BUILD_SCRIPT%"

test_script:
  - echo "%JL_TEST_SCRIPT%"
  - C:\julia\bin\julia -e "%JL_TEST_SCRIPT%"
```

Adjust `julia_version` numbers as needed.
