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
        blockColorIndex=10
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

function signTest()
    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            local p = boundless.BlockCoord(e.position:withYOffset(0.05))

            function makeSigns()
                -- no idea why but SIGN_METAL_MODULAR doesn't work...

                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(0, 0, 5))
                addBatchSign(p1, 1, 2, 1, boundless.blockTypes.SIGN_STONE_MODULAR, "dir 1")
                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(5, 0, 0))
                addBatchSign(p1, 2, 2, 1, boundless.blockTypes.SIGN_WOOD_MODULAR, "dir 2")
                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(0, 0, -5))
                addBatchSign(p1, 3, 2, 1, boundless.blockTypes.SIGN_GLEAM_MODULAR, "dir 3")
                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 0))
                addBatchSign(p1, 4, 2, 1, boundless.blockTypes.SIGN_WOOD_MODULAR, "dir 4")

                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 5))
                addBatchSign(p1, 4, 1, 1, boundless.blockTypes.SIGN_STONE_MODULAR, "width 1")
                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 10))
                addBatchSign(p1, 4, 2, 1, boundless.blockTypes.SIGN_STONE_MODULAR, "width 2")
                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 15))
                addBatchSign(p1, 4, 3, 1, boundless.blockTypes.SIGN_STONE_MODULAR, "width 3")
                local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 20))
                addBatchSign(p1, 4, 4, 1, boundless.blockTypes.SIGN_STONE_MODULAR, "width 4")
            end

            yieldWrapper(makeSigns, 1, setBatch)
        end
    end
end

-- signTest()
