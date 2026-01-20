local frame = CreateFrame("Frame", nil, UIParent)
frame:SetSize(200, 100)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

--Define the class and a list for the classes self buffs
local iconPool = {}
local _, class = UnitClass("player")
local requiredBuffs = {}

if class == "MAGE" then
    requiredBuffs = { "Arcane Intellect", "Frost Armor", "Ice Armor", "Dampen Magic" }
elseif class == "PRIEST" then
    requiredBuffs = { "Power Word: Fortitude"}
elseif class == "DRUID" then
    requiredBuffs = { "Mark of the Wild", "Thorns" }
elseif class == "WARLOCK" then
    requiredBuffs = { "Demon Armor"}
end

--Template function to store buff icons
local function CreateIcon(index)
    local f = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
    f:SetSize(40, 40)
    
    --Position icons in a horizontal list
    local xOffset = (index - 1) * 45
    f:SetPoint("LEFT", frame, "LEFT", xOffset, 0)
    
    f:SetAttribute("type", "spell")
    f.tex = f:CreateTexture(nil, "OVERLAY")
    f.tex:SetAllPoints()
    f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    
    return f
end

--Function that checks&shows all active buffs that the player has learned
--as well as create an icon on screen that the player can click to active the buff if ran out.
local function CheckBuffs()
    if InCombatLockdown() then return end

    for _, iconFrame in ipairs(iconPool) do
        iconFrame:Hide()
    end

    local missingCount = 0
    for _, buffName in ipairs(requiredBuffs) do
        local spellName, _, spellIcon, _, _, _, spellID = GetSpellInfo(buffName)
        if spellID and IsPlayerSpell(spellID) then
            
            -- Check if the buff is currently active and/or any of it's higher/lower ranks
            if not AuraUtil.FindAuraByName(buffName, "player", "HELPFUL") then
                missingCount = missingCount + 1
                
                if not iconPool[missingCount] then
                    iconPool[missingCount] = CreateIcon(missingCount)
                end
                
                local currentIcon = iconPool[missingCount]
                currentIcon.tex:SetTexture(spellIcon)
                currentIcon:SetAttribute("spell", buffName) --Cast the spell
                currentIcon:Show()
            end
        end
    end
    
    --Adjust the main frame width to center the icons properly
    if missingCount > 0 then
        frame:SetWidth(missingCount * 45)
        frame:Show()
    else
        frame:Hide()
    end
end

frame:RegisterEvent("PLAYER_REGEN_ENABLED")

--Load last pos player moved UI to
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MyUtilityAddon" then
        MyAddonStats = MyAddonStats or {}
        local pos = MyAddonStats.buffPos
        self:ClearAllPoints()
        if pos then
            self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        else
            self:SetPoint("CENTER", 0, 150)
        end
        -- Run an initial check once the addon data is ready
        CheckBuffs()
    elseif (event == "UNIT_AURA" and arg1 == "player") or (event == "PLAYER_REGEN_ENABLED") then
        CheckBuffs()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, CheckBuffs)
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

--Allow the ability to drag the UI and save its pos
frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsControlKeyDown() then
        self:StartMoving()
    end
end)

frame:SetScript("OnMouseUp", function(self, button)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    MyAddonStats.buffPos = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y
    }
end)