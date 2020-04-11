require "trials/scripthelpers"
if not scriptStart(true) then
    return
end

local Miner = scriptRequire("trials/miner")

local miner = Miner:new()

miner.onComplete = function (won)
    if won then
        print("winner!")
    else
        print("loser!")
    end
end

local lastUpdate = os.hrtime()
function minerOnEnterFrame()
    local now = os.hrtime()
    local delta = now - lastUpdate
    lastUpdate = now
    if miner.loaded then
        miner:Update(now, delta)
    end
end

function testMiner()
    miner:Load(function ()
        boundless.addEventListener(boundless.events.onEnterFrame, minerOnEnterFrame)
    end)
end

testMiner()
