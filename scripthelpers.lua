local requiredModules = {}
local lastRun

function scriptStart(ignoreMultipleRuns)
    local now = os.hrtime()
    if ignoreMultipleRuns and lastRun ~= nil and now < lastRun + 3 then
        print("Only just ran... ignoring")
        return false
    end
    lastRun = now

    -- remove all active events
    for f, _ in boundless.eventListeners(boundless.events.onEnterFrame) do
        print(boundless.removeEventListener(boundless.events.onEnterFrame, f))
    end
    for id, _ in os.intervals() do
        print(os.clearInterval(id))
    end
    for id, _ in os.timeouts() do
        print(os.clearTimeout(id))
    end

    -- unload all requires so they can be reloaded without having to restart the server
    for k,v in pairs(requiredModules) do
        package.loaded[k] = nil
    end
    requiredModules = {}
    return true
end

function scriptRequire(path)
    requiredModules[path] = true
    print("Loading " .. path)
    local result = require(path)
    return result
end

-- this is slow! only use for small structures <10 blocks
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

-- this is slow! only use for small structures <10 blocks
function setBlockXYZ(x, y, z, blockType, meta, color)
    local p = boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z))
    setBlock(p, blockType, meta, color)
end

-- this is slow! only use for small structures <10 blocks
function getBlockType(p)
    local c = boundless.ChunkCoord(p)
    local blockType
    boundless.loadChunkAnd8Neighbours(c, function (chunks)
        local v = boundless.getBlockValues(boundless.BlockCoord(p))
        blockType = v.blockType
    end)
    return blockType
end
