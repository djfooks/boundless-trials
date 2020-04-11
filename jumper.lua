require "trials/scripthelpers"
if not scriptStart(true) then
    return
end

scriptRequire("trials/batchblocks")
scriptRequire("trials/blockpatterns")

function workFn()
    print("working")
    -- empty the whole space
    clearCubeXYZ(100, 100, 100, 150, 150, 150)

    local baseBlockType = boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP
    local craftedBlockType = boundless.getBlockTypeData(baseBlockType).craftedType
    local stone = boundless.BlockValues(baseBlockType, 0, 0, 0)
    local wallStone = boundless.BlockValues(baseBlockType, 0, 46, 0)
    local highlightStone = boundless.BlockValues(baseBlockType, 0, 78, 0)
    boxSides(100, 100, 100, 150, 150, 150, wallStone)

    fillCubeXYZ(100, 100, 100, 150, 101, 150, wallStone)

    local maxRunSpeed = 5
    local maxJumpSpeed = 7
    local gravity = -36

    local minTime=0.05
    local maxTime=1.2

    function getProjectileAtTime(start, dirX, dirZ, runSpeed, jumpSpeed, t)
        local y = jumpSpeed * t + 0.5 * gravity * t * t
        local d = t * runSpeed
        return boundless.wrap(boundless.UnwrappedWorldPosition(
            start.x + d * dirX,
            start.y + y,
            start.z + d * dirZ))
    end

    function rndFloat(min, max)
        return min + math.random() * (max - min)
    end

    local start = boundless.wrap(boundless.UnwrappedBlockCoord(101, 138, 101))
    addBatchBlock(start, stone)

    local playerHalfWidth = 0.3
    local edge = playerHalfWidth

    for i=0,20 do
        local angle = rndFloat(0, 0.5) * math.pi
        local dirX = math.cos(angle)
        local dirZ = math.sin(angle)

        local signX
        if dirX > 0 then
            signX = 1
        else
            signX = -1
        end

        local signZ
        if dirZ > 0 then
            signZ = 1
        else
            signZ = -1
        end

        local tRnd = math.random()
        local t = minTime + (tRnd * tRnd) * (maxTime - minTime)

        local worldStart = boundless.wrap(boundless.UnwrappedWorldPosition(start) + boundless.UnwrappedWorldDelta(
            0.5 + (0.5 + edge) * signX, --move as far as possible on the block
            1.0,
            0.5 + (0.5 + edge) * signZ))

        local worldPos = getProjectileAtTime(worldStart, dirX, dirZ, maxRunSpeed, maxJumpSpeed, t)
        local endX = worldPos.x + signX * math.random(1, 3)
        local endZ = worldPos.z + signZ * math.random(1, 3)

        local x0 = math.min(endX, worldPos.x)
        local z0 = math.min(endZ, worldPos.z)
        local x1 = math.max(endX, worldPos.x)
        local z1 = math.max(endZ, worldPos.z)

        fillSubBlockXYZ(x0 - 0.251, worldPos.y - 0.251, z0 - 0.251, x1 + 0.251, worldPos.y + 0.251, z1 + 0.251, baseBlockType, craftedBlockType, 0)

        start = boundless.BlockCoord(boundless.wrap(boundless.UnwrappedWorldPosition(endX, worldPos.y, endZ)))
        addBatchBlock(start, highlightStone)
    end


    print("work done")
end

function completeFn()
    print("done")
end

yieldWrapper(workFn, 1, function ()
    setBatch(completeFn)
end)
