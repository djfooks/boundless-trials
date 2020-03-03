
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

function setBlock(p, blockType, meta, color)
    local c = boundless.ChunkCoord(p)
    boundless.loadChunkAnd8Neighbours(c, function (chunks)
        local v = boundless.getBlockValues(p)
        v.blockType = blockType
        v.blockMeta = meta
        v.blockColorIndex = color
        boundless.setBlockValues(p, v)
    end)
end

function setBlockXYZ(x, y, z, blockType, meta, color)
    local p = boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z))
    setBlock(p, blockType, meta, color)
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

local signDir = {
    { dirX=1, dirZ=0, placeOnFace=4 },
    { dirX=0, dirZ=1, placeOnFace=2 },
    { dirX=1, dirZ=0, placeOnFace=5 },
    { dirX=0, dirZ=1, placeOnFace=3 }
}
function addSign(p, dir, width, height, text)
    local b = boundless.undescribeBlock({
        blockType=boundless.blockTypes.SIGN_STONE_MODULAR,
        placeOnFace=signDir[dir].placeOnFace,
        rotation=0,
        blockColorIndex=10
    })

    local w = (width - 1) * 0.5
    local pos
    for i=-math.floor(w),math.ceil(w) do
        for y=1,height do
            local s = boundless.wrap(p + boundless.UnwrappedBlockDelta(i * signDir[dir].dirX, y - 1, i * signDir[dir].dirZ))
            pos = pos or s
            boundless.setBlockValues(s, b)
        end
    end
    local signEntity = boundless.getEntity(pos)
    if signEntity and signEntity.textAlign ~= nil then -- testing for textAlign field is sufficient to check if a sign entity
        signEntity.text = text
    end
end

local trailsOffsetX = 100
local trialsSectionX = 105
local sectionSizeZ = 8
local sectionDepth = 10
local stars = 0
function addSection(name, challenges, offsetZ)
    local c;
    c = coroutine.create(function()
        for x = trailsOffsetX, trialsSectionX + sectionDepth do
            for z = offsetZ, offsetZ + sectionSizeZ do
                -- floor
                if x >= trialsSectionX and (z == offsetZ + 1 or z == offsetZ + sectionSizeZ - 1) then
                    setBlockXYZ(x, 128, z, boundless.blockTypes.WOOD_TWISTED_TIMBER, 0, 0)
                elseif x % 4 == 2 and z % 4 == 2 then
                    setBlockXYZ(x, 128, z, boundless.blockTypes.CRYSTAL_GLEAM_BASECRAFTED, 0x33, 228)
                else
                    if x % 2 == 1 and z % 2 == 1 then
                        setBlockXYZ(x, 128, z, boundless.blockTypes.WOOD_TWISTED_TIMBERCRAFTED, 0x33, 0)
                    else
                        setBlockXYZ(x, 128, z, boundless.blockTypes.WOOD_ANCIENT_TIMBERCRAFTED, 0x33, 0)
                    end
                end
                -- roof
                if x >= trialsSectionX then
                    if x % 2 == 1 and z % 2 == 1 then
                        setBlockXYZ(x, 132, z, boundless.blockTypes.WOOD_ANCIENT_TIMBER, 0, 0)
                    else
                        setBlockXYZ(x, 132, z, boundless.blockTypes.WOOD_TWISTED_TIMBER, 0, 0)
                    end
                end
            end
            coroutine.yield()
        end

        for x = trialsSectionX, trialsSectionX + sectionDepth do
            for y = 128, 131 do
                local blockType = boundless.blockTypes.WOOD_ANCIENT_TRUNK
                if x % 2 == 0 then
                    blockType = boundless.blockTypes.WOOD_TWISTED_TRUNK
                end
                -- left wall
                setBlockXYZ(x, y, offsetZ, blockType, 0, 0)
                -- right wall
                setBlockXYZ(x, y, offsetZ + sectionSizeZ, blockType, 0, 0)
            end
            coroutine.yield()
        end
    end)

    local id;
    id = os.setInterval(function()
        if coroutine.resume(c) then
        else
            print("section done!")
            os.clearInterval(id)
        end
    end, 20)

    local signP = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX - 1, 132, offsetZ + sectionSizeZ * 0.5))
    addSign(signP, 2, 7, 1, name)

    for id, challenge in ipairs(challenges) do
        signP = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX + 5 * id - 2, 131, offsetZ + 1))
        addSign(signP, 3, 3, 1, challenge.name)
        local msg
        if stars >= challenge.stars_required then
            msg = challenge.description
        else
            msg = stars .. " / " .. challenge.stars_required .. " stars required"
        end
        addSign(signP:withYOffset(-1), 3, 3, 1, msg)
        local starMsg = "1 star " .. challenge.star_1_time .. "s\n" ..
                        "2 stars " .. challenge.star_2_time .. "s\n" ..
                        "3 stars " .. challenge.star_3_time .. "s"
        addSign(signP:withYOffset(-2), 3, 3, 1, starMsg)
    end
end

function spawnTrials()
    local sections = {
        MINING={
            {
                name="Rock race I",
                description="Smash through the rocks to beat the timer\nContains: Rocks\nReward: Basic Boulder\nJUMP TO PLAY",
                resources={
                    { blockType=boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, weight=1 }
                },
                reward={ boundless.blockTypes.ROCK_BOULDER_DUGUP },
                stars_required=0,
                star_1_time=30,
                star_2_time=25,
                star_3_time=20
            },
            {
                name="Rock race II",
                description="Smash through the rocks to beat the timer\nContains: Rocks\nReward: Basic Boulder",
                resources={
                    { blockType=boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, weight=1 },
                    { blockType=boundless.undescribeBlock(
                        {
                            blockType=boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP,
                            embeddedBlockType=boundless.blockTypes.METAL_COPPER_SEAM_DUGUP
                        }), weight=1 }
                },
                reward={ boundless.blockTypes.ROCK_BOULDER_DUGUP },
                stars_required=2,
                star_1_time=30,
                star_2_time=25,
                star_3_time=20
            }
        },
        CHALLENGES={},
        FIGHTING={},
        --TRADING={},
        --ASSAULT_COURSES={}
    }

    local numSections = 0
    for _, _ in pairs(sections) do
        numSections = numSections + 1
    end

    local offsetZ = 4 - (numSections * sectionSizeZ * 0.5)
    for key, value in pairs(sections) do
        addSection(key, value, offsetZ)
        offsetZ = offsetZ + sectionSizeZ
    end
end

spawnPlatform(40, 128, 4, boundless.blockTypes.ROCK_METAMORPHIC_BASE_DUGUP, 0)
local chest1Pos = boundless.wrap(boundless.UnwrappedBlockCoord(40, 129, 4))
setBlock(chest1Pos, boundless.blockTypes.STORAGE_WOOD_PLAIN, 0, 55)
local chest1Entity = boundless.getEntity(chest1Pos)
chest1Entity.inventory[1][1] = boundless.Item(boundless.itemTypes.PLACEABLE_WATER, 1, 0)
chest1Entity.inventory[1][2] = boundless.Item(boundless.itemTypes.PLACEABLE_LAVA, 1, 0)

spawnTrials()

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
                e.facing = math.pi * 0.5
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
