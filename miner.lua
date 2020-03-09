require "trials/batchblocks"
require "trials/clear"

local minerX = 300
local minerY = 5
local minerZ = 300
local minerWidthX = 30
local minerHeight = 10
local minerWidthZ = 50
local lavaBorder = 3
local minerMidX = minerX + minerWidthX * 0.5
function buildMiner()
    function workFn()
        -- empty the whole space
        clearCubeXYZ(minerX, minerY, minerZ, minerX + minerWidthX, minerY + minerHeight, minerZ + minerWidthZ)

        local lavaLiquidMeta = boundless.undescribeLiquid({
            liquidType=boundless.liquidTypes.LAVA,
            source=true
        })
        local lava = boundless.BlockValues(boundless.blockTypes.AIR, 0, 0, lavaLiquidMeta)
        local darkStone = boundless.BlockValues(boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, 0, 46, 0)
        local stone = boundless.BlockValues(boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, 0, 0, 0)
        local stone2 = boundless.BlockValues(boundless.blockTypes.ROCK_SEDIMENTARY_BASE_DUGUP, 0, 0, 0)
        local mantle = boundless.BlockValues(boundless.blockTypes.MANTLE_DEFAULT_BASE, 0, 228, 0)

        local yieldCount = 0

        function cube(x0, y0, z0, x1, y1, z1, blockValues)
            for x=x0,x1 do
                for y=y0,y1 do
                    for z=z0,z1 do
                        addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z)), blockValues)
                        yieldCount = yieldCount + 1
                        if yieldCount > 128 then
                            coroutine.yield()
                            yieldCount = 0
                        end
                    end
                end
            end
        end

        function wall(x0, z0, x1, z1, blockValues)
            cube(x0, minerY, z0, x1, minerY + minerHeight + 5, z1, blockValues)
        end

        function boxSides(x0, z0, x1, z1, blockValues)
            wall(x0, z0, x1, z0, blockValues)
            wall(x1, z0, x1, z1, blockValues)
            wall(x0, z1, x1, z1, blockValues)
            wall(x0, z0, x0, z1, blockValues)
        end

        -- mantle walls
        boxSides(minerX - 1, minerZ - 1, minerX + minerWidthX + 1, minerZ + minerWidthZ + 1, mantle)

        -- floor and lava
        for x=minerX,minerX + minerWidthX do
            for z=minerZ,minerZ + minerWidthZ do
                if x <= minerX + lavaBorder or x >= minerX + minerWidthX - lavaBorder or
                   z <= minerZ + lavaBorder or z >= minerZ + minerWidthZ - lavaBorder then
                    addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, minerY, z)), lava)
                else
                    addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, minerY, z)), darkStone)
                end
                addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, minerY - 1, z)), mantle)
                yieldCount = yieldCount + 3
                if yieldCount > 512 then
                    coroutine.yield()
                    yieldCount = 0
                end
            end
        end

        -- starting platform
        cube(minerMidX - 3, minerY, minerZ,     minerMidX + 3, minerY + 9, minerZ + 5, stone)
        cube(minerMidX - 3, minerY, minerZ + 6, minerMidX + 3, minerY + 6, minerZ + 8, stone2)
        cube(minerMidX - 3, minerY, minerZ + 9, minerMidX + 3, minerY + 3, minerZ + 11, stone)

        local wallX0 = minerX + lavaBorder + 1
        local wallX1 = minerX + minerWidthX - lavaBorder - 1
        local wallZ0 = minerZ + 26 - 5
        local wallZ1 = minerZ + 26 + 5

        for x=wallX0,wallX1 do
            for z=wallZ0,wallZ1 do
                function setCol(blockValues)
                    for y=minerY,minerY + 4 do
                        addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z)), blockValues)
                    end
                end
                if math.random() > 0.2 then
                    if math.random() < 0.5 then
                        setCol(stone)
                    else
                        setCol(stone2)
                    end
                end

                yieldCount = yieldCount + 5
                if yieldCount > 512 then
                    coroutine.yield()
                    yieldCount = 0
                end
            end
        end

        local numLava = 2 + math.random(2) - 1
        for i=1,numLava do
            local lavaBlockX = wallX0 + math.floor(((wallX1 - wallX0) / (numLava + 1)) * i) + math.random(3) - 1
            local lavaBlockZ = wallZ0 + math.random(wallZ1 - wallZ0 - 1) - 1
            addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(lavaBlockX, minerY + 6, lavaBlockZ)), lava)
        end
    end
    yieldWrapper(workFn, 1, setBatch)
end

function testMiner()
    local player
    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            local p = boundless.wrap(boundless.UnwrappedWorldPosition(minerMidX + 0.5, 16, minerZ + 2))
            e.position = p
            player = e
        end
    end

    buildMiner()
end

testMiner()
