local ADDON_NAME, MO = ...

MO.CollectionWindow = {}

local CollectionWindow = MO.CollectionWindow
local mainWindow = nil
local buttonSlots = {}
local categoryFilter = "All"
local searchFilter = ""
local headerFrames = {}
local HEADER_HEIGHT = 20
local manageMode = false

-- Minimum widths for top-row controls, used to enforce a floor on window
-- content width so search + filter don't overlap on narrow layouts.
local FILTER_BTN_WIDTH = 22
local SEARCH_BOX_MIN = 120
-- Horizontal inset from the frame edge to the content area. ButtonFrameTemplate
-- has ~6px of chrome inset on each side; SIDE_INSET adds visible breathing
-- room so headers, buttons, search box, and filter all line up consistently.
local SIDE_INSET = 16

-- Initialize the collection window
function CollectionWindow:Initialize()
    self:CreateWindow()
    MO.Utils.Debug("CollectionWindow initialized")
end

-- Apply the current theme via the Skins module.
function CollectionWindow:ApplyTheme()
    if mainWindow and MO.Skins then
        MO.Skins:Apply(mainWindow, MO.db.window.theme)
    end
end

-- Kept as a no-op so any older Settings callers still work.
function CollectionWindow:UpdateOpacity() end

-- Create the main window (Blizzard modern portrait-style panel)
function CollectionWindow:CreateWindow()
    -- Main frame uses ButtonFrameTemplate for the modern portrait-header look.
    -- Portrait and footer button-bar are hidden for the clean minimalist chrome.
    mainWindow = CreateFrame("Frame", "MinimapOrganizer_CollectionWindow", UIParent, "ButtonFrameTemplate")
    mainWindow:SetPoint(MO.db.window.point, UIParent, MO.db.window.relativePoint, MO.db.window.x, MO.db.window.y)
    mainWindow:SetScale(MO.db.window.scale)
    mainWindow:SetMovable(true)
    mainWindow:SetClampedToScreen(true)
    mainWindow:EnableMouse(true)
    mainWindow:SetFrameStrata("MEDIUM")
    mainWindow:SetFrameLevel(100)
    mainWindow:Hide()

    if ButtonFrameTemplate_HidePortrait then
        ButtonFrameTemplate_HidePortrait(mainWindow)
    end
    if ButtonFrameTemplate_HideButtonBar then
        ButtonFrameTemplate_HideButtonBar(mainWindow)
    end
    if mainWindow.Inset then
        mainWindow.Inset:Hide()
    end

    -- Flat title fill used when a theme hides the beveled border art (Minimal).
    -- Inset 6px on each side to match ButtonFrameTemplate's chrome inset,
    -- so the strip lines up with frame.Bg's left/right extent.
    local titleStrip = mainWindow:CreateTexture(nil, "BORDER")
    titleStrip:SetColorTexture(1, 1, 1, 1)
    titleStrip:SetPoint("TOPLEFT", 7, 0)
    titleStrip:SetPoint("TOPRIGHT", -7, 0)
    titleStrip:SetHeight(24)
    titleStrip:Hide()
    mainWindow.minimalTitleStrip = titleStrip

    -- Whole-frame drag (template already reserves the top strip for header art)
    mainWindow:RegisterForDrag("LeftButton")
    mainWindow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainWindow:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        CollectionWindow:SavePosition()
    end)

    -- Title
    if mainWindow.SetTitle then
        mainWindow:SetTitle(MO.L.WINDOW_TITLE)
    elseif mainWindow.TitleText then
        mainWindow.TitleText:SetText(MO.L.WINDOW_TITLE)
    end

    -- Escape to close
    tinsert(UISpecialFrames, "MinimapOrganizer_CollectionWindow")

    -- Close button — HookScript preserves the template's default (which plays
    -- the standard close sound); our hook runs the cleanup after.
    if mainWindow.CloseButton then
        mainWindow.CloseButton:HookScript("OnClick", function()
            CollectionWindow:Hide()
        end)
    end

    -- Manage mode gear button (sits immediately left of the built-in close X)
    self:CreateManageButton(mainWindow)

    -- Search box (LEFT side of top row)
    self:CreateSearchBox(mainWindow)

    -- Category filter (RIGHT side of top row) — icon-only DropdownButton
    self:CreateCategoryDropdown(mainWindow)

    -- Content area (where buttons go)
    local content = CreateFrame("Frame", nil, mainWindow)
    content:SetPoint("TOPLEFT", SIDE_INSET, -58)
    content:SetPoint("BOTTOMRIGHT", -SIDE_INSET, SIDE_INSET)
    mainWindow.content = content

    self.mainWindow = mainWindow

    -- Apply theme + initial top-row visibility
    self:ApplyTheme()
    self:UpdateTopRowVisibility()
