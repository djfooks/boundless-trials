require "trials/scripthelpers"

local Miner = require("trials/miner")

local miningHowTo = "Make it to the other side in time\nto keep all the rocks collected"

-- ideas
--  Mining in the dark (force player to make torches)


local trialHall = {
    { name="MINING", trials={
        {
            name="Rock race I",
            description="Smash through the rocks to beat the timer\nContains: Rocks\nReward: Basic Boulder",
            howTo=miningHowTo,
            rewardBlock=boundless.blockTypes.ROCK_BOULDER_DUGUP,
            stars_required=0,
            star_1_time=30,
            star_2_time=25,
            star_3_time=20,
            class=Miner
        },
        {
            name="Rock race II",
            description="Smash through the rocks to beat the timer\nContains: Rocks\nReward: Basic Boulder",
            howTo=miningHowTo,
            rewardBlock=boundless.blockTypes.ROCK_BOULDER_DUGUP,
            stars_required=0,
            star_1_time=30,
            star_2_time=25,
            star_3_time=20,
            class=Miner
        }
    }},
    { name="RACES", trials={
        {
            name="Jump Race I",
            description="Complete the course without falling\nContains: Tech Remnant Seem\nReward: Tech Remnant Seem",
            howTo=miningHowTo,
            rewardBlock=boundless.blockTypes.ANCIENTTECHNOLOGY_COMPONENT_SEAM_ROCK_IGNEOUS_BASE,
            stars_required=0,
            star_1_time=30,
            star_2_time=25,
            star_3_time=20,
            class=Miner
        },
    }},
    { name="FIGHTING", trials={
        {
            name="Wildstock I",
            description="Kill all the Wildstock against the timer\nContains: Wildstock\nReward: Dunno yet...",
            resources={
            },
            rewardBlock=boundless.blockTypes.ROCK_BOULDER_DUGUP,
            stars_required=0,
            star_1_time=30,
            star_2_time=25,
            star_3_time=20
        }
    }},
    --TRADING={},
    --ASSAULT_COURSES={}
}

local trialMap = {}
function processTrial(sectionId, trialIndex, trialId, trial)
    trial.id = trialId
    trial.sectionId = sectionId
    trial.index = trialIndex
    trial.lastDescriptionSignText = ""
    trial.playBlock = nil
    trial.isSelected = false
    trialMap[trialId] = trial
end

local nextTrialId = 1
for sectionId, section in ipairs(trialHall) do
    for trialIndex, trial in ipairs(section.trials) do
        processTrial(sectionId, trialIndex, nextTrialId, trial)
        nextTrialId = nextTrialId + 1
    end
end

local stars = 0
local loadingTrialId
local readyTrialId
local runningTrialId
local activeTrial
function getTrialDescriptionText(trial, active)
    if stars >= trial.stars_required then
        if active then
            local msg
            if loadingTrialId == trial.id then
                local now = os.hrtime()
                if now % 1 < 0.5 then
                    return trial.howTo .. "\n... LOADING ..."
                else
                    return trial.howTo .. "\nLOADING"
                end
            elseif readyTrialId == trial.id then
                msg = trial.howTo
            else
                msg = trial.description
            end

            local now = os.hrtime()
            if now % 1 < 0.5 then
                return msg .. "\nHIT TO PLAY"
            else
                return msg .. "\n<-- HIT TO PLAY -->"
            end
        else
            return trial.description
        end
    else
        return stars .. " / " .. trial.stars_required .. " stars required"
    end
end

