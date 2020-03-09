local trialHall = {
    { name="MINING", trials={
        {
            name="Rock race I",
            description="Smash through the rocks to beat the timer\nContains: Rocks\nReward: Basic Boulder",
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
            stars_required=0,
            star_1_time=30,
            star_2_time=25,
            star_3_time=20
        }
    }},
    { name="CHALLENGES", trials={} },
    { name="FIGHTING", trials={
        {
            name="Wildstock I",
            description="Kill all the Wildstock against the timer\nContains: Wildstock\nReward: Dunno yet...",
            resources={
            },
            reward={ boundless.blockTypes.ROCK_BOULDER_DUGUP },
            stars_required=0,
            star_1_time=30,
            star_2_time=25,
            star_3_time=20
        }
    }},
    --TRADING={},
    --ASSAULT_COURSES={}
}

local trialHall0
local trialHall1
local trailsOffsetX = 100
local trialsSectionX = 105
local sectionSizeZ = 8
local sectionDepth = 10
local stars = 0
function addSection(id, name, trials, offsetZ)
    for x = trailsOffsetX, trialsSectionX + sectionDepth do
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
        coroutine.yield()
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
        coroutine.yield()
    end

    local signP = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX - 1, 132, offsetZ + sectionSizeZ * 0.5))
    addSign(signP, 2, 7, 1, name)

    print(trials)
    for id, trial in ipairs(trials) do
        signP = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX + 5 * id - 2, 131, offsetZ + 1))
        print(trial.name)
        addSign(signP, 3, 3, 1, trial.name)
        trial.descriptionSignPos = signP:withYOffset(-1)
        addSign(trial.descriptionSignPos, 3, 3, 1, getTrialDescriptionText(trial))
        local starMsg = "1 star " .. trial.star_1_time .. "s\n" ..
                        "2 stars " .. trial.star_2_time .. "s\n" ..
                        "3 stars " .. trial.star_3_time .. "s"
        trial.starsSign = addSign(signP:withYOffset(-2), 3, 3, 1, starMsg)
    end
end

function spawnTrials()
    local offsetZ = 4 - (#trialHall * sectionSizeZ * 0.5)
    trialHall0 = boundless.wrap(boundless.UnwrappedBlockCoord(trailsOffsetX, 128, offsetZ))
    for id, value in ipairs(trialHall) do
        addSection(id, value.name, value.trials, offsetZ)
        offsetZ = offsetZ + sectionSizeZ
    end
    trialHall1 = boundless.wrap(boundless.UnwrappedBlockCoord(trialsSectionX + sectionDepth, 132, offsetZ))
end

function getTrialDescriptionText(trial, active)
    if stars >= trial.stars_required then
        if active then
            local now = os.hrtime()
            if now % 1 < 0.5 then
                return trial.description .. "\nJUMP TO PLAY"
            else
                return trial.description .. "\n--> JUMP TO PLAY <--"
            end
        else
            return trial.description
        end
    else
        return stars .. " / " .. trial.stars_required .. " stars required"
    end
end

function updateTrialHallSigns(trial, active)
    -- if active then
    --     print("ACTIVE " .. trial.name)
    -- else
    --     print("INACTIVE " .. trial.name)
    -- end

    local signEntity = boundless.getEntity(trial.descriptionSignPos)
    signEntity.text = getTrialDescriptionText(trial, active)
end

local prevTrial
function updateTrialHall(posUnderFeet)
    if trialHall1 ~= nil and
       posUnderFeet.x >= trialHall0.x and posUnderFeet.y >= trialHall0.y and posUnderFeet.z >= trialHall0.z and
       posUnderFeet.x <= trialHall1.x and posUnderFeet.y <= trialHall1.y and posUnderFeet.z <= trialHall1.z then

        local sectionId = math.floor((posUnderFeet.z - trialHall0.z) / sectionSizeZ) + 1
        local trialId = math.floor((posUnderFeet.x - trialsSectionX) / 5) + 1

        local section = trialHall[sectionId]
        local trial = section.trials[trialId]
        if trial ~= nil then
            updateTrialHallSigns(trial, true)
            if prevTrial ~= trial then
                if prevTrial ~= nil then
                    updateTrialHallSigns(prevTrial, false)
                end
                prevTrial = trial
            end
        elseif prevTrial ~= nil then
            updateTrialHallSigns(prevTrial, false)
            prevTrial = nil
        end
    elseif prevTrial ~= nil then
        updateTrialHallSigns(prevTrial, false)
        prevTrial = nil
    end
end