end

-- Create the settings/manage button — Plumber-style plain button (no template,
-- no chrome), just an icon overlay with alpha + press-offset feedback. Opens
-- a small menu with Manage Mode toggle and a link to the WoW settings panel.
function CollectionWindow:CreateManageButton(parent)
    local manageBtn = CreateFrame("DropdownButton", nil, parent)
    manageBtn:SetSize(22, 22)
    if parent.CloseButton then
        manageBtn:SetPoint("RIGHT", parent.CloseButton, "LEFT", -2, 0)
        manageBtn:SetFrameLevel(parent.CloseButton:GetFrameLevel() + 1)
    else
        manageBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -28, -3)
    end

    -- Shipped anti-aliased gear (64x64 PNG). Tinted warm off-white to match
    -- the muted filter icon on the row below. Slightly smaller than the
    -- 22x22 button and offset a hair to give breathing room from the title
    -- bar boundary.
    local gear = manageBtn:CreateTexture(nil, "OVERLAY")
    gear:SetSize(15, 15)
    gear:SetPoint("CENTER", 0, 0)
    gear:SetTexture("Interface\\AddOns\\MinimapOrganizer\\Assets\\SettingsIcon.png")
    gear:SetVertexColor(0.85, 0.8, 0.65)
    gear:SetAlpha(0.67)
    manageBtn.icon = gear

    manageBtn:SetupMenu(function(menu, rootDescription)
        rootDescription:CreateCheckbox(
            MO.L.MANAGE_MODE,
            function() return manageMode end,
            function() CollectionWindow:ToggleManageMode() end
        )
        rootDescription:CreateDivider()
        rootDescription:CreateButton(MO.L.SETTINGS or "Settings...", function()
            MO.Settings:Open()
        end)
    end)

    manageBtn:HookScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(MO.L.SETTINGS_MENU or "Options", 1, 1, 1)
        GameTooltip:Show()
    end)
    manageBtn:HookScript("OnLeave", function(self)
        self.icon:SetAlpha(manageMode and 1 or 0.67)
        GameTooltip:Hide()
    end)
    manageBtn:HookScript("OnMouseDown", function(self)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("CENTER", 1, -1)
    end)
    manageBtn:HookScript("OnMouseUp", function(self)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("CENTER")
    end)

    mainWindow.manageBtn = manageBtn
end

