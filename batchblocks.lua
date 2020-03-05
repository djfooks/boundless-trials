
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

local player
for c in boundless.connections() do
    local e = boundless.getEntity(c.id)
    if e then
        player = e
    end
end

local blocksArray = {}
local blocksIndex = 1

function addBlock(p, blockType)
    blocksArray[blocksIndex] = { p, blockType }
    blocksIndex = blocksIndex + 1
end

local playerBlockCoord = boundless.BlockCoord(player.position)

local p = boundless.wrap(playerBlockCoord + boundless.UnwrappedBlockDelta(10, 10, 10))
for x=-16,16 do
    for y=0,0 do
        for z=-0,0 do
            addBlock(boundless.wrap(p + boundless.UnwrappedBlockDelta(x, y, z)), boundless.blockTypes.WOOD_ANCIENT_TRUNK)
        end
    end
end

function setBatch()
    local c;
    c = coroutine.create(function()
        local chunks = {}
        local id = 0
        for _, v in ipairs(blocksArray) do
            local chunkCoord = boundless.ChunkCoord(v[1])
            local c1 = chunks[chunkCoord.x]
            if c1 == nil then
                c1 = {}
                chunks[chunkCoord.x] = c1
            end
            c1[chunkCoord.z][#c1 + 1] = v[2]
            id = id + 1
            if id == 512 then
                id = 0
                coroutine.yield()
            end
        end
        print(chunks)
    end)

    local id;
    id = os.setInterval(function()
        if coroutine.resume(c) then
        else
            print("batch done!")
            os.clearInterval(id)
        end
    end, 20)
end


setBatch()
