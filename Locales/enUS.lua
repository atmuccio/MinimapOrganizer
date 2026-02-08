local ADDON_NAME, MO = ...

MO.L = {
    -- Addon info
    ADDON_NAME = "MinimapOrganizer",

    -- Window
    WINDOW_TITLE = "Minimap Buttons",
    CATEGORY = "Category",
    FAVORITE = "Favorite",
    FAVORITES = "Favorites",
    ALL_CATEGORIES = "All",
    UNCATEGORIZED = "Uncategorized",

    -- Tooltips
    TOOLTIP_LEFTCLICK = "Left-click to open",
    TOOLTIP_RIGHTCLICK = "Right-click for settings",
    TOOLTIP_DRAG = "Drag to move",
    TOOLTIP_BUTTON_RIGHTCLICK = "Right-click for options",
    TOOLTIP_CTRL_CLICK = "Ctrl+Click to toggle favorite",

    -- Context menu
    TOGGLE_FAVORITE = "Toggle Favorite",
    SET_CATEGORY = "Set Category",
    RELEASE_TO_MINIMAP = "Release to Minimap",
    NEW_CATEGORY = "New Category...",
    DELETE_CATEGORY = "Delete Category",
    RENAME_CATEGORY = "Rename Category",

    -- Sorting
    SORT_ALPHABETICAL = "Alphabetical",
    SORT_CATEGORY = "By Category",

    -- Settings headers
    SETTINGS_HEADER_MINIMAP = "Minimap Button",
    SETTINGS_HEADER_WINDOW = "Collection Window",
    SETTINGS_HEADER_BEHAVIOR = "Behavior",
    SETTINGS_HEADER_CATEGORIES = "Categories",

    -- Settings: Minimap Button
    SETTINGS_HIDE_MINIMAP_BUTTON = "Hide Minimap Button",
    SETTINGS_HIDE_MINIMAP_BUTTON_TOOLTIP = "Hide the minimap button. Use /mo to toggle the window.",
    SETTINGS_LOCK_MINIMAP_BUTTON = "Lock Minimap Button Position",
    SETTINGS_LOCK_MINIMAP_BUTTON_TOOLTIP = "Prevent the minimap button from being dragged.",

    -- Settings: Window
    SETTINGS_BUTTONS_PER_ROW = "Buttons Per Row",
    SETTINGS_BUTTONS_PER_ROW_TOOLTIP = "Number of buttons to display per row.",
    SETTINGS_BUTTON_SIZE = "Button Size",
    SETTINGS_BUTTON_SIZE_TOOLTIP = "Size of buttons in pixels.",
    SETTINGS_WINDOW_SCALE = "Window Scale",
    SETTINGS_WINDOW_SCALE_TOOLTIP = "Scale of the collection window.",
    SETTINGS_WINDOW_OPACITY = "Window Opacity",
    SETTINGS_WINDOW_OPACITY_TOOLTIP = "Transparency of the collection window background.",
    SETTINGS_THEME = "Theme",
    SETTINGS_THEME_TOOLTIP = "Visual style of the collection window.",
    SETTINGS_CLOSE_ON_CLICK = "Close Window After Click",
    SETTINGS_CLOSE_ON_CLICK_TOOLTIP = "Close the window after clicking a button.",
    SETTINGS_HIDE_FILTER = "Hide Category Filter",
    SETTINGS_HIDE_FILTER_TOOLTIP = "Hide the category filter dropdown from the collection window.",
    SETTINGS_SORT_METHOD = "Sort Method",
    SETTINGS_SORT_METHOD_TOOLTIP = "How to sort buttons in the collection.",

    -- Themes
    THEME_DEFAULT = "Default",
    THEME_DARK = "Dark",
    THEME_TRANSPARENT = "Transparent",
    THEME_MINIMAL = "Minimal",

    -- Settings: Behavior
    SETTINGS_AUTO_COLLECT = "Auto-Collect New Buttons",
    SETTINGS_AUTO_COLLECT_TOOLTIP = "Automatically collect newly detected minimap buttons.",
    SETTINGS_SHOW_FAVORITES_FIRST = "Show Favorites First",
    SETTINGS_SHOW_FAVORITES_FIRST_TOOLTIP = "Always display favorite buttons at the top.",

    -- Settings: Category Management
    SETTINGS_MANAGE_CATEGORIES = "Manage Categories",
    SETTINGS_MANAGE_CATEGORIES_DESC = "View, create, and delete custom categories. Buttons in deleted categories will be moved to Uncategorized.",
    BUTTONS = "buttons",
    MOVE_UP = "Move Up",
    MOVE_DOWN = "Move Down",

    -- Settings: Exclusion Management
    SETTINGS_MANAGE_EXCLUSIONS = "Manage Exclusions",
    SETTINGS_MANAGE_EXCLUSIONS_DESC = "Buttons released to the minimap are listed here. Remove an exclusion to allow the button to be collected again.",
    RESTORE_BUTTON = "Restore",
    NO_EXCLUDED_BUTTONS = "No buttons are currently excluded.",

    -- Slash commands
    SLASH_USAGE = "Usage: /mo [toggle|settings|reset|debug]",
    SLASH_RESET_DONE = "Window position reset.",
    SLASH_DEBUG_ON = "Debug mode enabled.",
    SLASH_DEBUG_OFF = "Debug mode disabled.",

    -- Dialogs
    DIALOG_NEW_CATEGORY_TITLE = "New Category",
    DIALOG_NEW_CATEGORY_TEXT = "Enter a name for the new category:",
    DIALOG_RENAME_CATEGORY_TITLE = "Rename Category",
    DIALOG_RENAME_CATEGORY_TEXT = "Enter the new name:",
    DIALOG_DELETE_CATEGORY_CONFIRM = "Are you sure you want to delete '%s'? Buttons will be moved to Uncategorized.",
    DIALOG_ACCEPT = "Accept",
    DIALOG_CANCEL = "Cancel",

    -- Messages
    MSG_BUTTON_COLLECTED = "Collected: %s",
    MSG_BUTTON_RELEASED = "Released: %s",
    MSG_CATEGORY_CREATED = "Category created: %s",
    MSG_CATEGORY_DELETED = "Category deleted: %s",
    MSG_MIGRATED_FROM_MBB = "Migrated settings from MBB addon.",
}

-- Metatable for missing keys (returns key itself as fallback)
setmetatable(MO.L, {
    __index = function(t, key)
        return key
    end
})
