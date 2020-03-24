require "trials/scripthelpers"
scriptRequire("trials/batchblocks")
scriptRequire("trials/clear")
scriptRequire("trials/sign")

local minerX = 300
local minerY = 50
local minerZ = 300
local minerWidthX = 30
local minerHeight = 10
local minerWidthZ = 50
local lavaBorder = 3
local minerMidX = minerX + minerWidthX * 0.5
local signP = boundless.UnwrappedBlockCoord(minerMidX, minerY + 8, minerZ + minerWidthZ - 3)
local signEntityP
local minerTime = 10
local startCheckerboardZ = minerZ + 4
local finishCheckerboardZ = minerZ + minerWidthZ - 6

function buildMiner(completeFn)
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
        local stone1 = boundless.BlockValues(boundless.blockTypes.ROCK_IGNEOUS_BASE_DUGUP, 0, 0, 0)
        local stone2 = boundless.BlockValues(boundless.blockTypes.ROCK_SEDIMENTARY_BASE_DUGUP, 0, 0, 0)
        local mantle = boundless.BlockValues(boundless.blockTypes.MANTLE_DEFAULT_BASE, 0, 228, 0)
        local blackMantle = boundless.BlockValues(boundless.blockTypes.MANTLE_DEFAULT_BASE, 0, 1, 0)
        local gleam = boundless.BlockValues(boundless.blockTypes.CRYSTAL_GLEAM_BASE, 0, 228, 0)

        local checkerboard1 = boundless.BlockValues(boundless.blockTypes.ROCK_IGNEOUS_BASE_DUGUP, 0, 228, 0)
        local checkerboard2 = boundless.BlockValues(boundless.blockTypes.ROCK_IGNEOUS_BASE_DUGUP, 0, 1, 0)

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
        local platformX0 = minerMidX - 3
        local platformX1 = minerMidX + 3
        local platformTopZ = 5
        local platformTopY = minerY + 9
        cube(minerMidX - 3, minerY, minerZ,     minerMidX + 3, platformTopY, minerZ + platformTopZ, stone)
        cube(minerMidX - 3, minerY, minerZ + 6, minerMidX + 3, minerY + 6,   minerZ + 8, stone2)
        cube(minerMidX - 3, minerY, minerZ + 9, minerMidX + 3, minerY + 3,   minerZ + 11, stone)

        function checkerboard(x0, x1, y, z0)
            for x=x0,x1 do
                for z=z0,z0+1 do
                    if ((x + z) % 2) == 1 then
                        addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z)), checkerboard1)
                    else
                        addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z)), checkerboard2)
                    end
                end
            end
        end
        -- checkerboard start line
        checkerboard(platformX0, platformX1, platformTopY, startCheckerboardZ - 1)
        -- checkerboard finish line
        checkerboard(minerX + lavaBorder + 1, minerX + minerWidthX - lavaBorder - 1, minerY, finishCheckerboardZ - 1)

        -- trial wall
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
                    if math.random() < 0.1 then
                        setCol(blackMantle)
                    else
                        if math.random() < 0.5 then
                            setCol(stone)
                        else
                            setCol(stone2)
                        end
                    end
                end

                yieldCount = yieldCount + 5
                if yieldCount > 512 then
                    coroutine.yield()
                    yieldCount = 0
                end
            end
        end

        -- trial lava
        local numLava = 2 + math.random(2) - 1
        for i=1,numLava do
            local lavaBlockX = wallX0 + math.floor(((wallX1 - wallX0) / (numLava + 1)) * i) + math.random(3) - 1
            local lavaBlockZ = wallZ0 + math.random(wallZ1 - wallZ0 - 1) - 1
            addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(lavaBlockX, minerY + 6, lavaBlockZ)), lava)
        end

        -- sign and gleam border
        signEntityP = addBatchSign(signP, 1, 9, 3, boundless.blockTypes.SIGN_STONE_MODULAR, "Race over here")
        cube(signP.x - 5, signP.y - 1, signP.z + 1, signP.x + 5, signP.y + 3, signP.z + 1, gleam)
    end
    yieldWrapper(workFn, 1, function ()
        setBatch(completeFn)
    end)
end

local minerBuildingComplete
local minerStarted
local minerWon
local minerTimeRemaining
local minerSecondsDisplayed
function minerUpdate(now, delta, onMinerComplete)
    local player
    for c in boundless.connections() do
        player = boundless.getEntity(c.id)
    end

    if player == nil then
        return
    end

    if minerStarted == false then
        if minerWon == false and player.position.z > startCheckerboardZ then
            minerTimeRemaining = minerTime
            minerSecondsDisplayed = minerTime
            minerStarted = true
            boundless.getEntity(signEntityP).text = "GO"
        end
    else
        minerTimeRemaining = minerTimeRemaining - delta
        if minerWon == false and minerTimeRemaining <= 0 then
            boundless.getEntity(signEntityP).text = "TOO SLOW"
            onMinerComplete(false)
        elseif minerWon == true or player.position.z > finishCheckerboardZ then
            minerWon = true
            boundless.getEntity(signEntityP).text = "WINNER"
            onMinerComplete(minerWon)
        else
            local seconds = math.ceil(minerTimeRemaining)
            if minerSecondsDisplayed > seconds then
                boundless.getEntity(signEntityP).text = seconds
                minerSecondsDisplayed = seconds
            end
        end
    end
end

local lastUpdate = os.hrtime()
function minerOnEnterFrame(onMinerComplete)
    local now = os.hrtime()
    local delta = now - lastUpdate
    lastUpdate = now
    if minerBuildingComplete then
        minerUpdate(now, delta, onMinerComplete)
    end
end

function startMiner()
    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            local p = boundless.wrap(boundless.UnwrappedWorldPosition(minerMidX + 0.5, minerY + 11, minerZ + 0.6))
            e.position = p

            boundless.showPlayerLog(e, "Miner Trial", "Cross the start line to begin!",
                    { icon = boundless.guiIcons.boundless,
                      iconColor = boundless.guiColors.boundlessred })
        end
    end
end

function loadMiner(completeFn)
    minerStarted = false
    minerWon = false
    minerBuildingComplete = false
    buildMiner(function ()
        minerBuildingComplete = true
        completeFn()
    end)
end

function testMiner()
    loadMiner(startMiner)
    boundless.addEventListener(boundless.events.onEnterFrame, minerOnEnterFrame)
end

-- testMiner()
