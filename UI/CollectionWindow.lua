local ADDON_NAME, MO = ...

MO.CollectionWindow = {}

local CollectionWindow = MO.CollectionWindow
local mainWindow = nil
local buttonSlots = {}
local categoryFilter = "All"

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

    -- Title bar (for dragging)
    local titleBar = CreateFrame("Frame", nil, mainWindow)
    titleBar:SetHeight(24)
    titleBar:SetPoint("TOPLEFT", 12, -8)
    titleBar:SetPoint("TOPRIGHT", -28, -8)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")

    titleBar:SetScript("OnDragStart", function()
        mainWindow:StartMoving()
    end)

    titleBar:SetScript("OnDragStop", function()
        mainWindow:StopMovingOrSizing()
        CollectionWindow:SavePosition()
    end)

    -- Title text
    local title = mainWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -12)
    title:SetText(MO.L.WINDOW_TITLE)
    mainWindow.title = title

    -- Close button
    local closeBtn = CreateFrame("Button", nil, mainWindow, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        CollectionWindow:Hide()
    end)

    -- Category filter dropdown
    self:CreateCategoryDropdown(mainWindow)

    -- Content area (where buttons go)
    local content = CreateFrame("Frame", nil, mainWindow)
    content:SetPoint("TOPLEFT", 16, -56)
    content:SetPoint("BOTTOMRIGHT", -16, 16)
    mainWindow.content = content

    self.mainWindow = mainWindow
end

-- Create category filter dropdown
function CollectionWindow:CreateCategoryDropdown(parent)
    local dropdown = CreateFrame("Frame", "MinimapOrganizer_CategoryDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPRIGHT", -24, -28)

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

-- Refresh the button layout
function CollectionWindow:RefreshLayout()
    if not mainWindow or not mainWindow:IsShown() then return end

    local opts = MO.db.window
    local buttons = MO.ButtonManager:GetSortedButtons(categoryFilter)
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

    -- Calculate layout
    local perRow = opts.buttonsPerRow
    local size = opts.buttonSize
    local spacing = opts.buttonSpacing

    local buttonCount = #buttons
    local rows = math.max(1, math.ceil(buttonCount / perRow))
    local cols = math.min(buttonCount, perRow)

    -- Calculate window size
    local contentWidth = cols * (size + spacing) - spacing
    local contentHeight = rows * (size + spacing) - spacing

    -- Minimum sizes
    contentWidth = math.max(contentWidth, 150)
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
            GameTooltip:AddLine(self.buttonData.name, 1, 1, 1)
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
function CollectionWindow:ShowNewCategoryDialog(buttonName)
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
