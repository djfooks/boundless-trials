
function stop()
    for f, _ in boundless.eventListeners(boundless.events.onEnterFrame) do
        print(boundless.removeEventListener(boundless.events.onEnterFrame, f))
    end
    for id, _ in os.intervals() do
        print(os.clearInterval(id))
    end
    for id, _ in os.timeouts() do
        print(os.clearTimeout(id))
    end
end
stop()

function setBlock(p, blockType, color)
    local c = boundless.ChunkCoord(p)
    boundless.loadChunkAnd8Neighbours(c, function (chunks)
        local v = boundless.getBlockValues(p)
        v.blockType = blockType
        v.blockMeta = 0
        v.blockColorIndex = color
        boundless.setBlockValues(p, v)
    end)
end

function setBlockXYZ(x, y, z, blockType, color)
    local p = boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z))
    setBlock(p, blockType, color)
end

function getBlockType(p)
    local c = boundless.ChunkCoord(p)
    local blockType
    boundless.loadChunkAnd8Neighbours(c, function (chunks)
        local v = boundless.getBlockValues(boundless.BlockCoord(p))
        blockType = v.blockType
    end)
    return blockType
end

function spawnTree(bx, by, bz)
    print("spawnTree", bx, by, bz)
    for x = -1, 1 do
        for y = 4, 7 do
            for z = -1, 1 do
                setBlockXYZ(bx + x, by + y, bz + z, boundless.blockTypes.WOOD_LUSH_LEAVES, 0)
            end
        end
    end
    for y = 0, 5 do
        setBlockXYZ(bx, by + y, bz, boundless.blockTypes.WOOD_ANCIENT_TRUNK, 0)
    end
end

setBlockXYZ(4, 128, 4, boundless.blockTypes.SOIL_SILTY_BASE_DUGUP, 0)
spawnTree(4, 129, 4)

local player
for c in boundless.connections() do
    local e = boundless.getEntity(c.id)
    if e then
        local p = boundless.wrap(boundless.UnwrappedWorldPosition(4, 142, 4))
        e.position = p

        player = e
        boundless.showPlayerLog(e, "Welcome", "to the the boundless trials!",
                { icon = boundless.guiIcons.boundless,
                  iconColor = boundless.guiColors.boundlessred })
    end
end

function spawnPlatform(bx, by, bz, blockType, color)
    for x = -4, 4 do
        for y = 0, 1 do
            for z = -4, 4 do
                setBlockXYZ(bx + x, by + y, bz + z, blockType, color)
            end
        end
    end
end

function spawnTrials()
end

spawnPlatform(40, 128, 4, boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, 0)
local chest1Pos = boundless.wrap(boundless.UnwrappedBlockCoord(40, 130, 4))
setBlock(chest1Pos, boundless.blockTypes.STORAGE_WOOD_PLAIN, 55)
local chest1Entity = boundless.getEntity(chest1Pos)
chest1Entity.inventory[1][1] = boundless.Item(boundless.itemTypes.PLACEABLE_WATER, 1, 0)
chest1Entity.inventory[1][2] = boundless.Item(boundless.itemTypes.PLACEABLE_LAVA, 1, 0)

-- spawnTrials()

local tips = {
    { name="Make a tree",     description="Try jumping on a soil block!" },
    { name="Bridge builder",  description="Build a bridge to the rock platform!" },
    { name="Soiled yourself", description="Try crushing leaves against something hard with your feet!" },
}
local tipLookup = {}
for id = 1,#tips do
    tipLookup[tips[id].name] = tips[id]
    tips[id].complete = false
    tips[id].id = id
end
local currentTip = 1
local tipReminderIn = 3

function tipComplete(player, name)
    local tip = tipLookup[name]
    if tip ~= nil then
        if tip.complete == false then
            tip.complete = true
            boundless.showPlayerLog(player, name .. " COMPLETE!", "",
                { icon = boundless.guiIcons.boundless,
                  iconColor = boundless.guiColors.colorGREEN })
            print("Completed tip " .. name)

            if tip.id == currentTip then
                currentTip = currentTip + 1
            end

            while currentTip <= #tips and tips[currentTip].complete do
                currentTip = currentTip + 1
            end
            if currentTip <= #tips then
                print("Next tip " .. tips[currentTip].name)
            else
                print("All tips completed")
            end
            tipReminderIn = 3
        end
    else
        boundless.showPlayerLog(player, name, "MISSING TIP",
            { icon = boundless.guiGlyph(0xec4),
              iconColor = 0 })
    end
end

function updateTips(player, delta)
    tipReminderIn = tipReminderIn - delta
    if tipReminderIn < 0 and currentTip <= #tips then
        boundless.showPlayerLog(player, tips[currentTip].name, tips[currentTip].description,
            { icon = boundless.guiIcons.boundless,
              iconColor = boundless.guiColors.green })
        tipReminderIn = 5
    end
end

local lastUpdate = os.hrtime()
function onEnterFrame()
    local now = os.hrtime()
    local delta = now - lastUpdate
    lastUpdate = now

    updateTips(player, delta)

    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            posUnderFeet = e.position:withYOffset(-0.5)

            if posUnderFeet.y < 28 then
                print("Player fall reset!");
                e.position = boundless.wrap(boundless.UnwrappedWorldPosition(4, 142, 4))
            else
                blockType = getBlockType(posUnderFeet)

                if posUnderFeet.x > 40 then
                    tipComplete(player, "Bridge builder")
                end

                local rootType = boundless.getBlockTypeData(blockType).rootType
                if rootType ~= boundless.blockTypes.AIR then
                    blockType = rootType
                end

                if lastBlockType == boundless.blockTypes.AIR then
                    if blockType == boundless.blockTypes.SOIL_SILTY_BASE_DUGUP then
                        print("Trigger tree spawn")
                        trySpawnTree = posUnderFeet
                    end
                    if blockType == boundless.blockTypes.WOOD_LUSH_LEAVES_DUGUP then
                        print("Leaves jump")
                        crushingAgainst = getBlockType(posUnderFeet:withYOffset(-1))
                        if crushingAgainst ~= boundless.blockTypes.WOOD_LUSH_LEAVES_DUGUP and
                           crushingAgainst ~= boundless.blockTypes.AIR then
                            print("Leaves crush")
                            tipComplete(player, "Soiled yourself")
                            setBlock(boundless.BlockCoord(posUnderFeet), boundless.blockTypes.SOIL_SILTY_BASE_DUGUP, 0)
                        end
                    end
                end

                if trySpawnTree ~= nil then
                    local treeX = trySpawnTree.x - posUnderFeet.x
                    local treeZ = trySpawnTree.z - posUnderFeet.z
                    -- lets the player get away from the tree that is about to spawn
                    if treeX * treeX + treeZ * treeZ > 1.5 then
                        tipComplete(player, "Make a tree")
                        spawnTree(math.floor(trySpawnTree.x), math.floor(trySpawnTree.y) + 1, math.floor(trySpawnTree.z))
                        trySpawnTree = nil
                    end
                end

                lastBlockType = blockType
            end
        end
    end
end

boundless.addEventListener(boundless.events.onEnterFrame, onEnterFrame)
