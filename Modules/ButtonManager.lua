local ADDON_NAME, MO = ...

MO.ButtonManager = {}

local ButtonManager = MO.ButtonManager

-- Collect a button (hide from minimap, add to collection)
function ButtonManager:CollectButton(name)
    local frame = _G[name]
    if not frame or not frame._mo then
        MO.Utils.Debug("Cannot collect button (not hooked): " .. tostring(name))
        return false
    end

    MO.Utils.Debug("Collecting button: " .. name)

    -- Add to collected, remove from excluded
    MO.db.collectedButtons[name] = true
    MO.db.excludedButtons[name] = nil

    -- Assign to Uncategorized if no category
    if not MO.db.buttonCategories[name] then
        MO.db.buttonCategories[name] = "Uncategorized"
    end

    -- Hide the button from minimap
    frame._mo.oHide(frame)

    -- Refresh the collection window if visible
    if MO.CollectionWindow:IsShown() then
        MO.CollectionWindow:RefreshLayout()
    end

    return true
end

-- Release a button back to the minimap
function ButtonManager:ReleaseButton(name)
    local frame = _G[name]
    if not frame or not frame._mo then
        MO.Utils.Debug("Cannot release button (not hooked): " .. tostring(name))
        return false
    end

    MO.Utils.Debug("Releasing button: " .. name)

    -- Remove from collected, add to excluded
    MO.db.collectedButtons[name] = nil
    MO.db.excludedButtons[name] = true

    -- Restore original position
    frame._mo.oClearAllPoints(frame)
    local pt = frame._mo.oPoint
    if pt and pt[1] then
        frame._mo.oSetPoint(frame, pt[1], pt[2], pt[3], pt[4], pt[5])
    else
        -- Fallback position
        frame._mo.oSetPoint(frame, "CENTER", Minimap, "CENTER", 0, 0)
    end

    -- Restore original size
    local size = frame._mo.oSize
    if size and size[1] and size[2] then
        frame:SetWidth(size[1])
        frame:SetHeight(size[2])
    end

    -- Restore original alpha
    if frame._mo.oAlpha then
        frame:SetAlpha(frame._mo.oAlpha)
    end

    -- Re-enable mouse interaction on the button
    frame:EnableMouse(true)

    -- Reparent back to minimap
    frame:SetParent(Minimap)

    -- Show the button if it was visible
    if frame._mo.isVisible then
        frame._mo.oShow(frame)
    end

    -- Refresh the collection window if visible
    if MO.CollectionWindow:IsShown() then
        MO.CollectionWindow:RefreshLayout()
    end

    return true
end

-- Toggle a button between collected and released
function ButtonManager:ToggleButton(name)
    if MO.db.collectedButtons[name] then
        return self:ReleaseButton(name)
    else
        return self:CollectButton(name)
    end
end

-- Set the category for a button
function ButtonManager:SetCategory(name, categoryName)
    if not MO.db.categories[categoryName] then
        MO.Utils.Debug("Category does not exist: " .. categoryName)
        return false
    end

    MO.db.buttonCategories[name] = categoryName
    MO.Utils.Debug("Set category for " .. name .. " to " .. categoryName)

    if MO.CollectionWindow:IsShown() then
        MO.CollectionWindow:RefreshLayout()
    end

    return true
end

-- Get the category for a button
function ButtonManager:GetCategory(name)
    return MO.db.buttonCategories[name] or "Uncategorized"
end

-- Toggle favorite status for a button
function ButtonManager:ToggleFavorite(name)
    if MO.db.favorites[name] then
        MO.db.favorites[name] = nil
        MO.Utils.Debug("Removed favorite: " .. name)
    else
        MO.db.favorites[name] = true
        MO.Utils.Debug("Added favorite: " .. name)
    end

    if MO.CollectionWindow:IsShown() then
        MO.CollectionWindow:RefreshLayout()
    end
end

-- Check if a button is a favorite
function ButtonManager:IsFavorite(name)
    return MO.db.favorites[name] == true
