require "trials/scripthelpers"
scriptRequire("trials/batchblocks")

local signDir = {
    { dirX=1, dirZ=0, placeOnFace=4 },
    { dirX=0, dirZ=1, placeOnFace=2 },
    { dirX=1, dirZ=0, placeOnFace=5 },
    { dirX=0, dirZ=1, placeOnFace=3 }
}

function addBatchSign(p, dir, width, height, blockType, text)
    local b = boundless.undescribeBlock({
        blockType=blockType,
        placeOnFace=signDir[dir].placeOnFace,
        rotation=0,
        blockColorIndex=228
    })

    local w = (width - 1) * 0.5
    local pos
    for i=-math.floor(w),math.ceil(w) do
        for y=1,height do
            local s = boundless.wrap(p + boundless.UnwrappedBlockDelta(i * signDir[dir].dirX, y - 1, i * signDir[dir].dirZ))
            pos = pos or s
            addBatchBlock(s, b)
        end
    end

    if text ~= nil then
        if #text >= 127 then
            text = "TEXT TOO LONG"
        end
        addPostFunction(function ()
            local c = boundless.ChunkCoord(pos)
            boundless.loadChunkAnd8Neighbours(c, function (chunks)
                local signEntity = boundless.getEntity(pos)
                if signEntity and signEntity.textAlign ~= nil then -- testing for textAlign field is sufficient to check if a sign entity
                    signEntity.text = text
                end
            end)
        end)
    end

    return pos
end
