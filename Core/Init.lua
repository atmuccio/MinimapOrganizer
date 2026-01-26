local ADDON_NAME, MO = ...

-- Make addon globally accessible
_G.MinimapOrganizer = MO

-- Addon metadata
MO.name = ADDON_NAME
MO.version = "1.0.0"

-- System buttons to never collect (built-in WoW and common addon frames)
MO.SYSTEM_IGNORE = {
    -- Core WoW minimap elements
    "^MiniMapTrackingFrame$",
    "^MiniMapTrackingButton$",
    "^MiniMapMailFrame$",
    "^MiniMapMailBorder$",
    "^MiniMapMailIcon$",
    "^MiniMapBattlefieldFrame$",
    "^MinimapBackdrop$",
    "^MinimapZoomIn$",
    "^MinimapZoomOut$",
    "^MiniMapPing$",
    "^MinimapZoneTextButton$",
    "^MinimapToggleButton$",
    "^MinimapBorderTop$",
    "^MinimapNorthTag$",
    "^MinimapCompassTexture$",

    -- Time/Calendar
    "^TimeManagerClockButton$",
    "^GameTimeFrame$",

    -- Queue/LFG
    "^QueueStatusMinimapButton$",
    "^QueueStatusFrame$",

    -- Expansion features
    "^GarrisonLandingPageMinimapButton$",
    "^ExpansionLandingPageMinimapButton$",

    -- Instance difficulty
    "^MiniMapInstanceDifficulty$",
    "^GuildInstanceDifficulty$",
    "^MiniMapChallengeMode$",

    -- Addon specific patterns
    "^HandyNotes.*Pin$",
    "^TomTom.*",
    "^GatherMatePin",
    "^ZGVMarker",
    "^Questie",
    "^DBM.*Minimap",

    -- Our own button
    "^MinimapOrganizer_MinimapButton$",
}

-- Create event frame
local eventFrame = CreateFrame("Frame")
MO.eventFrame = eventFrame

-- Event handler
local function OnEvent(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        MO:OnAddonLoaded()
    elseif event == "PLAYER_LOGIN" then
        MO:OnPlayerLogin()
    elseif event == "PLAYER_LOGOUT" then
        MO:OnPlayerLogout()
    end
end

eventFrame:SetScript("OnEvent", OnEvent)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

-- Called when addon files are loaded
function MO:OnAddonLoaded()
    MO.Utils.Debug("ADDON_LOADED fired")

    -- Initialize database
    MO.Database:Initialize()
end

-- Called when player enters world
function MO:OnPlayerLogin()
    MO.Utils.Debug("PLAYER_LOGIN fired")

    -- Initialize UI components
    MO.MinimapButton:Initialize()
    MO.CollectionWindow:Initialize()

    -- Start scanning for minimap buttons
    MO.ButtonScanner:Initialize()
    MO.ButtonScanner:StartScanning()

    -- Register settings panel
    MO.Settings:Initialize()

    -- Register slash commands
    self:RegisterSlashCommands()

    MO.Utils.Debug("MinimapOrganizer loaded successfully")
end

-- Called on logout (for cleanup if needed)
function MO:OnPlayerLogout()
    -- Any cleanup would go here
end

-- Register slash commands
function MO:RegisterSlashCommands()
    SLASH_MINIMAPORGANIZER1 = "/mo"
    SLASH_MINIMAPORGANIZER2 = "/minimaporganizer"

    SlashCmdList["MINIMAPORGANIZER"] = function(msg)
        local cmd = msg:lower():trim()

        if cmd == "" or cmd == "toggle" then
            MO.CollectionWindow:Toggle()

        elseif cmd == "settings" or cmd == "options" or cmd == "config" then
            MO.Settings:Open()

        elseif cmd == "reset" then
            MO.Database:ResetWindowPosition()
            MO.CollectionWindow:UpdatePosition()
            MO.Utils.Print(MO.L.SLASH_RESET_DONE)

        elseif cmd == "debug" then
            MO.db.debug = not MO.db.debug
            if MO.db.debug then
                MO.Utils.Print(MO.L.SLASH_DEBUG_ON)
            else
                MO.Utils.Print(MO.L.SLASH_DEBUG_OFF)
            end

        elseif cmd == "scan" then
            -- Force immediate scan
            MO.ButtonScanner:ScanNow()

        else
            MO.Utils.Print(MO.L.SLASH_USAGE)
        end
    end
end

-- Check if a button name matches any system ignore pattern
function MO:IsSystemButton(name)
    if not name then return true end

    for _, pattern in ipairs(self.SYSTEM_IGNORE) do
        if name:match(pattern) then
            return true
        end
    end

    return false
end
