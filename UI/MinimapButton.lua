local ADDON_NAME, MO = ...

MO.MinimapButton = {}

local MinimapButton = MO.MinimapButton
local button = nil

-- Initialize the minimap button
function MinimapButton:Initialize()
    self:CreateButton()
    self:UpdateVisibility()
    self:UpdatePosition()
end

-- Create the minimap button
function MinimapButton:CreateButton()
    button = CreateFrame("Button", "MinimapOrganizer_MinimapButton", Minimap)
    button:SetSize(33, 33)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    -- Icon texture (storehouse icon) - positioned exactly like MBB
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 9, -7)
    icon:SetTexture("Interface\\ICONS\\Garrison_Building_Storehouse")
    icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
    button.icon = icon

    -- Border (minimap tracking style) - anchored at TOPLEFT like MBB
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border = border

    -- Highlight texture
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    -- Click handler
    button:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            MO.CollectionWindow:Toggle()
        elseif btn == "RightButton" then
            MO.Settings:Open()
        end
    end)

    -- Mouse down/up for icon press effect (like MBB)
    button:SetScript("OnMouseDown", function(self)
        self.icon:SetTexCoord(0, 1, 0, 1)
    end)

    button:SetScript("OnMouseUp", function(self)
        self.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925)
    end)

    -- Drag handlers
    button:SetScript("OnDragStart", function(self)
        if not MO.db.minimapButton.lock then
            self.isDragging = true
        end
    end)

    button:SetScript("OnDragStop", function(self)
        self.isDragging = false
    end)

    -- Update position while dragging (uses MBB-style positioning)
    button:SetScript("OnUpdate", function(self)
        if self.isDragging then
            local xpos, ypos = GetCursorPosition()
            local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()
            local scale = Minimap:GetEffectiveScale()

            xpos = xmin - xpos / scale + 70
            ypos = ypos / scale - ymin - 70

            local angle = math.deg(math.atan2(ypos, xpos))
            MO.db.minimapButton.position = angle

            MinimapButton:UpdatePosition()
        end
    end)

    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("MinimapOrganizer", 1, 1, 1)
        GameTooltip:AddLine(MO.L.TOOLTIP_LEFTCLICK, 0, 1, 0)
        GameTooltip:AddLine(MO.L.TOOLTIP_RIGHTCLICK, 0, 1, 0)
        if not MO.db.minimapButton.lock then
            GameTooltip:AddLine(MO.L.TOOLTIP_DRAG, 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    self.button = button
end

-- Update button position based on saved angle (MBB-style positioning)
function MinimapButton:UpdatePosition()
    if not button then return end

    local angle = MO.db.minimapButton.position or 225

    -- MBB's exact positioning formula for orbiting the minimap edge
    -- 83 = offset to center button on minimap edge
    -- 99 = orbital radius from minimap center
    local x = 83 - (math.cos(math.rad(angle)) * 99)
    local y = -83 + (math.sin(math.rad(angle)) * 99)

    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", x, y)
end

-- Save current position (angle)
function MinimapButton:SavePosition()
    -- Position is saved during drag in OnUpdate
    MO.Utils.Debug("Saved minimap button position: " .. (MO.db.minimapButton.position or 225))
end

-- Update visibility based on settings
function MinimapButton:UpdateVisibility()
    if not button then return end

    if MO.db.minimapButton.hide then
        button:Hide()
    else
        button:Show()
    end
end

-- Show the button
function MinimapButton:Show()
    if button then
        button:Show()
    end
end

-- Hide the button
function MinimapButton:Hide()
    if button then
        button:Hide()
    end
end
