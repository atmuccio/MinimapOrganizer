std = "lua51"
max_line_length = false
codes = true
self = false

exclude_files = {
    ".release",
    ".luarocks",
}

ignore = {
    "122", -- Setting read-only global (addon namespace creation)
    "211", -- Unused local variable
    "212", -- Unused argument
    "213", -- Unused loop variable
    "311", -- Value assigned to variable is unused
    "432", -- Shadowing upvalue argument (common pattern for self in callbacks)
    "542", -- Empty if branch
}

globals = {
    -- Addon namespace
    "MinimapOrganizer",
    "MinimapOrganizerDB",

    -- WoW API globals
    "CreateFrame",
    "UIParent",
    "Minimap",
    "GameTooltip",
    "Settings",
    "MenuUtil",
    "StaticPopupDialogs",
    "StaticPopup_Show",
    "UIDropDownMenu_Initialize",
    "UIDropDownMenu_CreateInfo",
    "UIDropDownMenu_AddButton",
    "UIDropDownMenu_SetWidth",
    "UIDropDownMenu_SetText",
    "GetCursorPosition",
    "GetLocale",
    "IsControlKeyDown",
    "SlashCmdList",
    "SLASH_MINIMAPORGANIZER1",
    "SLASH_MINIMAPORGANIZER2",
    "C_Timer",
    "MinimalSliderWithSteppersMixin",
    "UISpecialFrames",

    -- WoW frame methods added dynamically
    "tinsert",
    "tremove",
    "wipe",
    "format",
    "strsplit",
    "strjoin",

    -- MBB migration
    "MBB_Exclude",
}

read_globals = {
    "table",
    "string",
    "math",
    "pairs",
    "ipairs",
    "type",
    "tostring",
    "tonumber",
    "select",
    "unpack",
    "print",
    "getmetatable",
    "setmetatable",
    "rawget",
    "rawset",
    "next",
    "error",
    "pcall",
    "xpcall",
    "_G",
}
