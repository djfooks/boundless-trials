require "trials/scripthelpers"
scriptRequire("trials/batchblocks")
scriptRequire("trials/sign")
scriptRequire("trials/blockpatterns")

local TrialRaceBase = scriptRequire("trials/trialracebase")

local Miner = TrialRaceBase:new()

Miner.startTitle = "Miner Trial"
Miner.startDescription = "Cross the start line to begin!"

function Miner:BuildWork()
    local lavaBorder = 3

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

    -- mantle walls
    boxSides(self.x0 - 1, self.y0, self.z0 - 1, self.x1 + 1, self.y1, self.z1 + 1, mantle)

    -- floor and lava
    for x=self.x0,self.x1 do
        for z=self.z0,self.z1 do
            if x <= self.x0 + lavaBorder or x >= self.x1 - lavaBorder or
               z <= self.z0 + lavaBorder or z >= self.z1 - lavaBorder then
                addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, self.y0, z)), lava)
            else
                addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, self.y0, z)), darkStone)
            end
            addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, self.y0 - 1, z)), mantle)
        end
    end

    -- starting platform
    local platformX0 = self.midX - 3
    local platformX1 = self.midX + 3
    local platformTopZ = 5
    local platformTopY = self.y0 + 9
    fillCubeXYZ(self.midX - 3, self.y0, self.z0,     self.midX + 3, platformTopY, self.z0 + platformTopZ, stone)
    fillCubeXYZ(self.midX - 3, self.y0, self.z0 + 6, self.midX + 3, self.y0 + 6,   self.z0 + 8, stone2)
    fillCubeXYZ(self.midX - 3, self.y0, self.z0 + 9, self.midX + 3, self.y0 + 3,   self.z0 + 11, stone)

    -- checkerboard start line
    checkerboard(platformX0, platformX1, platformTopY, self.startCheckerboardZ - 1)
    -- checkerboard finish line
    checkerboard(self.x0 + lavaBorder + 1, self.x1 - lavaBorder - 1, self.y0, self.finishCheckerboardZ - 1)

    -- trial wall
    local wallX0 = self.x0 + lavaBorder + 1
    local wallX1 = self.x1 - lavaBorder - 1
    local wallZ0 = self.z0 + 26 - 5
    local wallZ1 = self.z0 + 26 + 5
    for x=wallX0,wallX1 do
        for z=wallZ0,wallZ1 do
            function setCol(blockValues)
                for y=self.y0,self.y0 + 4 do
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
        end
    end

    -- trial lava
    local numLava = 2 + math.random(2) - 1
    for i=1,numLava do
        local lavaBlockX = wallX0 + math.floor(((wallX1 - wallX0) / (numLava + 1)) * i) + math.random(3) - 1
        local lavaBlockZ = wallZ0 + math.random(wallZ1 - wallZ0 - 1) - 1
        addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(lavaBlockX, self.y0 + 6, lavaBlockZ)), lava)
    end

    -- sign and gleam border
    self.signEntityP = addBatchSign(self.signP, 1, 9, 3, boundless.blockTypes.SIGN_STONE_MODULAR, "Race over here")
    fillCubeXYZ(self.signP.x - 5, self.signP.y - 1, self.signP.z + 1, self.signP.x + 5, self.signP.y + 3, self.signP.z + 1, gleam)
end

function Miner:new(o)
    o = o or TrialRaceBase:new(o)
    setmetatable(o, self)
    self.__index = self

    self.startPosition = boundless.wrap(boundless.UnwrappedWorldPosition(self.midX + 0.5, self.y0 + 11, self.z0 + 0.6))
    self.restoreInventoryOnLose = true
    return o
end

return Miner
