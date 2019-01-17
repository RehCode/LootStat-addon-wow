local function itemname_in_list(itemsTrack, itemName)
    for index, value in next, itemsTrack do
        if value.name == itemName then
            return true
        end
    end
    return false
end

local function convertSeconds(seconds)
    local times = {}
    times.days = seconds / (24 * 3600)
    seconds = seconds % (24 * 3600)
    times.hours = seconds / 3600
    seconds = seconds % 3600
    times.minutes = seconds / 60
    times.seconds = seconds % 60

    return times
end


itemsTrack = {}

SLASH_LOOTSTATS1 = "/lootstat"

local function MyAddonCommands(msg, editbox)
  -- pattern matching that skips leading whitespace and whitespace between cmd and args
  -- any whitespace at end of args is retained
  local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")

  if cmd == "add" and args ~= "" then
    print("adding " .. args)
    local itemName, itemLink, _ = GetItemInfo(args)
    if itemLink then
        itemId = string.match(itemLink, "|Hitem:(%d+)")
        print("itemId: " .. itemId)
        print("itemName: " .. itemName)
        if not itemname_in_list(itemsTrack, itemName) then
            table.insert(itemsTrack, {name=itemName, itemId=itemId, lootStat={}})
            print("item added")
        else
            print("item already on list")
        end
    end

  elseif cmd == "reset" and args ~= "" then
    print("resetting " .. args)
    local itemName, itemLink, _ = GetItemInfo(args)
    if itemLink then
        itemId = string.match(itemLink, "|Hitem:(%d+)")
        print("itemId: " .. itemId)
        print("itemName: " .. itemName)
        for index, value in next, itemsTrack do
            if value.name == itemName then
                value.lootstat = {}
                print("item stat reset of: " .. itemName)
            end
        end
    elseif args == "all" then
        for index, value in next, itemsTrack do
            if value.name == itemName then
                value.lootstat = {}
            end
        end
        print("All record were removed")
    end
  elseif cmd == "stats" and args ~= "" then
    print("stats")
  else
    -- If not handled above, display some sort of help message
    print("Syntax: /lootstat (add|remove) itemLink");
  end
end

SlashCmdList["LOOTSTATS"] = MyAddonCommands   -- add /hiw and /hellow to command list

local TestingAddon_EventFrame = CreateFrame("Frame")
local events = {}

-- Handlers --------------------------------------------------------------------
function events:CHAT_MSG_COMBAT_XP_GAIN(...)
    local msg = ...
    local xp_gain = string.match(msg, "gain (%d+) exp")
    if xp_gain then
        local gain_percent = xp_gain / UnitXPMax("player") * 100
        local repeat_times = (UnitXPMax("player") - UnitXP("player")) / xp_gain
        local final_msg = string.format("|cffff99ff Gain: %.2f%% |cff99ffcc Times to repeat: %.2f |r", gain_percent, repeat_times)
        DEFAULT_CHAT_FRAME:AddMessage(final_msg)
    end
end

function events:PLAYER_XP_UPDATE(...)

    local arg1 = ...
    local actual_xp = UnitXP("player")
    local XPMax = UnitXPMax("player")
    local porcentaje = string.format("%.2f%%", (XPMax - actual_xp) * 100 / XPMax)
    DEFAULT_CHAT_FRAME:AddMessage(porcentaje .. " to go", 1, 0.83, 0.5)
end

itemsTrack = {}

-- table.insert(itemsTrack, {name="Ghost Iron Ore", itemId=72092, lootStat={}})
-- table.insert(itemsTrack, {name="White Trillium Ore", itemId=72103, lootStat={}})
-- table.insert(itemsTrack, {name="Black Trillium Ore", itemId=72094, lootStat={}})

function events:CHAT_MSG_LOOT(...)
    -- You receive item: []
    local lootstring, _, _, _, player = ...
    local itemLink = string.match(lootstring,"|%x+|Hitem:.-|h.-|h|r")
    local itemString = string.match(itemLink, "item[%-?%d:]+")
    local lootCount = string.match(lootstring, "|%x+|Hitem:.-|h.-|h|rx(%d+)")
    local itemId = string.match(lootstring, "|Hitem:(%d+)")

    if lootCount == nil then
        lootCount = 1
    end

    local name, _, quality, _, _, class, subclass, _, equipSlot, texture, _, ClassID, SubClassID = GetItemInfo(itemString)
    local convert_times, template_msj
    if UnitName("player") == player then
        -- DEFAULT_CHAT_FRAME:AddMessage("|cffff0000 ItemID: ".. itemId .. " |r name: " .. name)
        for index, trackItem in next, itemsTrack do
            if name == trackItem.name then
                table.insert(trackItem.lootStat, {timeStamp=time(), count=lootCount})
                -- print(#trackItem.lootStat)
                index_total = #trackItem.lootStat
                if index_total > 1 then
                    index_new = index_total - 1
                    elapseSec = time() - trackItem.lootStat[index_new].timeStamp
                    elapseTimes = convertSeconds(elapseSec)
                    template_msj = string.format("%d-%d:%d::%d", elapseTimes.days,
                        elapseTimes.hours, elapseTimes.minutes, elapseTimes.seconds)
                    DEFAULT_CHAT_FRAME:AddMessage(template_msj, 0, 1, 1)
                end
           end
        end
    end
end

-- Register --------------------------------------------------------------------
TestingAddon_EventFrame:SetScript("OnEvent",
    function(self, event, ...)
        events[event](self, ...); -- call one of the functions above
    end);

for k, v in pairs(events) do
 TestingAddon_EventFrame:RegisterEvent(k); -- Register all events for which handlers have been defined
end