end

-- Create a new category
function ButtonManager:CreateCategory(name, color)
    if MO.db.categories[name] then
        MO.Utils.Debug("Category already exists: " .. name)
        return false
    end

    MO.db.categories[name] = {
        order = MO.Utils.GetNextCategoryOrder(),
        color = color or MO.Utils.RandomCategoryColor(),
    }

    MO.Utils.Debug("Created category: " .. name)
    return true
end

-- Delete a category (moves buttons to Uncategorized)
function ButtonManager:DeleteCategory(name)
    if name == "Uncategorized" then
        MO.Utils.Debug("Cannot delete Uncategorized category")
        return false
    end

    if not MO.db.categories[name] then
        MO.Utils.Debug("Category does not exist: " .. name)
        return false
    end

    -- Move all buttons in this category to Uncategorized
    for buttonName, categoryName in pairs(MO.db.buttonCategories) do
        if categoryName == name then
            MO.db.buttonCategories[buttonName] = "Uncategorized"
        end
    end

    -- Remove the category
    MO.db.categories[name] = nil

    MO.Utils.Debug("Deleted category: " .. name)

    if MO.CollectionWindow:IsShown() then
        MO.CollectionWindow:RefreshLayout()
    end

    return true
end

-- Rename a category
function ButtonManager:RenameCategory(oldName, newName)
    if oldName == "Uncategorized" then
        MO.Utils.Debug("Cannot rename Uncategorized category")
        return false
    end

    if not MO.db.categories[oldName] then
        MO.Utils.Debug("Category does not exist: " .. oldName)
        return false
    end

    if MO.db.categories[newName] then
        MO.Utils.Debug("Category already exists: " .. newName)
        return false
    end

    -- Copy category data
    MO.db.categories[newName] = MO.db.categories[oldName]
    MO.db.categories[oldName] = nil

    -- Update button assignments
    for buttonName, categoryName in pairs(MO.db.buttonCategories) do
        if categoryName == oldName then
            MO.db.buttonCategories[buttonName] = newName
        end
    end

    MO.Utils.Debug("Renamed category: " .. oldName .. " -> " .. newName)
    return true
end

-- Get sorted list of buttons for display
function ButtonManager:GetSortedButtons(filterCategory)
    local buttons = {}

    -- Gather all collected buttons that are visible
    for buttonName in pairs(MO.db.collectedButtons) do
        local frame = _G[buttonName]
        if frame and frame._mo then
            -- Check visibility - include if the addon considers it visible
            if frame._mo.isVisible then
                local category = MO.db.buttonCategories[buttonName] or "Uncategorized"

                -- Apply category filter if specified
                if not filterCategory or filterCategory == "All" or category == filterCategory then
                    table.insert(buttons, {
                        name = buttonName,
                        frame = frame,
                        category = category,
                        isFavorite = MO.db.favorites[buttonName] == true,
                        categoryOrder = MO.db.categories[category] and MO.db.categories[category].order or 999,
                    })
                end
            end
        end
    end

    -- Sort based on settings
    table.sort(buttons, function(a, b)
        -- Favorites first (if enabled)
        if MO.db.showFavoritesFirst then
            if a.isFavorite and not b.isFavorite then return true end
            if b.isFavorite and not a.isFavorite then return false end
        end

        -- Then by sort method
        if MO.db.sortMethod == "category" then
            if a.categoryOrder ~= b.categoryOrder then
                return a.categoryOrder < b.categoryOrder
            end
        end

        -- Finally alphabetical by name
        return a.name < b.name
    end)

    return buttons
end

-- Get list of all categories (sorted by order)
function ButtonManager:GetCategories()
    local categories = {}

    for name, data in pairs(MO.db.categories) do
        table.insert(categories, {
            name = name,
            order = data.order,
            color = data.color,
        })
    end

    table.sort(categories, function(a, b)
        return a.order < b.order
    end)

    return categories
end