-- Create category filter — Plumber-style plain button on the top-row right,
-- shipping our own filter icon (three sliders + knobs). No template/chrome;
-- icon alpha lifts on hover and offsets by 1px on press.
function CollectionWindow:CreateCategoryDropdown(parent)
    local dropdown = CreateFrame("DropdownButton", "MinimapOrganizer_CategoryDropdown", parent)
    dropdown:SetSize(22, 22)
    dropdown:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -SIDE_INSET, -26)

    -- Shipped funnel icon (64x64 anti-aliased PNG), warm muted tint
    local icon = dropdown:CreateTexture(nil, "OVERLAY")
    icon:SetSize(16, 16)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\AddOns\\MinimapOrganizer\\Assets\\FilterIcon.png")
    icon:SetVertexColor(0.75, 0.7, 0.55)
    icon:SetAlpha(0.67)
    dropdown.icon = icon

    local function IsSelected(value)
        return categoryFilter == value
    end
    local function SetSelected(value)
        categoryFilter = value
        CollectionWindow:RefreshLayout()
    end

    dropdown:SetupMenu(function(menu, rootDescription)
        rootDescription:CreateRadio(MO.L.ALL_CATEGORIES, IsSelected, SetSelected, "All")
        rootDescription:CreateRadio("|cffffd200" .. MO.L.FAVORITES .. "|r", IsSelected, SetSelected, "__favorites__")
        rootDescription:CreateDivider()

        local categories = MO.ButtonManager:GetCategories()
        for _, cat in ipairs(categories) do
            local color = string.format("|cff%02x%02x%02x",
                math.floor(cat.color[1] * 255),
                math.floor(cat.color[2] * 255),
                math.floor(cat.color[3] * 255))
            rootDescription:CreateRadio(color .. cat.name .. "|r", IsSelected, SetSelected, cat.name)
        end
    end)

    dropdown:HookScript("OnEnter", function(self)
        self.icon:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(MO.L.FILTER_BY_CATEGORY or "Filter by Category", 1, 1, 1)
        local current
        if categoryFilter == "All" then
            current = MO.L.ALL_CATEGORIES
        elseif categoryFilter == "__favorites__" then
            current = MO.L.FAVORITES
        else
            current = categoryFilter
        end
        GameTooltip:AddLine(current, 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    dropdown:HookScript("OnLeave", function(self)
        self.icon:SetAlpha(0.67)
        GameTooltip:Hide()
    end)
    dropdown:HookScript("OnMouseDown", function(self)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("CENTER", 1, -1)
    end)
    dropdown:HookScript("OnMouseUp", function(self)
        self.icon:ClearAllPoints()
        self.icon:SetPoint("CENTER")
    end)

    mainWindow.categoryDropdown = dropdown
end

-- Create search box (top row, LEFT side, matches 22px height of icon buttons).
-- The right edge is set in UpdateTopRowVisibility depending on whether the
-- category filter button is visible.
function CollectionWindow:CreateSearchBox(parent)
    local searchBox = CreateFrame("EditBox", "MinimapOrganizer_SearchBox", parent, "SearchBoxTemplate")
    searchBox:SetHeight(22)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(64)

    -- SearchBoxTemplate ships with a "Search" placeholder; override for locale
    if searchBox.Instructions then
        searchBox.Instructions:SetText(MO.L.SEARCH_PLACEHOLDER)
    end

    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if SearchBoxTemplate_OnTextChanged then
            SearchBoxTemplate_OnTextChanged(self)
        end
        searchFilter = self:GetText() or ""
        if mainWindow and mainWindow:IsShown() then
            CollectionWindow:RefreshLayout()
        end
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)

    mainWindow.searchBox = searchBox
end

-- Update top-row control visibility. Search box + category filter are
-- toggled together via a single hideTopRow setting.
function CollectionWindow:UpdateTopRowVisibility()
    if not mainWindow then return end

    local hide = MO.db.window.hideTopRow

    if hide then
        mainWindow.categoryDropdown:Hide()
        mainWindow.searchBox:Hide()
        categoryFilter = "All"
        searchFilter = ""
        mainWindow.searchBox:SetText("")
        mainWindow.content:SetPoint("TOPLEFT", SIDE_INSET, -32)
    else
        mainWindow.categoryDropdown:Show()
        mainWindow.searchBox:Show()
        mainWindow.searchBox:ClearAllPoints()
        -- Left edge aligns with the header divider lines (content.LEFT + 4)
        mainWindow.searchBox:SetPoint("TOPLEFT", mainWindow, "TOPLEFT", SIDE_INSET + 4, -26)
        mainWindow.searchBox:SetPoint("RIGHT", mainWindow.categoryDropdown, "LEFT", -6, 0)
        mainWindow.content:SetPoint("TOPLEFT", SIDE_INSET, -58)
    end

    if mainWindow:IsShown() then
        self:RefreshLayout()
    end
end

-- Toggle manage mode. Tint the gear gold while manage mode is active so
-- it's obvious the collection is in a special state; otherwise restore the
-- resting warm off-white tint.
function CollectionWindow:ToggleManageMode()
    manageMode = not manageMode

    if mainWindow and mainWindow.manageBtn and mainWindow.manageBtn.icon then
        if manageMode then
            mainWindow.manageBtn.icon:SetVertexColor(1, 0.82, 0)
        else
            mainWindow.manageBtn.icon:SetVertexColor(0.85, 0.8, 0.65)
        end
    end
end

-- Check if manage mode is active
function CollectionWindow:IsManageMode()
    return manageMode
end

-- Get or create a category header
local function GetOrCreateHeader(index, parent)
    if headerFrames[index] then
        return headerFrames[index]
    end

    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(HEADER_HEIGHT)

    -- Category name (create first so lines can anchor to it)
    local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", 0, 0)
    header.text = text

    -- Left line (anchored to text) — color is set per-header to match the section
    local leftLine = header:CreateTexture(nil, "ARTWORK")
    leftLine:SetHeight(1)
    leftLine:SetPoint("LEFT", 4, 0)
    leftLine:SetPoint("RIGHT", text, "LEFT", -8, 0)
    header.leftLine = leftLine

    -- Right line (anchored to text)
    local rightLine = header:CreateTexture(nil, "ARTWORK")
    rightLine:SetHeight(1)
    rightLine:SetPoint("LEFT", text, "RIGHT", 8, 0)
    rightLine:SetPoint("RIGHT", -4, 0)
    header.rightLine = rightLine

    headerFrames[index] = header
    return header
end

-- Refresh the button layout
function CollectionWindow:RefreshLayout()
    if not mainWindow or not mainWindow:IsShown() then return end

    local opts = MO.db.window
    local topRowVisible = not opts.hideTopRow
    -- Content anchor: TOPLEFT (SIDE_INSET, -58 or -32) + BOTTOMRIGHT
    -- (-SIDE_INSET, SIDE_INSET). Vertical chrome = 58+SIDE_INSET or 32+SIDE_INSET.
    local heightPadding = topRowVisible and (58 + SIDE_INSET) or (32 + SIDE_INSET)
    local buttons, categoryBreaks = MO.ButtonManager:GetSortedButtons(categoryFilter, searchFilter)
    local content = mainWindow.content

    -- Hide all existing slots first
    for _, slot in ipairs(buttonSlots) do
        slot:Hide()
        slot:ClearAllPoints()
        if slot.buttonFrame then
            slot.buttonFrame._mo.oHide(slot.buttonFrame)
            slot.buttonFrame = nil
        end
    end

    -- Hide all headers
    for _, header in pairs(headerFrames) do
        header:Hide()
    end

    -- Calculate layout
    local perRow = opts.buttonsPerRow
    local size = opts.buttonSize
    local spacing = opts.buttonSpacing
    local showHeaders = (categoryFilter == "All") and (MO.db.sortMethod == "category") and next(categoryBreaks)

    local buttonCount = #buttons
    local cols = math.min(buttonCount, perRow)

    -- Calculate content width
    local contentWidth = cols * (size + spacing) - spacing
    contentWidth = math.max(contentWidth, 150)

    -- Make sure the top row fits its visible controls (search + filter btn)
    if topRowVisible then
        local topRowMin = SEARCH_BOX_MIN + 6 + FILTER_BTN_WIDTH
        if topRowMin > contentWidth then
            contentWidth = topRowMin
        end
    end

    if showHeaders then
        -- Calculate positions accounting for headers
        local yOffset = 0
        local headerCount = 0
        local buttonIndex = 0

        for i, btnData in ipairs(buttons) do
            -- Insert header if needed
            if categoryBreaks[i] then
                -- Close out previous category - add height for all rows used
                if buttonIndex > 0 then
                    local rowsUsed = math.ceil(buttonIndex / perRow)
                    yOffset = yOffset + rowsUsed * (size + spacing)
                end

                headerCount = headerCount + 1
                local header = GetOrCreateHeader(headerCount, content)
                header:SetWidth(contentWidth)
                header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
                header.text:SetText(categoryBreaks[i])

                local catData = MO.db.categories[categoryBreaks[i]]
                local r, g, b
                if catData and catData.color then
                    r, g, b = catData.color[1], catData.color[2], catData.color[3]
                else
                    -- Favorites section (or no category data) — soft gold
                    r, g, b = 1, 0.82, 0
                end
                header.text:SetTextColor(r, g, b)
                header.leftLine:SetColorTexture(r, g, b, 0.55)
                header.rightLine:SetColorTexture(r, g, b, 0.55)

                header:Show()
                yOffset = yOffset + HEADER_HEIGHT + 4
                buttonIndex = 0  -- Reset for new category
            end

            -- Position button
            local slot = self:GetOrCreateSlot(i)
            local col = buttonIndex % perRow
            local rowOffset = math.floor(buttonIndex / perRow) * (size + spacing)

            slot:SetSize(size, size)
            slot:SetPoint("TOPLEFT", content, "TOPLEFT",
                col * (size + spacing),
                -(yOffset + rowOffset))

            self:SetupSlot(slot, btnData)
            slot:Show()
            buttonIndex = buttonIndex + 1
        end

        -- Calculate total height - include last category's rows
        local lastCategoryRows = math.max(1, math.ceil(buttonIndex / perRow))
        local contentHeight = yOffset + lastCategoryRows * (size + spacing) - spacing
        contentHeight = math.max(contentHeight, size)

        -- Set window size (SIDE_INSET each side matches content anchor offsets)
        local windowWidth = contentWidth + SIDE_INSET * 2
        local windowHeight = contentHeight + heightPadding
        mainWindow:SetSize(windowWidth, windowHeight)
    else
        -- Standard layout without headers
        local rows = math.max(1, math.ceil(buttonCount / perRow))

        -- Calculate window size
        local contentHeight = rows * (size + spacing) - spacing
        contentHeight = math.max(contentHeight, size)

        -- Set window size (SIDE_INSET each side matches content anchor offsets)
        local windowWidth = contentWidth + SIDE_INSET * 2
        local windowHeight = contentHeight + heightPadding

        mainWindow:SetSize(windowWidth, windowHeight)

        -- Position each button
        for i, btnData in ipairs(buttons) do
            local slot = self:GetOrCreateSlot(i)
            local row = math.floor((i - 1) / perRow)
            local col = (i - 1) % perRow

            slot:SetSize(size, size)
            slot:SetPoint("TOPLEFT", content, "TOPLEFT",
                col * (size + spacing),
                -row * (size + spacing))

            self:SetupSlot(slot, btnData)
            slot:Show()
        end
    end
end

-- Get or create a button slot
function CollectionWindow:GetOrCreateSlot(index)
    if buttonSlots[index] then
        return buttonSlots[index]
    end

    local slot = CreateFrame("Button", "MinimapOrganizer_Slot" .. index, mainWindow.content)
    slot:EnableMouse(true)
    slot:RegisterForClicks("AnyUp")

    -- Favorite indicator: gold star with a black offset-copy drop-shadow behind
    -- it, so the star reads clearly on both dark and bright icons without the
    -- boxy backdrop rectangle.
    local favFrame = CreateFrame("Frame", nil, slot)
    favFrame:SetFrameStrata("HIGH")
    favFrame:SetSize(15, 15)
    favFrame:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 2, 2)
    favFrame:Hide()

    local favShadow = favFrame:CreateTexture(nil, "OVERLAY", nil, 5)
    favShadow:SetPoint("TOPLEFT", 1, -1)
    favShadow:SetPoint("BOTTOMRIGHT", 1, -1)
    favShadow:SetTexture("Interface\\COMMON\\ReputationStar")
    favShadow:SetTexCoord(0, 0.5, 0, 0.5)
    favShadow:SetVertexColor(0, 0, 0, 0.85)

    local favIcon = favFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    favIcon:SetAllPoints()
    favIcon:SetTexture("Interface\\COMMON\\ReputationStar")
    favIcon:SetTexCoord(0, 0.5, 0, 0.5)  -- Top-left quadrant (filled star)
    favIcon:SetVertexColor(1, 0.84, 0)  -- Gold color
    slot.favFrame = favFrame

    -- Highlight on hover
    local highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.22)

    -- Tooltip handler
    slot:SetScript("OnEnter", function(self)
        if not self.buttonData then return end
        local frame = self.buttonData.frame

        if manageMode then
            -- Manage mode: show MO management tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            local displayName = MO.Utils.GetAddonDisplayName(self.buttonData.name)
            GameTooltip:AddLine(displayName, 1, 1, 1)
            GameTooltip:AddLine(MO.L.CATEGORY .. ": " .. self.buttonData.category, 0.7, 0.7, 0.7)
            if self.buttonData.isFavorite then
                GameTooltip:AddLine(MO.L.FAVORITE, 1, 0.84, 0)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(MO.L.TOOLTIP_MANAGE_LEFTCLICK, 0.5, 0.5, 0.5)
            GameTooltip:AddLine(MO.L.TOOLTIP_MANAGE_RIGHTCLICK, 0.5, 0.5, 0.5)
            GameTooltip:Show()
        else
            -- Normal mode: show original button tooltip
            if frame and frame._mo and frame._mo.oOnEnter then
                frame._mo.oOnEnter(frame)
            else
                -- Fallback if no original OnEnter
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local displayName = MO.Utils.GetAddonDisplayName(self.buttonData.name)
                GameTooltip:AddLine(displayName, 1, 1, 1)
                GameTooltip:Show()
            end
        end
    end)

    slot:SetScript("OnLeave", function(self)
        if self.buttonData then
            local frame = self.buttonData.frame
            -- Call original OnLeave for cleanup (highlights, etc.)
            if not manageMode and frame and frame._mo and frame._mo.oOnLeave then
                frame._mo.oOnLeave(frame)
            end
        end
        GameTooltip:Hide()
    end)

    -- Click handler
    slot:SetScript("OnClick", function(self, btn)
        if not self.buttonData then return end
        local frame = self.buttonData.frame

        if manageMode then
            -- Manage mode: MO controls only, no forwarding
            if btn == "LeftButton" then
                MO.ButtonManager:ToggleFavorite(self.buttonData.name)
            elseif btn == "RightButton" then
                CollectionWindow:ShowContextMenu(self)
            end
        else
            -- Normal mode: forward all clicks to the original button
            if not frame or not frame._mo then return end

            local handled = false
            if frame._mo.oOnClick then
                frame._mo.oOnClick(frame, btn)
                handled = true
            end
            if frame._mo.oOnMouseUp then
                frame._mo.oOnMouseUp(frame, btn)
                handled = true
            end
            if not handled and frame._mo.oOnMouseDown then
                frame._mo.oOnMouseDown(frame, btn)
            end

            -- Close window if setting enabled
            if btn == "LeftButton" and MO.db.window.closeOnClick then
                CollectionWindow:Hide()
            end
        end
    end)

    buttonSlots[index] = slot
    return slot
