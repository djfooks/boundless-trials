
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

function addBatchBlock(p, blockType)
    local chunkCoord = boundless.ChunkCoord(p)
    local localBlockCoord = boundless.wrap(p - boundless.BlockCoord(chunkCoord))
    local blockIndex = localBlockCoord.x + localBlockCoord.z * 16 + localBlockCoord.y * 256

    local chunksZ = getMapFromMap(batchChunks, chunkCoord.x)
    local blocksMap = getMapFromMap(chunksZ, chunkCoord.z)
    if blocksMap[blockIndex] == nil then
        batchBlocksCount = batchBlocksCount + 1
    end
    blocksMap[blockIndex] = blockType
end

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
    for x=-16,16 do
        for y=0,16 do
            for z=-0,16 do
                addBatchBlock(boundless.wrap(p + boundless.UnwrappedBlockDelta(x, y, z)), boundless.blockTypes.WOOD_ANCIENT_TRUNK)
            end
        end
    end
end

makeCube()


boundless.wrap(boundless.UnwrappedChunkCoord(0, 0))

function setBatch()
    local c;
    local blocksSet = 0
    c = coroutine.create(function()
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
        while true do
            --print("loopin")
            local chunkCoord = peekChunk()
            if chunkCoord == nil then
                batchChunks = {}
                return
            end
            local chunkLocal = boundless.BlockCoord(chunkCoord)

            if #loadedChunks == 9 then
                local blockMap = batchChunks[chunkCoord.x][chunkCoord.z]

                v = peekBlock(blockMap)
                if v == nil then
                    batchChunks[chunkCoord.x][chunkCoord.z] = nil
                    for _, loadedChunk in ipairs(loadedChunks) do
                        loadedChunk:release()
                    end
                    loadedChunks = {}
                    print("released chunks")
                else
                    local blockId = v[1]
                    local blockPos = toBlockPos(chunkLocal, blockId)
                    local blockType = v[2]
                    local blockValues = boundless.BlockValues(blockType, 0, 0, 0)
                    boundless.setBlockValues(blockPos, blockValues)
                    blocksSet = blocksSet + 1
                    blockMap[blockId] = nil
                end
            elseif loadingChunks == false then
                loadingChunks = true
                boundless.loadChunkAnd8Neighbours(chunkCoord, function (chunks)
                    for i, chunk in ipairs(chunks) do
                        loadedChunks[i] = chunk:lock()
                    end
                    print("Loaded chunks " .. #loadedChunks)
                    loadingChunks = false
                end)
            end
            coroutine.yield()
        end
    end)

    local id;
    id = os.setInterval(function()
        if coroutine.resume(c) then
            --print("Blocks set " .. blocksSet .. " / " .. batchBlocksCount)
        else
            print("batch done!")
            os.clearInterval(id)
        end
    end, 1)
end


setBatch()
