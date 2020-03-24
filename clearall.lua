require "trials/scripthelpers"

scriptRequire("trials/clear")

function workFn()
    clearCubeXYZ(0, 127, -32, 120, 140, 32)
    clearCubeXYZ(299, 49, 299, 331, 70, 351)
    print("Clear cube setup")
end

function clearTrials()
    yieldWrapper(workFn, 1, setBatch)
end

clearTrials()
