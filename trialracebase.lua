require "trials/scripthelpers"

local Trial = scriptRequire("trials/trial")

local TrialRaceBase = Trial:new()

function TrialRaceBase:new(o)
    o = o or Trial:new(o)
    setmetatable(o, self)
    self.__index = self

    self.raceStarted = false
    self.stopped = false
    self.won = false
    self.timeRemaining = 0
    self.secondsDisplayed = 0

    self.signP = boundless.UnwrappedBlockCoord(self.midX, self.y0 + 8, self.z1 - 3)
    self.signEntityP = self.signP
    self.startCheckerboardZ = self.z0 + 4
    self.finishCheckerboardZ = self.z1 - 6
    self.timeToComplete = 15
    self.restoreInventoryOnLose = false
    return o
end

function TrialRaceBase:Update(now, delta)
    local player
    for c in boundless.connections() do
        player = boundless.getEntity(c.id)
    end

    if player == nil then
        return
    end

    if self.stopped then
        return
    end

    if self.raceStarted == false then
        if self.won == false and player.position.z > self.startCheckerboardZ then
            self.timeRemaining = self.timeToComplete
            self.secondsDisplayed = self.timeToComplete
            self.raceStarted = true
            boundless.getEntity(self.signEntityP).text = "GO"
        end
    else
        self.timeRemaining = self.timeRemaining - delta
        if self.timeRemaining <= 0 then
            boundless.getEntity(self.signEntityP).text = "TOO SLOW"
            boundless.showPlayerLog(player, self.startTitle, "Trial lost",
                    { icon = boundless.guiIcons.boundless,
                      iconColor = boundless.guiColors.boundlessred })
            if self.restoreInventoryOnLose then
                self.restoreInventory = true
            end
            self.onComplete(false)
            self.stopped = true
        elseif player.position.z > self.finishCheckerboardZ then
            self.won = true
            boundless.getEntity(self.signEntityP).text = "WINNER"
            boundless.showPlayerLog(player, self.startTitle, "WINNER!",
                    { icon = boundless.guiIcons.boundless,
                      iconColor = boundless.guiColors.boundlessred })
            self.onComplete(self.won)
            self.stopped = true
        else
            local seconds = math.ceil(self.timeRemaining)
            if self.secondsDisplayed > seconds then
                boundless.getEntity(self.signEntityP).text = seconds
                self.secondsDisplayed = seconds
                if seconds <= 10 then
                    boundless.showPlayerLog(player, self.startTitle, "Be Quick! only " .. seconds .. "s left",
                            { icon = boundless.guiIcons.boundless,
                              iconColor = boundless.guiColors.boundlessred })
                end
            end
        end
    end
end

return TrialRaceBase
