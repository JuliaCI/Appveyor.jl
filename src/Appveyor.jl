module Appveyor

if VERSION < v"0.7.0-DEV.914"
    iswindows(k::Symbol=Base.Sys.KERNEL) = k in (:Windows, :NT)
else
    using Base.Sys: iswindows
end

if iswindows()
    # Allows us to verify Codecov upload via Appveyor is working
    const IS_WINDOWS = true
end

end # module
