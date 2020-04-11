require "trials/scripthelpers"
scriptRequire("trials/batchblocks")

local checkerboard1 = boundless.BlockValues(boundless.blockTypes.ROCK_IGNEOUS_BASE_DUGUP, 0, 228, 0)
local checkerboard2 = boundless.BlockValues(boundless.blockTypes.ROCK_IGNEOUS_BASE_DUGUP, 0, 1, 0)
function checkerboard(x0, x1, y, z0)
    for x=x0,x1 do
        for z=z0,z0+1 do
            if ((x + z) % 2) == 1 then
                addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z)), checkerboard1)
            else
                addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(x, y, z)), checkerboard2)
            end
        end
    end
end

function boxSides(x0, y0, z0, x1, y1, z1, blockValues)
    fillCubeXYZ(x0, y0, z0, x1, y1, z0, blockValues)
    fillCubeXYZ(x1, y0, z0, x1, y1, z1, blockValues)
    fillCubeXYZ(x0, y0, z1, x1, y1, z1, blockValues)
    fillCubeXYZ(x0, y0, z0, x0, y1, z1, blockValues)
end

function fillSubBlockXYZ(x0, y0, z0, x1, y1, z1, blockType, craftedType, color)

    local bx0 = math.floor(x0)
    local bx1 = math.ceil(x1)
    local by0 = math.floor(y0)
    local by1 = math.ceil(y1)
    local bz0 = math.floor(z0)
    local bz1 = math.ceil(z1)

    for bx=bx0,bx1 do
        for by=by0,by1 do
            for bz=bz0,bz1 do

                local i = 1
                local meta = 0

                -- meta is in zyx order
                for iz=0,1 do
                    for iy=0,1 do
                        for ix=0,1 do
                            local x = bx + 0.25 + ix * 0.5
                            local y = by + 0.25 + iy * 0.5
                            local z = bz + 0.25 + iz * 0.5
                            if x0 < x and x1 > x and
                                y0 < y and y1 > y and
                                z0 < z and z1 > z then
                                meta = meta + i
                            end
                            i = i * 2
                        end
                    end
                end

                if meta == 255 then
                    addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(bx, by, bz)), boundless.BlockValues(blockType, 0, color, 0))
                elseif meta ~= 0 then
                    addBatchBlock(boundless.wrap(boundless.UnwrappedBlockCoord(bx, by, bz)), boundless.BlockValues(craftedType, meta, color, 0))
                else
                    -- print("No meta for p0: " .. x0 .. ", " .. y0 .. ", " .. z0 .. "   p1: " .. x1 .. ", " .. y1 .. ", " .. z1)
                end
            end
        end
    end
end