end

-- Helper to fix textures on a frame (recursive for children)
local function FixFrameTextures(frame)
    -- Fix regions (textures) on this frame
    for _, region in pairs({frame:GetRegions()}) do
        if region:IsObjectType("Texture") then
            if region.SetVertexColor then
                region:SetVertexColor(1, 1, 1, 1)
            end
            if region.SetDesaturated then
                region:SetDesaturated(false)
            end
        end
    end

    -- Recursively fix child frames
    for _, child in pairs({frame:GetChildren()}) do
        FixFrameTextures(child)
    end
end

-- Setup a slot with button data
function CollectionWindow:SetupSlot(slot, btnData)
    slot.buttonData = btnData
    slot.buttonFrame = btnData.frame

    local frame = btnData.frame
    local size = MO.db.window.buttonSize

    -- Reparent the actual button frame into the slot
    frame:SetParent(slot)
    frame._mo.oClearAllPoints(frame)
    frame._mo.oSetPoint(frame, "CENTER", slot, "CENTER", 0, 0)
    frame:SetSize(size - 4, size - 4)  -- Slightly smaller to fit in slot
    frame:SetAlpha(1)  -- Force full opacity regardless of addon's settings
    frame:EnableMouse(false)  -- Disable mouse on button - let the slot handle clicks

    -- Reset frame strata/level - LibDBIcon uses fixed strata which can cause issues
    if frame.SetFixedFrameStrata then
        frame:SetFixedFrameStrata(false)
    end
    if frame.SetFixedFrameLevel then
        frame:SetFixedFrameLevel(false)
    end
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(slot:GetFrameLevel() + 5)

    -- Fix dark icons: reset vertex colors and desaturation on all textures
    FixFrameTextures(frame)

    frame._mo.oShow(frame)

    -- Show/hide favorite indicator
    if btnData.isFavorite then
        slot.favFrame:Show()
    else
        slot.favFrame:Hide()
    end