local trialHall0
local trialHall1
local trialsOffsetX = 100
local trialsSectionX = 105
local sectionSizeZ = 8
local sectionDepth = 10
local trialHallZ0 = 4 - (#trialHall * sectionSizeZ * 0.5)

function addSection(id, name, trials, offsetZ)
    for x = trialsOffsetX, trialsSectionX + sectionDepth do
        for z = offsetZ, offsetZ + sectionSizeZ do
            -- floor
            if x >= trialsSectionX and (z == offsetZ + 1 or z == offsetZ + sectionSizeZ - 1) then
                addBatchBlockXYZ(x, 128, z, boundless.BlockValues(boundless.blockTypes.WOOD_TWISTED_TIMBER, 0, 0, 0))
            elseif x % 4 == 2 and z % 4 == 2 then
                addBatchBlockXYZ(x, 128, z, boundless.BlockValues(boundless.blockTypes.CRYSTAL_GLEAM_BASECRAFTED, 0x33, 228, 0))
            else
                if x % 2 == 1 and z % 2 == 1 then
                    addBatchBlockXYZ(x, 128, z, boundless.BlockValues(boundless.blockTypes.WOOD_TWISTED_TIMBERCRAFTED, 0x33, 0, 0))
                else
                    addBatchBlockXYZ(x, 128, z, boundless.BlockValues(boundless.blockTypes.WOOD_ANCIENT_TIMBERCRAFTED, 0x33, 0, 0))
                end
            end
            -- roof
            if x >= trialsSectionX then
                if x % 2 == 1 and z % 2 == 1 then
                    addBatchBlockXYZ(x, 132, z, boundless.BlockValues(boundless.blockTypes.WOOD_ANCIENT_TIMBER, 0, 0, 0))
                else
                    addBatchBlockXYZ(x, 132, z, boundless.BlockValues(boundless.blockTypes.WOOD_TWISTED_TIMBER, 0, 0, 0))
                end
            end
        end
    end

    for x = trialsSectionX, trialsSectionX + sectionDepth do
        for y = 128, 131 do
            local blockType = boundless.blockTypes.WOOD_ANCIENT_TRUNK
            if x % 2 == 0 then
                blockType = boundless.blockTypes.WOOD_TWISTED_TRUNK
            end
            -- left wall
            addBatchBlockXYZ(x, y, offsetZ, boundless.BlockValues(blockType, 0, 0, 0))
            -- right wall
            addBatchBlockXYZ(x, y, offsetZ + sectionSizeZ, boundless.BlockValues(blockType, 0, 0, 0))
        end
    end

    local signP = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX - 1, 132, offsetZ + sectionSizeZ * 0.5))
    addBatchSign(signP, 2, 7, 1, boundless.blockTypes.SIGN_STONE_MODULAR, name)

    for id, trial in ipairs(trials) do
        signP = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX + 5 * id - 2, 131, offsetZ + sectionSizeZ - 1))
        -- print(trial.id .. " " .. trial.name)
        addBatchSign(signP, 1, 3, 1, boundless.blockTypes.SIGN_WOOD_MODULAR, trial.name)

        trial.descriptionSignPos = signP:withYOffset(-1)
        addBatchSign(trial.descriptionSignPos, 1, 3, 1, boundless.blockTypes.SIGN_STONE_MODULAR, getTrialDescriptionText(trial, false))

        trial.playBlock1 = boundless.wrap(trial.descriptionSignPos - boundless.UnwrappedBlockDelta(2, 0, -1))
        trial.playBlock2 = boundless.wrap(trial.descriptionSignPos - boundless.UnwrappedBlockDelta(-2, 0, -1))

        local starMsg = "1 star " .. trial.star_1_time .. "s\n" ..
                        "2 stars " .. trial.star_2_time .. "s\n" ..
                        "3 stars " .. trial.star_3_time .. "s"
        trial.starsSign = addBatchSign(signP:withYOffset(-2), 1, 3, 1, boundless.blockTypes.SIGN_WOOD_MODULAR, starMsg)
    end
end

function spawnTrials()
    local offsetZ = trialHallZ0
    trialHall0 = boundless.wrap(boundless.UnwrappedBlockCoord(trialsOffsetX, 128, offsetZ))
    for id, value in ipairs(trialHall) do
        addSection(id, value.name, value.trials, offsetZ)
        offsetZ = offsetZ + sectionSizeZ
    end
    trialHall1 = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX + sectionDepth, 132, offsetZ))
end

function onTrialLoaded()
    print("Loading completed!")
    readyTrialId = loadingTrialId
    loadingTrialId = nil
end

function copyInventory(src, dst)
    for i=1,src:capacity() do
        if src[i] ~= nil then
            dst[i] = src[i]:copy()
        else
            dst[i] = nil
        end
    end
end

function restoreInventory(src, dst)
    for i=1,dst:capacity() do
        if src[i] ~= nil then
            dst[i] = src[i]
        else
            dst[i] = nil
        end
    end
end

