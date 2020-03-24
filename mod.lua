require "trials/scripthelpers"
if not scriptStart(true) then
    return
end

scriptRequire("trials/sign")
scriptRequire("trials/batchblocks")
scriptRequire("trials/trialhall")
scriptRequire("trials/tiphelper")

function spawnTree(bx, by, bz)
    print("spawnTree", bx, by, bz)
    for x = -1, 1 do
        for y = 4, 7 do
            for z = -1, 1 do
                setBlockXYZ(bx + x, by + y, bz + z, boundless.blockTypes.WOOD_LUSH_LEAVES, 0, 0)
            end
        end
    end
    for y = 0, 5 do
        setBlockXYZ(bx, by + y, bz, boundless.blockTypes.WOOD_ANCIENT_TRUNK, 0, 0)
    end
end

setBlockXYZ(4, 128, 4, boundless.blockTypes.SOIL_SILTY_BASE_DUGUP, 0, 0)
spawnTree(4, 129, 4)

local player
for c in boundless.connections() do
    local e = boundless.getEntity(c.id)
    if e then
        local p = boundless.wrap(boundless.UnwrappedWorldPosition(4, 142, 4))
        e.position = p
        e.facing = math.pi * 0.5

        player = e
        boundless.showPlayerLog(e, "Welcome", "to the the boundless trials!",
                { icon = boundless.guiIcons.boundless,
                  iconColor = boundless.guiColors.boundlessred })
    end
end

function spawnPlatform(bx, by, bz, blockType, color)
    for x = -2, 2 do
        for z = -2, 2 do
            setBlockXYZ(bx + x, by, bz + z, blockType, 0, color)
        end
    end
end

spawnPlatform(40, 128, 4, boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, 0)
local chest1Pos = boundless.wrap(boundless.UnwrappedBlockCoord(40, 129, 4))
setBlock(chest1Pos, boundless.blockTypes.STORAGE_WOOD_PLAIN, 0, 55)
local chest1Entity = boundless.getEntity(chest1Pos)
chest1Entity.inventory[1][1] = boundless.Item(boundless.itemTypes.PLACEABLE_WATER, 1, 0)
chest1Entity.inventory[1][2] = boundless.Item(boundless.itemTypes.PLACEABLE_LAVA, 1, 0)

yieldWrapper(spawnTrials, 1, setBatch)

local lastUpdate = os.hrtime()
function onEnterFrame()
    local now = os.hrtime()
    local delta = now - lastUpdate
    lastUpdate = now

    updateTips(player, delta)

    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            posUnderFeet = e.position:withYOffset(-0.4)

            if posUnderFeet.y < 28 then
                print("Player fall reset!");
                e.position = boundless.wrap(boundless.UnwrappedWorldPosition(4, 142, 4))
                e.facing = math.pi * 0.5
            else
                local blockTypeUnderFeet = getBlockType(posUnderFeet)
                updateTrialHall(now, delta, e.position)

                if posUnderFeet.x > 40 then
                    tipComplete(player, "Bridge builder")
                end

                local rootType = boundless.getBlockTypeData(blockTypeUnderFeet).rootType
                if rootType ~= boundless.blockTypes.AIR then
                    blockTypeUnderFeet = rootType
                end

                if lastBlockType == boundless.blockTypes.AIR then
                    if blockTypeUnderFeet == boundless.blockTypes.SOIL_SILTY_BASE_DUGUP then
                        print("Trigger tree spawn")
                        trySpawnTree = posUnderFeet
                    end
                    if blockTypeUnderFeet == boundless.blockTypes.WOOD_LUSH_LEAVES_DUGUP then
                        print("Leaves jump")
                        crushingAgainst = getBlockType(posUnderFeet:withYOffset(-1))
                        if crushingAgainst ~= boundless.blockTypes.WOOD_LUSH_LEAVES_DUGUP and
                           crushingAgainst ~= boundless.blockTypes.AIR then
                            print("Leaves crush")
                            tipComplete(player, "Soiled yourself")
                            setBlock(boundless.BlockCoord(posUnderFeet), boundless.blockTypes.SOIL_SILTY_BASE_DUGUP, 0, 0)
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
