local ADDON_NAME, MO = ...

MO.ButtonScanner = {}

local ButtonScanner = MO.ButtonScanner

-- Tracking
local hookedButtons = {}
local scanTimer = 0
local SCAN_INTERVAL = 3  -- seconds between scans

-- Initialize the scanner
function ButtonScanner:Initialize()
    MO.Utils.Debug("ButtonScanner initialized")
end

-- Start the periodic scanning
function ButtonScanner:StartScanning()
    local scanFrame = CreateFrame("Frame")
    scanFrame:SetScript("OnUpdate", function(self, elapsed)
        scanTimer = scanTimer + elapsed
        if scanTimer >= SCAN_INTERVAL then
            scanTimer = 0
            ButtonScanner:ScanMinimapChildren()
        end
    end)

    -- Do an initial scan immediately
    self:ScanNow()
end

-- Force an immediate scan
function ButtonScanner:ScanNow()
    scanTimer = 0
    self:ScanMinimapChildren()
end

-- Scan all minimap children for buttons
function ButtonScanner:ScanMinimapChildren()
    local children = { Minimap:GetChildren() }

    for _, child in ipairs(children) do
        local name = child:GetName()

        if name and not hookedButtons[name] then
            -- Check if it's a valid button and not a system button
            if self:IsValidButton(child) and not MO:IsSystemButton(name) then
                self:HookButton(child)

                -- Auto-collect if enabled and not excluded
                if MO.db.autoCollect and not MO.db.excludedButtons[name] then
                    MO.ButtonManager:CollectButton(name)
                end
            end
        end
    end
end

-- Check if a frame is a valid interactive button
function ButtonScanner:IsValidButton(frame)
    if not frame then return false end
    if not frame.HasScript then return false end

    -- Check for interactive scripts
    local hasClick = frame:HasScript("OnClick") and frame:GetScript("OnClick")
    local hasMouseUp = frame:HasScript("OnMouseUp") and frame:GetScript("OnMouseUp")
    local hasMouseDown = frame:HasScript("OnMouseDown") and frame:GetScript("OnMouseDown")

    return hasClick or hasMouseUp or hasMouseDown
end

-- Hook a button to intercept show/hide and positioning
function ButtonScanner:HookButton(frame)
    local name = frame:GetName()
    if not name then return end

    MO.Utils.Debug("Hooking button: " .. name)

    -- Store original methods and state
    frame._mo = {
        oShow = frame.Show,
        oHide = frame.Hide,
        oSetPoint = frame.SetPoint,
        oClearAllPoints = frame.ClearAllPoints,
        oPoint = { frame:GetPoint() },
        oSize = { frame:GetWidth(), frame:GetHeight() },
        oAlpha = frame:GetAlpha(),  -- Store original alpha for restoration
        isVisible = frame:IsVisible(),
    }

    -- Hook Show
    frame.Show = function(self, ...)
        self._mo.isVisible = true

        -- Only actually show if:
        -- 1. Button is excluded (user wants it on minimap), OR
        -- 2. Collection window is open (showing buttons in grid)
        if MO.db.excludedButtons[name] then
            self._mo.oShow(self, ...)
        elseif MO.db.collectedButtons[name] and MO.CollectionWindow:IsShown() then
            self._mo.oShow(self, ...)
        elseif not MO.db.collectedButtons[name] then
            -- Not collected, show normally
            self._mo.oShow(self, ...)
        end
        -- If collected and window closed, don't show

        -- Refresh window layout if it's open
        if MO.CollectionWindow:IsShown() then
            MO.CollectionWindow:RefreshLayout()
        end
    end

    -- Hook Hide
    frame.Hide = function(self, ...)
        self._mo.isVisible = false
        self._mo.oHide(self, ...)

        -- Refresh window layout if it's open
        if MO.CollectionWindow:IsShown() then
            MO.CollectionWindow:RefreshLayout()
        end
    end

    -- Hook SetPoint to prevent repositioning while collected
    frame.SetPoint = function(self, ...)
        if MO.db.collectedButtons[name] then
            -- Block external repositioning while collected
            return
        end
        self._mo.oSetPoint(self, ...)
    end

    -- Hook ClearAllPoints
    frame.ClearAllPoints = function(self, ...)
        if MO.db.collectedButtons[name] then
            -- Block while collected
            return
        end
        self._mo.oClearAllPoints(self, ...)
    end

    -- Mark as hooked
    hookedButtons[name] = true
end

-- Check if a button is hooked
function ButtonScanner:IsHooked(name)
    return hookedButtons[name] == true
end

-- Get list of all hooked button names
function ButtonScanner:GetHookedButtons()
    local buttons = {}
    for name in pairs(hookedButtons) do
        table.insert(buttons, name)
    end
    return buttons
end
