local ADDON_NAME, MO = ...

MO.Utils = {}

-- Deep copy a table
function MO.Utils.DeepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[MO.Utils.DeepCopy(k)] = MO.Utils.DeepCopy(v)
        end
        setmetatable(copy, MO.Utils.DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Check if a value exists in a table (array)
function MO.Utils.Contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Check if a key exists in a table
function MO.Utils.HasKey(tbl, key)
    return tbl[key] ~= nil
end

-- Count entries in a table
function MO.Utils.Count(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Check if string matches any pattern in a list
function MO.Utils.MatchesAnyPattern(str, patterns)
    for _, pattern in ipairs(patterns) do
        if str:match(pattern) then
            return true
        end
    end
    return false
end

-- Print a formatted addon message
function MO.Utils.Print(msg)
    print("|cff00ccff[MinimapOrganizer]|r " .. tostring(msg))
end

-- Debug print (only when debug mode is on)
function MO.Utils.Debug(msg)
    if MO.db and MO.db.debug then
        print("|cffff9900[MO Debug]|r " .. tostring(msg))
    end
end

-- Generate a unique order number for new categories
function MO.Utils.GetNextCategoryOrder()
    local maxOrder = 0
    if MO.db and MO.db.categories then
        for _, data in pairs(MO.db.categories) do
            if data.order and data.order > maxOrder then
                maxOrder = data.order
            end
        end
    end
    return maxOrder + 1
end

-- Generate a random pastel color for new categories
function MO.Utils.RandomCategoryColor()
    return {
        0.4 + math.random() * 0.4,
        0.4 + math.random() * 0.4,
        0.4 + math.random() * 0.4,
    }
end

-- Get the addon name from LibDBIcon registry if available
function MO.Utils.GetAddonFromLibDBIcon(frameName)
    -- LibDBIcon stores buttons in LibStub("LibDBIcon-1.0").objects
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LDBIcon and LDBIcon.objects then
        for name, button in pairs(LDBIcon.objects) do
            if button:GetName() == frameName then
                return name  -- This is the registered addon/data broker name
            end
        end
    end
    return nil
end

-- Get addon metadata (title) from TOC file
function MO.Utils.GetAddonTitle(addonName)
    if addonName and C_AddOns and C_AddOns.GetAddOnMetadata then
        local title = C_AddOns.GetAddOnMetadata(addonName, "Title")
        if title then
            -- Strip color codes from title
            return title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        end
    end
    return nil
end

-- Get a friendly display name for an addon based on its frame name
function MO.Utils.GetAddonDisplayName(frameName)
    if not frameName then return "Unknown" end

    -- Method 1: Query LibDBIcon registry (most reliable for modern addons)
    local ldbName = MO.Utils.GetAddonFromLibDBIcon(frameName)
    if ldbName then
        -- Try to get the addon's Title from TOC metadata
        local title = MO.Utils.GetAddonTitle(ldbName)
        if title then
            return title
        end
        return ldbName  -- Fallback to the registered name
    end

    -- Method 2: Try to extract addon name from frame name and get TOC title
    local addonGuess = frameName:match("^([^_]+)") or frameName:gsub("MinimapButton$", "")
    local title = MO.Utils.GetAddonTitle(addonGuess)
    if title then
        return title
    end

    -- Method 3: Clean up the frame name as fallback
    local cleaned = frameName:gsub("MinimapButton$", "")
                             :gsub("_MinimapButton$", "")
                             :gsub("Minimap$", "")
                             :gsub("_Minimap$", "")
                             :gsub("Button$", "")
                             :gsub("_Button$", "")
                             :gsub("^Lib", "")

    -- Add spaces before capitals: "MyAddon" -> "My Addon"
    cleaned = cleaned:gsub("(%l)(%u)", "%1 %2")

    -- Remove underscores and extra spaces
    cleaned = cleaned:gsub("_", " "):gsub("%s+", " ")
    cleaned = cleaned:match("^%s*(.-)%s*$") or cleaned  -- trim

    if cleaned ~= "" then
        return cleaned
    end

    return frameName  -- Fallback to raw name
end
