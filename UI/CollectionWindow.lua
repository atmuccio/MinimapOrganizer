local ADDON_NAME, MO = ...

MO.CollectionWindow = {}

local CollectionWindow = MO.CollectionWindow
local mainWindow = nil
local buttonSlots = {}
local categoryFilter = "All"
local headerFrames = {}
local HEADER_HEIGHT = 20

-- Backdrop definition
local WINDOW_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileEdge = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

-- Initialize the collection window
function CollectionWindow:Initialize()
    self:CreateWindow()
    MO.Utils.Debug("CollectionWindow initialized")
end

-- Create the main window
function CollectionWindow:CreateWindow()
    -- Main frame
    mainWindow = CreateFrame("Frame", "MinimapOrganizer_CollectionWindow", UIParent, "BackdropTemplate")
    mainWindow:SetPoint(MO.db.window.point, UIParent, MO.db.window.relativePoint, MO.db.window.x, MO.db.window.y)
    mainWindow:SetScale(MO.db.window.scale)
    mainWindow:SetMovable(true)
    mainWindow:SetClampedToScreen(true)
    mainWindow:EnableMouse(true)
    mainWindow:SetFrameStrata("MEDIUM")
    mainWindow:SetFrameLevel(100)
    mainWindow:SetBackdrop(WINDOW_BACKDROP)
    mainWindow:SetBackdropColor(0, 0, 0, 0.9)
    mainWindow:Hide()

    -- Register for escape to close
    tinsert(UISpecialFrames, "MinimapOrganizer_CollectionWindow")

    -- Title bar with backdrop
    local titleBar = CreateFrame("Frame", nil, mainWindow, "BackdropTemplate")
    titleBar:SetHeight(24)
    titleBar:SetPoint("TOPLEFT", 7, -6)
    titleBar:SetPoint("TOPRIGHT", -26, -6)
    titleBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    titleBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    titleBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")

    titleBar:SetScript("OnDragStart", function()
        mainWindow:StartMoving()
    end)

    titleBar:SetScript("OnDragStop", function()
        mainWindow:StopMovingOrSizing()
        CollectionWindow:SavePosition()
    end)

    -- Title text (centered in bar)
    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    title:SetText(MO.L.WINDOW_TITLE)
    mainWindow.title = title
    mainWindow.titleBar = titleBar

    -- Close button
    local closeBtn = CreateFrame("Button", nil, mainWindow, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainWindow, "TOPRIGHT", -5, -6)
    closeBtn:SetScript("OnClick", function()
        CollectionWindow:Hide()
    end)

    -- Category filter dropdown
    self:CreateCategoryDropdown(mainWindow)

    -- Content area (where buttons go)
    local content = CreateFrame("Frame", nil, mainWindow)
    content:SetPoint("TOPLEFT", 16, -60)
    content:SetPoint("BOTTOMRIGHT", -16, 16)
    mainWindow.content = content

    self.mainWindow = mainWindow
end

-- Create category filter dropdown
function CollectionWindow:CreateCategoryDropdown(parent)
    local dropdown = CreateFrame("Frame", "MinimapOrganizer_CategoryDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", 0, -32)

    UIDropDownMenu_SetWidth(dropdown, 120)
    UIDropDownMenu_SetText(dropdown, MO.L.ALL_CATEGORIES)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local info = UIDropDownMenu_CreateInfo()

        -- "All" option
        info.text = MO.L.ALL_CATEGORIES
        info.value = "All"
        info.checked = (categoryFilter == "All")
        info.func = function()
            categoryFilter = "All"
            UIDropDownMenu_SetText(dropdown, MO.L.ALL_CATEGORIES)
            CollectionWindow:RefreshLayout()
        end
        UIDropDownMenu_AddButton(info)

        -- Separator
        info = UIDropDownMenu_CreateInfo()
        info.disabled = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)

        -- Category options
        local categories = MO.ButtonManager:GetCategories()
        for _, cat in ipairs(categories) do
            info = UIDropDownMenu_CreateInfo()
            info.text = cat.name
            info.value = cat.name
            info.checked = (categoryFilter == cat.name)
            info.colorCode = string.format("|cff%02x%02x%02x",
                math.floor(cat.color[1] * 255),
                math.floor(cat.color[2] * 255),
                math.floor(cat.color[3] * 255))
            info.func = function()
                categoryFilter = cat.name
                UIDropDownMenu_SetText(dropdown, cat.name)
                CollectionWindow:RefreshLayout()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    mainWindow.categoryDropdown = dropdown
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

    -- Left line (anchored to text)
    local leftLine = header:CreateTexture(nil, "ARTWORK")
    leftLine:SetHeight(1)
    leftLine:SetPoint("LEFT", 4, 0)
    leftLine:SetPoint("RIGHT", text, "LEFT", -8, 0)
    leftLine:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    header.leftLine = leftLine

    -- Right line (anchored to text)
    local rightLine = header:CreateTexture(nil, "ARTWORK")
    rightLine:SetHeight(1)
    rightLine:SetPoint("LEFT", text, "RIGHT", 8, 0)
    rightLine:SetPoint("RIGHT", -4, 0)
    rightLine:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    header.rightLine = rightLine

    headerFrames[index] = header
    return header
