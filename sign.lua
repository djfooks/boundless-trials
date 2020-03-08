
local signDir = {
    { dirX=1, dirZ=0, placeOnFace=4 },
    { dirX=0, dirZ=1, placeOnFace=2 },
    { dirX=1, dirZ=0, placeOnFace=5 },
    { dirX=0, dirZ=1, placeOnFace=3 }
}
function addSign(p, dir, width, height, text)
    local b = boundless.undescribeBlock({
        blockType=boundless.blockTypes.SIGN_STONE_MODULAR,
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
            boundless.setBlockValues(s, b)
        end
    end
    local signEntity = boundless.getEntity(pos)
    if signEntity and signEntity.textAlign ~= nil then -- testing for textAlign field is sufficient to check if a sign entity
        signEntity.text = text
    end
end

function signTest()
    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            local p = boundless.BlockCoord(e.position:withYOffset(0.05))
            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(0, 0, 5))
            addSign(p1, 1, 2, 1, "dir 1")
            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(5, 0, 0))
            addSign(p1, 2, 2, 1, "dir 2")
            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(0, 0, -5))
            addSign(p1, 3, 2, 1, "dir 3")
            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 0))
            addSign(p1, 4, 2, 1, "dir 4")


            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 5))
            addSign(p1, 4, 1, 1, "width 1")
            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 10))
            addSign(p1, 4, 2, 1, "width 2")
            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 15))
            addSign(p1, 4, 3, 1, "width 3")
            local p1 = boundless.wrap(p + boundless.UnwrappedBlockDelta(-5, 0, 20))
            addSign(p1, 4, 4, 1, "width 4")
        end
    end
end
