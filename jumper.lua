require "trials/scripthelpers"
if not scriptStart(true) then
    return
end

scriptRequire("trials/batchblocks")
scriptRequire("trials/blockpatterns")

local startBlocks = {}
local baseBlockType = boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP

local trampoline = boundless.BlockValues(boundless.blockTypes.PHYSICS_TRAMPOLINE_BASE)
local reachedStone = boundless.BlockValues(baseBlockType, 0, 26, 0)
local waterLiquidMeta = boundless.undescribeLiquid({
    liquidType=boundless.liquidTypes.WATER,
    source=true
})
local water = boundless.BlockValues(boundless.blockTypes.AIR, 0, 0, waterLiquidMeta)
local glass = boundless.BlockValues(boundless.blockTypes.GLASS_DEFAULT_BASE)
local lowestEnd = 150
local completed = false

function workFn()
    print("working")
    -- empty the whole space
    clearCubeXYZ(100, 100, 100, 150, 150, 150)

    local craftedBlockType = boundless.getBlockTypeData(baseBlockType).craftedType
    local stone = boundless.BlockValues(baseBlockType, 0, 0, 0)
    local wallStone = boundless.BlockValues(baseBlockType, 0, 46, 0)
    local highlightStone = boundless.BlockValues(baseBlockType, 0, 78, 0)
    boxSides(100, 100, 100, 150, 150, 150, wallStone)

    fillCubeXYZ(101, 100, 101, 149, 101, 149, trampoline)
    fillCubeXYZ(101, 102, 101, 149, 102, 149, water)
    fillCubeXYZ(101, 149, 101, 149, 149, 149, glass)

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
    addBatchBlock(start, reachedStone)
    table.insert(startBlocks, start)
    lowestEnd = math.min(lowestEnd, start.y)

    local playerHalfWidth = 0.3
    local edge = playerHalfWidth
    local endReached = false

    while not endReached do
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
        if worldPos.y > 145 then
            worldPos = getProjectileAtTime(worldStart, dirX, dirZ, maxRunSpeed, maxJumpSpeed, t + 0.5)
        elseif worldPos.y <= 105 then
            worldPos = getProjectileAtTime(worldStart, dirX, dirZ, maxRunSpeed, maxJumpSpeed, 0.035)
        end

        local endX = worldPos.x + signX * math.random(1, 3) * 0.5
        local endZ = worldPos.z + signZ * math.random(1, 3) * 0.5

        local x0 = math.min(endX, worldPos.x)
        local z0 = math.min(endZ, worldPos.z)
        local x1 = math.max(endX, worldPos.x)
        local z1 = math.max(endZ, worldPos.z)

        if x1 >= 150 or z1 >= 150 then
            endReached = true
        else
            fillSubBlockXYZ(x0 - 0.251, worldPos.y - 0.251, z0 - 0.251, x1 + 0.251, worldPos.y + 0.251, z1 + 0.251, baseBlockType, craftedBlockType, 0)

            start = boundless.BlockCoord(boundless.wrap(boundless.UnwrappedWorldPosition(endX, worldPos.y, endZ)))
            addBatchBlock(start, highlightStone)

            lowestEnd = math.min(lowestEnd, start.y)
            table.insert(startBlocks, start)
        end
    end


    print("work done")
end

local startPosReached = 1
function teleportBack()
    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            local checkpoint = math.max(startPosReached - 1, 1)
            print("Teleporting to checkpoint " .. checkpoint .. " / " .. #startBlocks)
            local worldPos = boundless.WorldPosition(startBlocks[checkpoint])
            e.position = boundless.wrap(worldPos + boundless.UnwrappedWorldDelta(0.5, 1.5, 0.5))
        end
    end
end

function completeFn()
    print("done")
    print("lowestEnd " .. lowestEnd)
    completed = true
    teleportBack()
end

yieldWrapper(workFn, 1, function ()
    setBatch(completeFn)
end)

local velocity = 0
local prevPosition

for c in boundless.connections() do
    local e = boundless.getEntity(c.id)
    if e then
        prevPosition = e.position
    end
end

local frameDelta = 1 / 16
function onEnterFrame(worldTime)

    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            if not completed then
                return
            end

            local velocity = boundless.distance(e.position, prevPosition) / frameDelta
            prevPosition = e.position

            if e.position.y < lowestEnd - 1 and velocity < 0.1 then
                teleportBack()
            end

            posUnderFeet = e.position:withYOffset(-0.4)
            local blockUnderFeet = boundless.BlockCoord(posUnderFeet)

            for i=1,3 do
                if blockUnderFeet == startBlocks[startPosReached + i] then
                    for j=1,i do
                        setBlockValue(startBlocks[startPosReached + j], reachedStone)
                    end
                    startPosReached = startPosReached + i
                end
            end
        end
    end
end

boundless.addEventListener(boundless.events.onEnterFrame, onEnterFrame)
