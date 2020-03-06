
function getMapFromCountedMap(map, key)
    local element = map.map[key]
    if element == nil then
        map.count = map.count + 1
        element = { count=0, map={} }
        map.map[key] = element
        return element
    end
    return element
end

function setValueCountedMap(map, key, value)
    local element = map.map[key]
    if element == nil then
        map.count = map.count + 1
        map.map[key] = value
        return true
    end
    map.map[key] = value
    return false
end

local batchChunks = { count=0, map={} }
local batchBlocksCount = 0

function addBatchBlock(p, blockType)
    local chunkCoord = boundless.ChunkCoord(p)
    local localBlockCoord = boundless.wrap(p - boundless.BlockCoord(chunkCoord))
    local blockIndex = localBlockCoord.x + localBlockCoord.z * 16 + localBlockCoord.y * 256

    local chunksZ = getMapFromCountedMap(batchChunks, chunkCoord.x)
    local blocksMap = getMapFromCountedMap(chunksZ, chunkCoord.z)
    if setValueCountedMap(blocksMap, blockIndex, blockType) then
        batchBlocksCount = batchBlocksCount + 1
    end
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
        for y=0,0 do
            for z=-0,0 do
                addBatchBlock(boundless.wrap(p + boundless.UnwrappedBlockDelta(x, y, z)), boundless.blockTypes.WOOD_ANCIENT_TRUNK)
            end
        end
    end

    for x, chunksZ in pairs(batchChunks.map) do
        print("x " .. x)
        for z, blocksMap in pairs(chunksZ.map) do
            print("    z " .. z)
            for blockId, blockType in pairs(blocksMap.map) do
                print("        (" .. x .. ", " .. z .. ") blockId " .. blockId)
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
            for chunkX, chunksZMap in pairs(batchChunks.map) do
                for chunkZ, blocksMap in pairs(chunksZMap.map) do
                    return boundless.wrap(boundless.UnwrappedChunkCoord(chunkX, chunkZ))
                end
            end
            return nil
        end

        function peekBlock(blockMap)
            for blockId, blockType in pairs(blockMap.map) do
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
        while true do
            local chunkCoord = peekChunk()
            if chunkCoord == nil then
                return
            end
            local chunkLocal = boundless.BlockCoord(chunkCoord)

            if #loadedChunks == 9 then
                print("loadedChunks " .. chunkCoord.x .. " " .. chunkCoord.z)
                local blockMap = batchChunks.map[chunkCoord.x].map[chunkCoord.z]
                local allSet = false
                for i=1,16 do
                    v = peekBlock(blockMap)
                    print("peek block " .. v[1] .. " " .. v[2])
                    if v == nil then
                        allSet = true
                        break
                    end
                    local blockId = v[1]
                    local blockPos = toBlockPos(chunkLocal, blockId)
                    local blockType = v[2]
                    local blockValues = boundless.BlockValues(blockType, 0, 0, 0)
                    boundless.setBlockValues(blockPos, blockValues)
                    blocksSet = blocksSet + 1

                    blockMap.map[blockId] = nil
                    blockMap.count = blockMap.count - 1
                end

                if allSet then
                    removeFromChunkMap(chunkCoord)
                    for _, loadedChunk in ipairs(loadedChunks) do
                        loadedChunk:release()
                    end
                    loadedChunks = {}
                else
                    coroutine.yield()
                end
            else
                boundless.loadChunkAnd8Neighbours(chunkCoord, function (chunks)
                    for i, chunk in ipairs(chunks) do
                        loadedChunks[i] = chunk:lock()
                    end
                end)
            end
            coroutine.yield()
        end
    end)

    local id;
    id = os.setInterval(function()
        if coroutine.resume(c) then
            print("Blocks set " .. blocksSet .. " / " .. batchBlocksCount)
        else
            print("batch done!")
            os.clearInterval(id)
        end
    end, 20)
end


setBatch()