end

-- Show context menu for a slot (using modern MenuUtil API)
function CollectionWindow:ShowContextMenu(slot)
    if not slot.buttonData then return end

    local buttonName = slot.buttonData.name

    MenuUtil.CreateContextMenu(slot, function(ownerRegion, rootDescription)
        -- Title
        rootDescription:CreateTitle(buttonName)

        -- Toggle Favorite
        rootDescription:CreateButton(MO.L.TOGGLE_FAVORITE, function()
            MO.ButtonManager:ToggleFavorite(buttonName)
        end)

        -- Set Category submenu
        local categoryMenu = rootDescription:CreateButton(MO.L.SET_CATEGORY)
        local currentCategory = MO.ButtonManager:GetCategory(buttonName)
        local categories = MO.ButtonManager:GetCategories()

        for _, cat in ipairs(categories) do
            categoryMenu:CreateRadio(cat.name, function()
                return currentCategory == cat.name
            end, function()
                MO.ButtonManager:SetCategory(buttonName, cat.name)
            end)
        end

        categoryMenu:CreateDivider()
        categoryMenu:CreateButton(MO.L.NEW_CATEGORY, function()
            CollectionWindow:ShowNewCategoryDialog(buttonName)
        end)

        -- Divider
        rootDescription:CreateDivider()

        -- Release to Minimap
        rootDescription:CreateButton(MO.L.RELEASE_TO_MINIMAP, function()
            MO.ButtonManager:ReleaseButton(buttonName)
        end)
    end)
