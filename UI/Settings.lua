local ADDON_NAME, MO = ...

MO.Settings = {}

local Settings = MO.Settings
local category = nil

-- Initialize settings panel
function Settings:Initialize()
    self:RegisterSettings()
    MO.Utils.Debug("Settings initialized")
end

-- Open the settings panel
function Settings:Open()
    if category then
        _G.Settings.OpenToCategory(category:GetID())
    end
end

-- Register all settings with the modern Settings API
function Settings:RegisterSettings()
    local L = MO.L

    -- Create the main category
    category = _G.Settings.RegisterVerticalLayoutCategory("MinimapOrganizer")

    -- ==========================================
    -- MINIMAP BUTTON SECTION
    -- ==========================================

    -- Header (using a spacer approach since headers are complex in the new API)
    local function AddSpacer()
        local spacerData = _G.Settings.CreateControlTextContainer()
        spacerData:Add(1, " ")
    end

    -- Hide Minimap Button
    do
        local variable = "MinimapOrganizer_HideMinimapButton"
        local name = L.SETTINGS_HIDE_MINIMAP_BUTTON
        local tooltip = L.SETTINGS_HIDE_MINIMAP_BUTTON_TOOLTIP
        local defaultValue = false

        local function GetValue()
            return MO.db.minimapButton.hide
        end

        local function SetValue(value)
            MO.db.minimapButton.hide = value
            MO.MinimapButton:UpdateVisibility()
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        _G.Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Lock Minimap Button Position
    do
        local variable = "MinimapOrganizer_LockMinimapButton"
        local name = L.SETTINGS_LOCK_MINIMAP_BUTTON
        local tooltip = L.SETTINGS_LOCK_MINIMAP_BUTTON_TOOLTIP
        local defaultValue = false

        local function GetValue()
            return MO.db.minimapButton.lock
        end

        local function SetValue(value)
            MO.db.minimapButton.lock = value
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        _G.Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- ==========================================
    -- WINDOW SECTION
    -- ==========================================

    -- Buttons Per Row
    do
        local variable = "MinimapOrganizer_ButtonsPerRow"
        local name = L.SETTINGS_BUTTONS_PER_ROW
        local tooltip = L.SETTINGS_BUTTONS_PER_ROW_TOOLTIP
        local defaultValue = 8
        local minValue = 4
        local maxValue = 16
        local step = 1

        local function GetValue()
            return MO.db.window.buttonsPerRow
        end

        local function SetValue(value)
            MO.db.window.buttonsPerRow = value
            if MO.CollectionWindow:IsShown() then
                MO.CollectionWindow:RefreshLayout()
            end
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Number, name, defaultValue, GetValue, SetValue)
        local options = _G.Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        _G.Settings.CreateSlider(category, setting, options, tooltip)
    end

    -- Button Size
    do
        local variable = "MinimapOrganizer_ButtonSize"
        local name = L.SETTINGS_BUTTON_SIZE
        local tooltip = L.SETTINGS_BUTTON_SIZE_TOOLTIP
        local defaultValue = 32
        local minValue = 24
        local maxValue = 48
        local step = 2

        local function GetValue()
            return MO.db.window.buttonSize
        end

        local function SetValue(value)
            MO.db.window.buttonSize = value
            if MO.CollectionWindow:IsShown() then
                MO.CollectionWindow:RefreshLayout()
            end
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Number, name, defaultValue, GetValue, SetValue)
        local options = _G.Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        _G.Settings.CreateSlider(category, setting, options, tooltip)
    end

    -- Window Scale
    do
        local variable = "MinimapOrganizer_WindowScale"
        local name = L.SETTINGS_WINDOW_SCALE
        local tooltip = L.SETTINGS_WINDOW_SCALE_TOOLTIP
        local defaultValue = 1.0
        local minValue = 0.5
        local maxValue = 2.0
        local step = 0.1

        local function GetValue()
            return MO.db.window.scale
        end

        local function SetValue(value)
            MO.db.window.scale = value
            MO.CollectionWindow:UpdateScale()
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Number, name, defaultValue, GetValue, SetValue)
        local options = _G.Settings.CreateSliderOptions(minValue, maxValue, step)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            return string.format("%.1fx", value)
        end)
        _G.Settings.CreateSlider(category, setting, options, tooltip)
    end

    -- Close on Button Click
    do
        local variable = "MinimapOrganizer_CloseOnClick"
        local name = L.SETTINGS_CLOSE_ON_CLICK
        local tooltip = L.SETTINGS_CLOSE_ON_CLICK_TOOLTIP
        local defaultValue = false

        local function GetValue()
            return MO.db.window.closeOnClick
        end

        local function SetValue(value)
            MO.db.window.closeOnClick = value
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        _G.Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Sort Method
    do
        local variable = "MinimapOrganizer_SortMethod"
        local name = L.SETTINGS_SORT_METHOD
        local tooltip = L.SETTINGS_SORT_METHOD_TOOLTIP

        local function GetOptions()
            local container = _G.Settings.CreateControlTextContainer()
            container:Add("alphabetical", L.SORT_ALPHABETICAL)
            container:Add("category", L.SORT_CATEGORY)
            return container:GetData()
        end

        local function GetValue()
            return MO.db.sortMethod
        end

        local function SetValue(value)
            MO.db.sortMethod = value
            if MO.CollectionWindow:IsShown() then
                MO.CollectionWindow:RefreshLayout()
            end
        end

        local defaultValue = "alphabetical"
        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.String, name, defaultValue, GetValue, SetValue)
        _G.Settings.CreateDropdown(category, setting, GetOptions, tooltip)
    end

    -- ==========================================
    -- BEHAVIOR SECTION
    -- ==========================================

    -- Auto-Collect New Buttons
    do
        local variable = "MinimapOrganizer_AutoCollect"
        local name = L.SETTINGS_AUTO_COLLECT
        local tooltip = L.SETTINGS_AUTO_COLLECT_TOOLTIP
        local defaultValue = true

        local function GetValue()
            return MO.db.autoCollect
        end

        local function SetValue(value)
            MO.db.autoCollect = value
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        _G.Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Show Favorites First
    do
        local variable = "MinimapOrganizer_ShowFavoritesFirst"
        local name = L.SETTINGS_SHOW_FAVORITES_FIRST
        local tooltip = L.SETTINGS_SHOW_FAVORITES_FIRST_TOOLTIP
        local defaultValue = true

        local function GetValue()
            return MO.db.showFavoritesFirst
        end

        local function SetValue(value)
            MO.db.showFavoritesFirst = value
            if MO.CollectionWindow:IsShown() then
                MO.CollectionWindow:RefreshLayout()
            end
        end

        local setting = _G.Settings.RegisterProxySetting(category, variable,
            _G.Settings.VarType.Boolean, name, defaultValue, GetValue, SetValue)
        _G.Settings.CreateCheckbox(category, setting, tooltip)
    end

    -- Register the category
    _G.Settings.RegisterAddOnCategory(category)

    -- Create Category Management subcategory
    self:CreateCategoryManagementPanel(category)

    MO.Utils.Debug("Settings registered")
