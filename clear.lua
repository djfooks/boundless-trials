require "trials/batchblocks"

function clearCubeXYZ(x0, y0, z0, x1, y1, z1)
    local p0 = boundless.wrap(boundless.UnwrappedBlockCoord(x0, y0, z0))
    local p1 = boundless.wrap(boundless.UnwrappedBlockCoord(x1, y1, z1))
    clearCube(p0, p1)
end

function clearCube(p0, p1)
    local blockValues = boundless.BlockValues(boundless.blockTypes.AIR, 0, 0, 0)
    local yieldCount = 0
    for x=p0.x,p1.x do
        for y=p0.y,p1.y do
            for z=p0.z,p1.z do
                addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z)), blockValues)
            end
            yieldCount = yieldCount + p1.z - p0.z
            if yieldCount > 1024 then
                coroutine.yield()
                yieldCount = 0
            end
        end
    end
end

function workFn()
    clearCubeXYZ(0, 127, -32, 120, 140, 32)
    clearCubeXYZ(299, 5, 299, 331, 30, 351)
    print("Clear cube setup")
end

yieldWrapper(workFn, 1, setBatch)
