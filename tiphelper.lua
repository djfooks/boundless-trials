
local tips = {
    { name="Make a tree",     description="Try jumping on a soil block!" },
    { name="Bridge builder",  description="Build a bridge to the rock platform!" },
    { name="Soiled yourself", description="Try crushing leaves against something hard with your feet!" },
}
local tipLookup = {}
for id = 1,#tips do
    tipLookup[tips[id].name] = tips[id]
    tips[id].complete = false
    tips[id].id = id
end
local currentTip = 1
local tipReminderIn = 3

function tipComplete(player, name)
    local tip = tipLookup[name]
    if tip ~= nil then
        if tip.complete == false then
            tip.complete = true
            boundless.showPlayerLog(player, name .. " COMPLETE!", "",
                { icon = boundless.guiIcons.boundless,
                  iconColor = boundless.guiColors.colorGREEN })
            print("Completed tip " .. name)

            if tip.id == currentTip then
                currentTip = currentTip + 1
            end

            while currentTip <= #tips and tips[currentTip].complete do
                currentTip = currentTip + 1
            end
            if currentTip <= #tips then
                print("Next tip " .. tips[currentTip].name)
            else
                print("All tips completed")
            end
            tipReminderIn = 3
        end
    else
        boundless.showPlayerLog(player, name, "MISSING TIP",
            { icon = boundless.guiGlyph(0xec4),
              iconColor = 0 })
    end
end

function updateTips(player, delta)
    tipReminderIn = tipReminderIn - delta
    if tipReminderIn < 0 and currentTip <= #tips then
        boundless.showPlayerLog(player, tips[currentTip].name, tips[currentTip].description,
            { icon = boundless.guiIcons.boundless,
              iconColor = boundless.guiColors.green })
        tipReminderIn = 5
    end
end
