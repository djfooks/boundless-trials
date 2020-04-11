require "trials/scripthelpers"
scriptRequire("trials/batchblocks")
scriptRequire("trials/sign")

Trial = {
    x0 = 300,
    y0 = 50,
    z0 = 300,
    widthX = 30,
    height = 15,
    widthZ = 50,
    startTitle = "Trial title",
    startDescription= "Trial description"
}

function Trial:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.x1 = self.x0 + self.widthX
    self.y1 = self.y0 + self.height
    self.z1 = self.z0 + self.widthZ

    self.midX = self.x0 + self.widthX * 0.5

    self.signP = boundless.UnwrappedBlockCoord(self.midX, self.y0 + 8, self.z1 - 3)
    self.startCheckerboard = self.z0 + 4
    self.endCheckerboard = self.z1 - 6

    self.started = false
    self.won = false
    self.loaded = false
    self.onComplete = nil
    self.restoreInventory = false
    return o
end

function Trial:Start()
    for c in boundless.connections() do
        local e = boundless.getEntity(c.id)
        if e then
            e.position = self.startPosition

            boundless.showPlayerLog(e, self.startTitle, self.startDescription,
                    { icon = boundless.guiIcons.boundless,
                      iconColor = boundless.guiColors.boundlessred })
        end
    end
    self.started = true
end

function Trial:Load(loadCompleteFn)
    function workFn()
        -- empty the whole space
        clearCubeXYZ(self.x0, self.y0, self.z0, self.x1, self.y1, self.z1)
        self:BuildWork()
    end

    function completeFn()
        self.loaded = true
        loadCompleteFn()
    end

    yieldWrapper(workFn, 1, function ()
        setBatch(completeFn)
    end)
end

function Trial:BuildWork()
end

function Trial:Update(now, delta)
end

return Trial
