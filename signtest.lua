require "trials/scripthelpers"
if not scriptStart(true) then
    return
end

scriptRequire("trials/sign")

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

signTest()
