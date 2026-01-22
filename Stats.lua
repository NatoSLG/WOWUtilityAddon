local frame = CreateFrame("Frame", "MyUtilityAddonFrame", UIParent, "BackdropTemplate")
frame:SetSize(160, 95)
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

local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
nameText:SetPoint("TOP", frame, "TOP", 0, -15)

local killText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
killText:SetPoint("TOP", frame, "TOP", 0, -35)

local jumpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
jumpText:SetPoint("TOP", killText, "BOTTOM", 0, -10)

local charData

local function UpdateUI()
    if charData then
        nameText:SetText(UnitName("player"))
        killText:SetText("Total Kills: |cffffffff" .. (charData.totalKills or 0) .. "|r")
        jumpText:SetText("Total Jumps: |cffffffff" .. (charData.totalJumps or 0) .. "|r")
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

--Check if the player was the first to tag enemy and current target
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == "MyUtilityAddon" then
            MyAddonStats = MyAddonStats or {}
            local charKey = UnitFullName("player") .. "-" .. GetRealmName()
            MyAddonStats[charKey] = MyAddonStats[charKey] or { totalKills = 0, totalJumps = 0 }
            charData = MyAddonStats[charKey]
            UpdateUI()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        if subEvent == "UNIT_DIED" and charData then
            if destGUID == UnitGUID("target") then
                if not UnitIsTapDenied("target") and UnitCanAttack("player", "target") then
                    charData.totalKills = (charData.totalKills or 0) + 1
                    UpdateUI()
                end
            end
        end
    end
end)

local isJumping = false
--Tracks jumps
hooksecurefunc("JumpOrAscendStart", function()
    if not IsFalling() and not IsMounted() and not IsSwimming() and charData then
        charData.totalJumps = (charData.totalJumps or 0) + 1
        UpdateUI()
        isJumping = true
        C_Timer.After(0.5, function() isJumping = false end)
    end
end)

--Custom slash command allowing the user to reset/hide UI of the stats
--Also allows the user to move the UI around the screen and save its location
frame:SetScript("OnDragStart", function(self) if IsControlKeyDown() then self:StartMoving() end end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

SLASH_MYADDONRESET1, SLASH_MYADDONRESET2 = "/statsreset", "/rs"
SlashCmdList["MYADDONRESET"] = function()
    if charData then
        charData.totalKills, charData.totalJumps = 0, 0
        UpdateUI()
        print("|cffFFFF00MyUtilityAddon:|r Stats Reset for this character!")
    end
end

SLASH_MYADDONTOGGLE1, SLASH_MYADDONTOGGLE2 = "/statstoggle", "/st"
SlashCmdList["MYADDONTOGGLE"] = function()
    if frame:IsShown() then frame:Hide() else frame:Show() end
end