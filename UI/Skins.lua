local ADDON_NAME, MO = ...

MO.Skins = {}

-- Theme definitions. Each theme customizes the ButtonFrameTemplate chrome
-- via texture tinting and selective decoration hiding — same pattern
-- Baganator uses in its Skins/ module, adapted for a single main frame.
local THEMES = {
    Default = {
        bgTint = { 1, 1, 1, 1 },
        titleTint = { 1, 1, 1, 1 },
        hideStreaks = false,
    },
    Dark = {
        bgTint = { 0.35, 0.35, 0.4, 1 },
        titleTint = { 0.5, 0.5, 0.55, 1 },
        hideStreaks = false,
    },
    Minimal = {
        bgTint = { 0.1, 0.1, 0.1, 1 },
        titleTint = { 0.15, 0.15, 0.15, 1 },
        hideStreaks = true,
        hideBorder = true,
    },
    Transparent = {
        bgTint = { 1, 1, 1, 0.5 },
        titleTint = { 1, 1, 1, 0.7 },
        hideStreaks = false,
    },
}

function MO.Skins:GetThemeNames()
    local names = {}
    for name in pairs(THEMES) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function MO.Skins:GetTheme(name)
    return THEMES[name] or THEMES.Default
end

-- Apply a theme to the collection window. Called on window create and any
-- time the Theme or Opacity setting changes. Opacity is a multiplier over
-- each theme's own alpha values.
function MO.Skins:Apply(frame, themeName)
    if not frame then return end
    local theme = self:GetTheme(themeName)
    local opacity = (MO.db and MO.db.window and MO.db.window.opacity) or 1

    if frame.Bg then
        frame.Bg:SetVertexColor(theme.bgTint[1], theme.bgTint[2], theme.bgTint[3], theme.bgTint[4] * opacity)
    end

    if frame.TopTileStreaks then
        if theme.hideStreaks then
            frame.TopTileStreaks:Hide()
        else
            frame.TopTileStreaks:Show()
            frame.TopTileStreaks:SetVertexColor(theme.titleTint[1], theme.titleTint[2], theme.titleTint[3], theme.titleTint[4] * opacity)
        end
    end
    if frame.TitleBg then
        frame.TitleBg:SetVertexColor(theme.titleTint[1], theme.titleTint[2], theme.titleTint[3], theme.titleTint[4] * opacity)
    end

    -- Minimal theme strips the beveled border art to give a truly flat look,
    -- and shows a flat title strip so the title bar band doesn't vanish.
    if frame.NineSlice then
        if theme.hideBorder then
            frame.NineSlice:Hide()
        else
            frame.NineSlice:Show()
        end
    end
    if frame.minimalTitleStrip then
        if theme.hideBorder then
            frame.minimalTitleStrip:Show()
            -- Approximate Bg's atlased rendering by pre-multiplying with the
            -- atlas's warm base color (~0.8, 0.75, 0.7 average) so a flat
            -- ColorTexture visually matches the body.
            frame.minimalTitleStrip:SetColorTexture(
                theme.bgTint[1] * 0.85,
                theme.bgTint[2] * 0.80,
                theme.bgTint[3] * 0.72,
                theme.bgTint[4] * opacity
            )
        else
            frame.minimalTitleStrip:Hide()
        end
    end
end
