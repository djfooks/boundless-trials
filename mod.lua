require "trials/scripthelpers"
if not scriptStart(true) then
    return
end

scriptRequire("trials/sign")
scriptRequire("trials/batchblocks")
scriptRequire("trials/trialhall")
scriptRequire("trials/tiphelper")

local treeLookup = {
    { soil=boundless.blockTypes.SOIL_SILTY_BASE,
      soilDugUp=boundless.blockTypes.SOIL_SILTY_BASE_DUGUP,
      leaves=boundless.blockTypes.WOOD_LUSH_LEAVES,
      leavesDugUp=boundless.blockTypes.WOOD_LUSH_LEAVES_DUGUP,
      trunk=boundless.blockTypes.WOOD_ANCIENT_TRUNK },

    { soil=boundless.blockTypes.SOIL_PEATY_BASE,
      soilDugUp=boundless.blockTypes.SOIL_PEATY_BASE_DUGUP,
      leaves=boundless.blockTypes.WOOD_WAXY_LEAVES,
      leavesDugUp=boundless.blockTypes.WOOD_WAXY_LEAVES_DUGUP,
      trunk=boundless.blockTypes.WOOD_LUSTROUS_TRUNK },

    { soil=boundless.blockTypes.SOIL_CLAY_BASE,
      soilDugUp=boundless.blockTypes.SOIL_CLAY_BASE_DUGUP,
      leaves=boundless.blockTypes.WOOD_EXOTIC_LEAVES,
      leavesDugUp=boundless.blockTypes.WOOD_EXOTIC_LEAVES_DUGUP,
      trunk=boundless.blockTypes.WOOD_TWISTED_TRUNK },
}
function spawnTree(bx, by, bz, soilSource)
    local leaves = treeLookup[1].leaves
    local trunk = treeLookup[1].trunk
    for _, t in ipairs(treeLookup) do
        if soilSource == t.soil or soilSource == t.soilDugUp then
            leaves = t.leaves
            trunk = t.trunk
        end
    end
    print("spawnTree", bx, by, bz)
    for x = -1, 1 do
        for y = 4, 7 do
            for z = -1, 1 do
                setBlockXYZ(bx + x, by + y, bz + z, leaves, 0, 0)
            end
        end
    end
    for y = 0, 5 do
        setBlockXYZ(bx, by + y, bz, trunk, 0, 0)
    end
end

setBlockXYZ(4, 128, 4, boundless.blockTypes.SOIL_SILTY_BASE_DUGUP, 0, 0)
spawnTree(4, 129, 4, boundless.blockTypes.SOIL_SILTY_BASE_DUGUP)

local prevPosition
for c in boundless.connections() do
    local e = boundless.getEntity(c.id)
    if e then
        local p = boundless.wrap(boundless.UnwrappedWorldPosition(4, 142, 4))
        e.position = p
        prevPosition = p
        e.facing = math.pi * 0.5

        boundless.showPlayerLog(e, "Welcome", "to the the boundless trials!",
                { icon = boundless.guiIcons.boundless,
                  iconColor = boundless.guiColors.boundlessred })
    end
end

local platformsLoaded = false
function addPlatforms()
    function spawnPlatform(bx, by, bz, blockType, color)
        local blockValues = boundless.BlockValues(blockType, 0, color, 0)
        for x = -2, 2 do
            for z = -2, 2 do
                addBatchBlockXYZ(bx + x, by, bz + z, blockValues)
            end
        end
    end
    spawnPlatform(40, 128, 4, boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, 0)
    addBatchBlockXYZ(40, 128, 5, boundless.BlockValues(boundless.blockTypes.SOIL_CLAY_BASE_DUGUP))
    addBatchBlockXYZ(40, 128, 3, boundless.BlockValues(boundless.blockTypes.SOIL_PEATY_BASE_DUGUP))
    coroutine.yield()
    spawnTrials()

    local chest1Pos = boundless.wrap(boundless.UnwrappedBlockCoord(40, 129, 4))
    local chestBlockValues = boundless.BlockValues(boundless.blockTypes.STORAGE_WOOD_PLAIN, 0, 55, 0)
    addBatchBlock(chest1Pos, chestBlockValues)
    addPostFunction(function ()
        local chest1Entity = boundless.getEntity(chest1Pos)
        chest1Entity.inventory[1][1] = boundless.Item(boundless.itemTypes.ITEM_SEED_BERRY, 1, 0)
        chest1Entity.inventory[1][2] = boundless.Item(boundless.itemTypes.ITEM_SEED_TUBER, 1, 0)
    end)
end

yieldWrapper(addPlatforms, 1, function ()
    setBatch(function ()
        print("Platforms loaded!")
        platformsLoaded = true
    end)
end)

local trySpawnTree
local soilSource
local lastUpdate = os.hrtime()
local frameDelta = 1/ 16
function onEnterFrame()
    local now = os.hrtime()
    local delta = now - lastUpdate
    lastUpdate = now

    for c in boundless.connections() do
        local player = boundless.getEntity(c.id)
        if player then
            updateTips(player, delta)
            posUnderFeet = player.position:withYOffset(-0.4)

            local velocity = boundless.distance(player.position, prevPosition) / frameDelta
            prevPosition = player.position

            if posUnderFeet.y < 28 and velocity < 0.1 then
                print("Player fall reset!");
                player.position = boundless.wrap(boundless.UnwrappedWorldPosition(4, 142, 4))
                player.facing = math.pi * 0.5
            else
                local blockTypeUnderFeet = getBlockType(posUnderFeet)
                if platformsLoaded then
                    updateTrialHall(now, delta, player.position)
                end

                if posUnderFeet.x > 40 then
                    tipComplete(player, "Bridge builder")
                end

                local rootType = boundless.getBlockTypeData(blockTypeUnderFeet).rootType
                if rootType ~= boundless.blockTypes.AIR then
                    blockTypeUnderFeet = rootType
                end

                if lastBlockType == boundless.blockTypes.AIR then
                    for _, t in ipairs(treeLookup) do
                        if blockTypeUnderFeet == t.soil or blockTypeUnderFeet == t.soilDugUp then
                            print("Trigger tree spawn")
                            trySpawnTree = posUnderFeet
                            soilSource = blockTypeUnderFeet
                        end
                        if blockTypeUnderFeet == t.leavesDugUp then
                            print("Leaves jump")
                            tipComplete(player, "Soiled yourself")
                            setBlock(boundless.BlockCoord(posUnderFeet), t.soil, 0, 0)
                        end
                    end
                end

                if trySpawnTree ~= nil then
                    local treeX = trySpawnTree.x - posUnderFeet.x
                    local treeZ = trySpawnTree.z - posUnderFeet.z
                    -- lets the player get away from the tree that is about to spawn
                    if treeX * treeX + treeZ * treeZ > 1.5 then
                        tipComplete(player, "Make a tree")
                        spawnTree(math.floor(trySpawnTree.x), math.floor(trySpawnTree.y) + 1, math.floor(trySpawnTree.z), soilSource)
                        trySpawnTree = nil
                    end
                end

                lastBlockType = blockTypeUnderFeet
            end
        end
    end
end

boundless.addEventListener(boundless.events.onEnterFrame, onEnterFrame)
