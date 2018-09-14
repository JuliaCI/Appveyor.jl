# Appveyor.jl

[![Build status](https://ci.appveyor.com/api/projects/status/rbca6b6qclxqdhwx/branch/version-1?svg=true)](https://ci.appveyor.com/project/simonbyrne/appveyor-jl)
[![codecov.io](http://codecov.io/github/JuliaCI/Appveyor.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaCI/Appveyor.jl?branch=version-1)
[![Coveralls](https://coveralls.io/repos/github/JuliaCI/Appveyor.jl/badge.svg?branch=version-1)](https://coveralls.io/github/JuliaCI/Appveyor.jl?branch=version-1)

This contains a "universal" Appveyor script for Julia repositories, making it easier to set up matrix builds and keep URLs up-to-date.

# Usage

Replace your `appveyor.yml` file with the following:

```
environment:
  matrix:
  - julia_version: 0.7
  - julia_version: 1
  - julia_version: nightly
#  codecov: true
#  coveralls_token:
#    secure: XXXXX


platform:
  - x86 # 32-bit
  - x64 # 64-bit

# # Uncomment the following lines to allow failures on nightly julia
# # (tests will run but not make your overall status red)
# matrix:
#   allow_failures:
#   - julia_version: nightly

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

on_success:
  - echo "%JL_SUCCESS_SCRIPT%"
  - C:\julia\bin\julia -e "%JL_SUCCESS_SCRIPT%"
```

## Julia versions

Adjust `julia_version` environment variable as needed. Accepted are:
 - `nightly`: for latest [nightly build](https://julialang.org/downloads/nightlies.html).
 - `1`: for latest version 1 major release
 - x.y: for latest x.y minor release
 - x.y.z: for exact x.y.z release

## Coverage

The script supports automatic uploading of coverage statistics to various online services.

### Codecov

1. Enable [Codecov.io](https://codecov.io/) on the repository.
2. Add a `codecov` environment variable.

If the repository is private, you will need to provide a `CODECOV_TOKEN`, similar to Coveralls below.

### Coveralls 

1. Enable [Coveralls.io](https://coveralls.io/) on the repository.
2. Copy the provided secret token.
3. Encrypt the token at https://ci.appveyor.com/tools/encrypt
4. Provide the encrypted token as a [secure environment variable](https://www.appveyor.com/docs/how-to/secure-files/#decrypting-files-during-an-appveyor-build) `coveralls_token` (see the example above).
