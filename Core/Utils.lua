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
