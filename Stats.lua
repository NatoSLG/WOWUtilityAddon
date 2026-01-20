local frame = CreateFrame("Frame", "MyUtilityAddonFrame", UIParent, "BackdropTemplate")
frame:SetSize(160, 75)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

--UI customization
frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground", 
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.6)
frame:SetBackdropBorderColor(1, 1, 1, 0.8)

local killText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
killText:SetPoint("TOP", frame, "TOP", 0, -15)

local jumpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
jumpText:SetPoint("TOP", killText, "BOTTOM", 0, -10)

local function UpdateUI()
    if MyAddonStats then
        killText:SetText("Total Kills: |cffffffff" .. (MyAddonStats.totalKills or 0) .. "|r")
        jumpText:SetText("Total Jumps: |cffffffff" .. (MyAddonStats.totalJumps or 0) .. "|r")
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_FLAGS")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

--Check if the player was the first to tag enemy and current target
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "MyUtilityAddon" then
            MyAddonStats = MyAddonStats or { totalKills = 0, totalJumps = 0 }
            UpdateUI()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        
        if subEvent == "UNIT_DIED" then
            if destGUID == UnitGUID("target") then
                if not UnitIsTapDenied("target") and UnitCanAttack("player", "target") then
                    MyAddonStats.totalKills = (MyAddonStats.totalKills or 0) + 1
                    UpdateUI()
                end
            end
        end
    end
end)

--Tracks jumps
hooksecurefunc("JumpOrAscendStart", function()
    if MyAddonStats then
        MyAddonStats.totalJumps = (MyAddonStats.totalJumps or 0) + 1
        UpdateUI()
    end
end)

--Custom slash command allowing the user to reset/hide UI of the stats
SLASH_MYADDONRESET1 = "/statsreset"
SLASH_MYADDONRESET2 = "/rs"
SLASH_MYADDONTOGGLE1 = "/statstoggle"
SLASH_MYADDONTOGGLE2 = "/st"

SlashCmdList["MYADDONRESET"] = function(msg)
    if MyAddonStats then
        MyAddonStats.totalKills = 0
        MyAddonStats.totalJumps = 0
        UpdateUI()
        print("|cffFFFF00MyUtilityAddon:|r |cff00FF00Stats have been reset!|r")
    end
end

SlashCmdList["MYADDONTOGGLE"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

--Allows the movement of UI
frame:SetScript("OnDragStart", function(self)
    if IsControlKeyDown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)