local savedInventory = {}
function onTrialComplete(won)
    print("onTrialComplete")
    local trial = trialMap[runningTrialId]
    runningTrialId = nil

    -- teleport back
    local player
    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            player = e
            local p = boundless.wrap(boundless.UnwrappedWorldPosition(trialsSectionX + 5 * trial.index - 2, 129, trialHallZ0 + sectionSizeZ * (trial.sectionId - 1) + 2))
            player.position = p
        end
    end

    if won then
        local p = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX + 5 * trial.index - 4, 129, trialHallZ0 + sectionSizeZ * trial.sectionId - 1))
        setBlock(p, trial.rewardBlock, 0, 0, 0)
    else
        -- remove all items collected
        if activeTrial.restoreInventory then
            restoreInventory(savedInventory, player.inventory[1])
        end
    end

    activeTrial = nil
end

local playGreen = 146
local playWhite = 228
local playColor = playGreen
function updateTrialInfo(now, delta, trial, active, playerPos)
    local msg = getTrialDescriptionText(trial, active)
    if msg ~= trial.lastDescriptionSignText then
        local signEntity = boundless.getEntity(trial.descriptionSignPos)
        if signEntity ~= nil and not signEntity:expired() then
            signEntity.text = msg
            trial.lastDescriptionSignText = msg
        end
    end

    if trial.isSelected ~= active then
        trial.isSelected = active
        if not active then
            setBlock(trial.playBlock1, boundless.blockTypes.WOOD_TWISTED_TRUNK, 0, 0)
            setBlock(trial.playBlock2, boundless.blockTypes.WOOD_TWISTED_TRUNK, 0, 0)
        end
    end

    if active then

        local activeColor
        local now = os.hrtime()
        if now % 2 < 1.0 then
            activeColor = playGreen
        else
            activeColor = playWhite
        end
        if playColor ~= activeColor then
            playColor = activeColor
            setBlock(trial.playBlock1, boundless.blockTypes.MANTLE_DEFAULT_BASE, 0, activeColor)
            setBlock(trial.playBlock2, boundless.blockTypes.MANTLE_DEFAULT_BASE, 0, activeColor)
        end

        if boundless.getEntity(trial.playBlock1, true) or boundless.getEntity(trial.playBlock2, true) then
            if readyTrialId == trial.id then
                local player
                for c in boundless.connections() do
                    local e = boundless.getEntity(c.id)
                    if e then
                        player = e
                        copyInventory(player.inventory[1], savedInventory)
                    end
                end
                readyTrialId = nil
                runningTrialId = trial.id
                activeTrial.onComplete = onTrialComplete
                activeTrial:Start()
            elseif loadingTrialId == nil then
                loadingTrialId = trial.id
                activeTrial = trial.class:new()
                activeTrial:Load(onTrialLoaded)
                setBlock(trial.playBlock1, boundless.blockTypes.AIR, 0, 0)
                setBlock(trial.playBlock2, boundless.blockTypes.AIR, 0, 0)
            end
        end
    end
end

local prevTrial
function updateTrialHall(now, delta, playerPos)
    if runningTrialId ~= nil then
        activeTrial:Update(now, delta)
    elseif trialHall1 ~= nil and
       playerPos.x >= trialHall0.x and playerPos.y >= trialHall0.y and playerPos.z >= trialHall0.z and
       playerPos.x <= trialHall1.x and playerPos.y <= trialHall1.y and playerPos.z <= trialHall1.z then

        local sectionId = math.floor((playerPos.z - trialHall0.z) / sectionSizeZ) + 1
        local trialId = math.floor((playerPos.x - trialsSectionX) / 5) + 1

        local section = trialHall[sectionId]
        local trial = section.trials[trialId]
        if trial ~= nil then
            updateTrialInfo(now, delta, trial, true, playerPos)
            if prevTrial ~= trial then
                if prevTrial ~= nil then
                    updateTrialInfo(now, delta, prevTrial, false, playerPos)
                end
                prevTrial = trial
            end
        elseif prevTrial ~= nil then
            updateTrialInfo(now, delta, prevTrial, false, playerPos)
            prevTrial = nil
        end
    elseif prevTrial ~= nil then
        updateTrialInfo(now, delta, prevTrial, false, playerPos)
        prevTrial = nil
    end
end