end

-- Refresh the button layout
function CollectionWindow:RefreshLayout()
    if not mainWindow or not mainWindow:IsShown() then return end

    local opts = MO.db.window
    local buttons, categoryBreaks = MO.ButtonManager:GetSortedButtons(categoryFilter)
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
                if catData and catData.color then
                    header.text:SetTextColor(catData.color[1], catData.color[2], catData.color[3])
                else
                    header.text:SetTextColor(0.8, 0.8, 0.8)
                end

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

        -- Set window size
        local windowWidth = contentWidth + 32
        local windowHeight = contentHeight + 72
        mainWindow:SetSize(windowWidth, windowHeight)
    else
        -- Standard layout without headers
        local rows = math.max(1, math.ceil(buttonCount / perRow))

        -- Calculate window size
        local contentHeight = rows * (size + spacing) - spacing
        contentHeight = math.max(contentHeight, size)

        -- Set window size (add padding for title, borders)
        local windowWidth = contentWidth + 32
        local windowHeight = contentHeight + 72  -- Title + dropdown + padding

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

    -- No background - let buttons show at full opacity
    -- The window backdrop provides enough visual context

    -- Favorite indicator (small gold star in top-right corner)
    -- Using a separate frame to ensure it's always on top
    local favFrame = CreateFrame("Frame", nil, slot)
    favFrame:SetFrameStrata("HIGH")
    favFrame:SetSize(14, 14)
    favFrame:SetPoint("TOPRIGHT", slot, "TOPRIGHT", 2, 2)
    favFrame:Hide()

    local favIcon = favFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    favIcon:SetAllPoints()
    favIcon:SetTexture("Interface\\COMMON\\ReputationStar")
    favIcon:SetTexCoord(0, 0.5, 0, 0.5)  -- Top-left quadrant (filled star)
    favIcon:SetVertexColor(1, 0.84, 0)  -- Gold color
    slot.favFrame = favFrame

    -- Highlight on hover (subtle)
    local highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.15)

    -- Tooltip
    slot:SetScript("OnEnter", function(self)
        if self.buttonData then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            -- Show friendly addon name
            local displayName = MO.Utils.GetAddonDisplayName(self.buttonData.name)
            GameTooltip:AddLine(displayName, 1, 1, 1)

            -- Show raw frame name in smaller gray text if different
            if displayName ~= self.buttonData.name then
                GameTooltip:AddLine(self.buttonData.name, 0.5, 0.5, 0.5)
            end

            GameTooltip:AddLine(MO.L.CATEGORY .. ": " .. self.buttonData.category, 0.7, 0.7, 0.7)
            if self.buttonData.isFavorite then
                GameTooltip:AddLine(MO.L.FAVORITE, 1, 0.84, 0)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(MO.L.TOOLTIP_BUTTON_RIGHTCLICK, 0.5, 0.5, 0.5)
            GameTooltip:AddLine(MO.L.TOOLTIP_CTRL_CLICK, 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end
    end)

    slot:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click handler
    slot:SetScript("OnClick", function(self, btn)
        if not self.buttonData then return end

        if btn == "LeftButton" then
            if IsControlKeyDown() then
                -- Ctrl+Click to toggle favorite
                MO.ButtonManager:ToggleFavorite(self.buttonData.name)
            else
                -- Regular click - forward to the actual button
                local frame = self.buttonData.frame
                if frame then
                    -- Try various click handlers
                    local script = frame:GetScript("OnClick")
                    if script then
                        script(frame, btn)
                    end
                end

                -- Close window if setting enabled
                if MO.db.window.closeOnClick then
                    CollectionWindow:Hide()
                end
            end
        elseif btn == "RightButton" then
            -- Show context menu
            CollectionWindow:ShowContextMenu(self)
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
