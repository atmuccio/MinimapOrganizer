local ADDON_NAME, MO = ...

MO.Database = {}

-- Default database structure
MO.Database.defaults = {
    version = 1,
    debug = false,

    -- Button state
    collectedButtons = {},      -- {["ButtonName"] = true}
    excludedButtons = {},       -- {["ButtonName"] = true} - never auto-collect these

    -- Organization
    categories = {
        ["Uncategorized"] = { order = 1, color = {0.5, 0.5, 0.5} },
    },
    buttonCategories = {},      -- {["ButtonName"] = "CategoryName"}
    favorites = {},             -- {["ButtonName"] = true}

    -- Window settings
    window = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        buttonsPerRow = 8,
        buttonSize = 32,
        buttonSpacing = 4,
        scale = 1.0,
        closeOnClick = false,
        theme = "Default",
        opacity = 0.9,
    },

    -- Minimap button settings
    minimapButton = {
        hide = false,
        position = 225,  -- degrees around minimap
        lock = false,
    },

    -- Behavior settings
    autoCollect = true,
    showFavoritesFirst = true,
    sortMethod = "alphabetical",  -- "alphabetical" or "category"
}

-- Initialize the database
function MO.Database:Initialize()
    -- Create or load saved variables
    if not MinimapOrganizerDB then
        MinimapOrganizerDB = MO.Utils.DeepCopy(self.defaults)
        MO.Utils.Debug("Created new database")
    else
        -- Merge with defaults for any missing fields
        self:MergeDefaults(MinimapOrganizerDB, self.defaults)
        MO.Utils.Debug("Loaded existing database")
    end

    -- Create shortcut reference
    MO.db = MinimapOrganizerDB

    -- Check for MBB migration
    self:MigrateFromMBB()

    -- Run any version migrations
    self:RunMigrations()
end

-- Recursively merge defaults into saved data
function MO.Database:MergeDefaults(saved, defaults)
    for key, defaultValue in pairs(defaults) do
        if saved[key] == nil then
            if type(defaultValue) == "table" then
                saved[key] = MO.Utils.DeepCopy(defaultValue)
            else
                saved[key] = defaultValue
            end
            MO.Utils.Debug("Added missing key: " .. key)
        elseif type(defaultValue) == "table" and type(saved[key]) == "table" then
            -- Don't merge user data tables (categories, buttons, etc.)
            local skipMerge = {
                collectedButtons = true,
                excludedButtons = true,
                categories = true,
                buttonCategories = true,
                favorites = true,
            }
            if not skipMerge[key] then
                self:MergeDefaults(saved[key], defaultValue)
            end
        end
    end
end

-- Migrate settings from old MBB addon if present
function MO.Database:MigrateFromMBB()
    -- Check if MBB exclude list exists and we haven't migrated yet
    if MBB_Exclude and not MO.db.migratedFromMBB then
        MO.Utils.Debug("Found MBB_Exclude, migrating...")

        -- Import excluded buttons (buttons user wanted on minimap, not in bag)
        for _, buttonName in ipairs(MBB_Exclude) do
            MO.db.excludedButtons[buttonName] = true
        end

        -- Mark migration as complete
        MO.db.migratedFromMBB = true

        MO.Utils.Print(MO.L.MSG_MIGRATED_FROM_MBB)
    end
end

-- Handle version migrations
function MO.Database:RunMigrations()
    local currentVersion = MO.db.version or 0

    -- Version 1 is current, no migrations needed yet
    -- Future migrations would go here:
    -- if currentVersion < 2 then
    --     -- migrate to v2
    --     MO.db.version = 2
    -- end

    MO.db.version = self.defaults.version
end

-- Reset window position
function MO.Database:ResetWindowPosition()
    MO.db.window.point = "CENTER"
    MO.db.window.relativePoint = "CENTER"
    MO.db.window.x = 0
    MO.db.window.y = 0
end

-- Reset all settings to defaults
function MO.Database:ResetAll()
    MinimapOrganizerDB = MO.Utils.DeepCopy(self.defaults)
    MO.db = MinimapOrganizerDB
end