end

-- Create a subcategory for managing categories
function Settings:CreateCategoryManagementPanel(parentCategory)
    local L = MO.L

    -- Create a canvas frame for custom UI
    local frame = CreateFrame("Frame")
    frame:SetSize(600, 400)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(L.SETTINGS_MANAGE_CATEGORIES)

    -- Description
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText(L.SETTINGS_MANAGE_CATEGORIES_DESC)
    desc:SetWidth(550)
    desc:SetJustifyH("LEFT")

    -- Scroll frame for category list
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    scrollFrame:SetSize(550, 280)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(530, 1)
    scrollFrame:SetScrollChild(scrollChild)

    frame.scrollChild = scrollChild
    frame.categoryRows = {}

    -- Refresh function
    local function RefreshCategoryList()
        -- Hide existing rows
        for _, row in pairs(frame.categoryRows) do
            row:Hide()
        end

        local categories = MO.ButtonManager:GetCategories()
        local yOffset = 0

        for i, cat in ipairs(categories) do
            local row = frame.categoryRows[i]
            if not row then
                row = CreateFrame("Frame", nil, scrollChild)
                row:SetSize(520, 28)

                -- Category name
                row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                row.nameText:SetPoint("LEFT", 8, 0)
                row.nameText:SetWidth(200)
                row.nameText:SetJustifyH("LEFT")

                -- Button count
                row.countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                row.countText:SetPoint("LEFT", row.nameText, "RIGHT", 16, 0)
                row.countText:SetWidth(100)

                -- Delete button (trashcan icon)
                row.deleteBtn = CreateFrame("Button", nil, row)
                row.deleteBtn:SetSize(22, 22)
                row.deleteBtn:SetPoint("RIGHT", -8, 0)

                local trashIcon = row.deleteBtn:CreateTexture(nil, "ARTWORK")
                trashIcon:SetAllPoints()
                trashIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                row.deleteBtn.icon = trashIcon

                row.deleteBtn:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight", "ADD")

                row.deleteBtn:SetScript("OnEnter", function(self)
                    self.icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
                end)
                row.deleteBtn:SetScript("OnLeave", function(self)
                    self.icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                end)

                -- Background for alternating rows
                row.bg = row:CreateTexture(nil, "BACKGROUND")
                row.bg:SetAllPoints()

                frame.categoryRows[i] = row
            end

            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            row.nameText:SetText(cat.name)

            -- Count buttons in this category
            local count = 0
            for _, btnCat in pairs(MO.db.buttonCategories) do
                if btnCat == cat.name then
                    count = count + 1
                end
            end
            row.countText:SetText(count .. " " .. (L.BUTTONS or "buttons"))

            -- Alternating background
            if i % 2 == 0 then
                row.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
            else
                row.bg:SetColorTexture(0, 0, 0, 0)
            end

            -- Disable delete for Uncategorized
            if cat.name == "Uncategorized" then
                row.deleteBtn:Disable()
                row.deleteBtn:SetAlpha(0.5)
            else
                row.deleteBtn:Enable()
                row.deleteBtn:SetAlpha(1)
                row.deleteBtn:SetScript("OnClick", function()
                    StaticPopupDialogs["MINIMAPORGANIZER_DELETE_CATEGORY"] = {
                        text = string.format(L.DIALOG_DELETE_CATEGORY_CONFIRM, cat.name),
                        button1 = L.DIALOG_ACCEPT,
                        button2 = L.DIALOG_CANCEL,
                        OnAccept = function()
                            MO.ButtonManager:DeleteCategory(cat.name)
                            RefreshCategoryList()
                        end,
                        timeout = 0,
                        whileDead = true,
                        hideOnEscape = true,
                    }
                    StaticPopup_Show("MINIMAPORGANIZER_DELETE_CATEGORY")
                end)
            end

            row:Show()
            yOffset = yOffset + 30
        end

        scrollChild:SetHeight(math.max(yOffset, 100))
    end

    -- Add New Category button
    local addBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    addBtn:SetSize(150, 24)
    addBtn:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 0, -8)
    addBtn:SetText(L.NEW_CATEGORY)
    addBtn:SetScript("OnClick", function()
        MO.CollectionWindow:ShowNewCategoryDialog(nil)
        -- Delay refresh to allow dialog to complete
        C_Timer.After(0.5, RefreshCategoryList)
    end)

    -- Refresh on show
    frame:SetScript("OnShow", RefreshCategoryList)

    -- Register as subcategory
    local subcategory = _G.Settings.RegisterCanvasLayoutSubcategory(parentCategory, frame, L.SETTINGS_MANAGE_CATEGORIES or "Manage Categories")
    subcategory.OnCommit = function() end
    subcategory.OnDefault = function() end
    subcategory.OnRefresh = function() end
end
