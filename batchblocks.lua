
function getMapFromMap(map, key)
    local element = map[key]
    if element == nil then
        element = {}
        map[key] = element
        return element
    end
    return element
end

local batchChunks = {}
local batchBlocksCount = 0

function addBatchBlock(p, blockValues)
    local chunkCoord = boundless.ChunkCoord(p)
    local localBlockCoord = boundless.wrap(p - boundless.BlockCoord(chunkCoord))
    local blockIndex = localBlockCoord.x + localBlockCoord.z * 16 + localBlockCoord.y * 256

    local chunksZ = getMapFromMap(batchChunks, chunkCoord.x)
    local blocksMap = getMapFromMap(chunksZ, chunkCoord.z)
    if blocksMap[blockIndex] == nil then
        batchBlocksCount = batchBlocksCount + 1
    end
    blocksMap[blockIndex] = blockValues
end

function addBatchBlockXYZ(x, y, z, blockValues)
    local p = boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z))
    return addBatchBlock(p, blockValues)
end

function yieldWrapper(workFn, interval, completeFn)
    local c;
    c = coroutine.create(function()
        workFn()
    end)
    local id;
    id = os.setInterval(function()
        if coroutine.resume(c) then
        else
            c = nil
            os.clearInterval(id)
            if completeFn ~= nil then
                completeFn()
            end
        end
    end, interval)
end

function yieldWaterfall(fnArray, completeFn)
    local i = 1
    function runNextFn()
        if i == #fnArray then
            if completeFn ~= nil then
                completeFn()
            end
        else
            yieldWrapper(fnArray[i], 1, runNextFn)
            fnArray[i] = nil
            i = i + 1
        end
    end
    runNextFn()
end

function setBatch()
    print("setBatch")
    local blocksSet = 0
    function workFn()
        function peekChunk()
            for chunkX, chunksZMap in pairs(batchChunks) do
                for chunkZ, blocksMap in pairs(chunksZMap) do
                    return boundless.wrap(boundless.UnwrappedChunkCoord(chunkX, chunkZ))
                end
            end
            return nil
        end

        function peekBlock(blockMap)
            for blockId, blockType in pairs(blockMap) do
                return { blockId, blockType }
            end
            return nil
        end

        function toBlockPos(chunkLocal, blockId)
            local blockY = math.floor(blockId / 256)
            blockId = blockId - blockY * 256
            local blockZ = math.floor(blockId / 16)
            local blockX = blockId - blockZ * 16
            return boundless.wrap(chunkLocal + boundless.UnwrappedBlockDelta(blockX, blockY, blockZ))
        end

        local loadedChunks = {}
        local loadingChunks = false
        local currentChunk = nil
        local chunkLocal = nil
        local blockMap = nil
        while true do
            --print("loopin")
            if currentChunk == nil then
                currentChunk = peekChunk()
                if currentChunk == nil then
                    batchChunks = {}
                    return
                end
                chunkLocal = boundless.BlockCoord(currentChunk)
                blockMap = batchChunks[currentChunk.x][currentChunk.z]
            end

            if #loadedChunks == 9 then
                for i=0,1023 do
                    if currentChunk then
                        v = peekBlock(blockMap)
                        if v == nil then
                            batchChunks[currentChunk.x][currentChunk.z] = nil
                            for _, loadedChunk in ipairs(loadedChunks) do
                                loadedChunk:release()
                            end
                            loadedChunks = {}
                            print("released chunks")
                            currentChunk = nil
                        else
                            local blockId = v[1]
                            local blockPos = toBlockPos(chunkLocal, blockId)
                            local blockValues = v[2]
                            boundless.setBlockValues(blockPos, blockValues)
                            blocksSet = blocksSet + 1
                            blockMap[blockId] = nil
                        end
                    end
                end

            elseif loadingChunks == false then
                loadingChunks = true
                boundless.loadChunkAnd8Neighbours(currentChunk, function (chunks)
                    for i, chunk in ipairs(chunks) do
                        loadedChunks[i] = chunk:lock()
                    end
                    print("Loaded chunks " .. #loadedChunks)
                    loadingChunks = false
                end)
            end
            coroutine.yield()
        end
    end

    yieldWrapper(workFn, 1, function()
        print("batch done!")
    end)
end

function testBatchBlocks()
    function makeCube()
        local player
        for c in boundless.connections() do
            local e = boundless.getEntity(c.id)
            if e then
                player = e
            end
        end
        local playerBlockCoord = boundless.BlockCoord(player.position)

        local p = boundless.wrap(playerBlockCoord + boundless.UnwrappedBlockDelta(10, 10, 10))

        local blockValues = boundless.BlockValues(boundless.blockTypes.WOOD_ANCIENT_TRUNK, 0, 0, 0)
        for x=-16,16 do
            for y=0,16 do
                for z=-0,16 do
                    addBatchBlock(boundless.wrap(p + boundless.UnwrappedBlockDelta(x, y, z)), blockValues)
                end
            end
            coroutine.yield()
        end
    end
    yieldWrapper(makeCube, 1, setBatch)
end

--testBatchBlocks()