end

-- Show dialog to create new category
function CollectionWindow:ShowNewCategoryDialog(buttonName, onComplete)
    StaticPopupDialogs["MINIMAPORGANIZER_NEW_CATEGORY"] = {
        text = MO.L.DIALOG_NEW_CATEGORY_TEXT,
        button1 = MO.L.DIALOG_ACCEPT,
        button2 = MO.L.DIALOG_CANCEL,
        hasEditBox = true,
        editBoxWidth = 200,
        OnAccept = function(self)
            local name = self.EditBox:GetText():trim()
            if name ~= "" then
                MO.ButtonManager:CreateCategory(name)
                if buttonName then
                    MO.ButtonManager:SetCategory(buttonName, name)
                end
                if onComplete then
                    onComplete()
                end
            end
        end,
        OnShow = function(self)
            self.EditBox:SetText("")
            self.EditBox:SetFocus()
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local name = parent.EditBox:GetText():trim()
            if name ~= "" then
                MO.ButtonManager:CreateCategory(name)
                if buttonName then
                    MO.ButtonManager:SetCategory(buttonName, name)
                end
                if onComplete then
                    onComplete()
                end
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopup_Show("MINIMAPORGANIZER_NEW_CATEGORY")
end

-- Save window position
function CollectionWindow:SavePosition()
    local point, _, relativePoint, x, y = mainWindow:GetPoint()
    MO.db.window.point = point
    MO.db.window.relativePoint = relativePoint
    MO.db.window.x = x
    MO.db.window.y = y
end

-- Update position from saved settings
function CollectionWindow:UpdatePosition()
    if mainWindow then
        mainWindow:ClearAllPoints()
        mainWindow:SetPoint(MO.db.window.point, UIParent, MO.db.window.relativePoint, MO.db.window.x, MO.db.window.y)
    end
end

-- Toggle window visibility
function CollectionWindow:Toggle()
    if mainWindow:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Show the window
function CollectionWindow:Show()
    mainWindow:Show()
    self:RefreshLayout()
end

-- Hide the window
function CollectionWindow:Hide()
    -- Reset manage mode when closing
    if manageMode then
        manageMode = false
        if mainWindow.manageBtn and mainWindow.manageBtn.icon then
            mainWindow.manageBtn.icon:SetVertexColor(0.85, 0.8, 0.65)
        end
    end

    mainWindow:Hide()

    -- Re-hide all collected buttons
    for buttonName in pairs(MO.db.collectedButtons) do
        local frame = _G[buttonName]
        if frame and frame._mo then
            frame._mo.oHide(frame)
        end
    end
end

-- Check if window is shown
function CollectionWindow:IsShown()
    return mainWindow and mainWindow:IsShown()
end

-- Update scale
function CollectionWindow:UpdateScale()
    if mainWindow then
        mainWindow:SetScale(MO.db.window.scale)
    end
end
