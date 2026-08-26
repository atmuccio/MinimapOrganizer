# Changelog

## [1.6.0] - 2026-08-26

### Added
- **Search bar** in the collection window's top row — case-insensitive matching against both raw frame names and friendly addon display names
- **Favorites filter** — new selectable option in the category dropdown that shows only favorited buttons regardless of category
- **Modern portrait chrome** — main frame now inherits Blizzard's `ButtonFrameTemplate` for the clean modern header look (portrait and footer button bar hidden)
- **Settings menu** — the title-bar gear icon now opens a small dropdown with a Manage Mode toggle and a link into the WoW settings panel
- **Themes rebuilt on a Skins module** — Default / Dark / Minimal / Transparent, applied via texture tinting so themes work with the modern chrome
- **Window Opacity slider** — separate from theme, multiplies the theme's own alpha (30%–100%)
- **Shipped icon assets** — filter funnel and settings gear PNGs rendered in-house

### Changed
- Merged "Hide Category Filter" and "Hide Search Bar" settings into a single **Hide Search and Filter** toggle (migration handles existing values)
- All ten supported locales updated with translations for the new UI strings

### Fixed
- Belt-and-suspenders guard in `ButtonScanner.HookButton` ensures no code path can hook a `SYSTEM_IGNORE` frame like `ExpansionLandingPageMinimapButton`

## [1.5.2] - 2026-08-16

### Changed
- Updated Interface version to 120100 for WoW 12.1.0 (Curse of Ula'tek)

### Note
- Apologies for the short delay on this update — I was away for a bit. Thanks for your patience, and back to it now!

## [1.5.1] - 2026-06-17

### Changed
- Updated Interface version to 120007 for WoW 12.0.7 (Midnight: Revelations)

## [1.5.0] - 2026-04-21

### Changed
- Updated Interface version to 120005 for WoW 12.0.5 (Lingering Shadows)
- Fixed addon version string being out of sync between TOC and runtime

## [1.4.0] - Preserve Original Button Behavior

### Added
- **Manage Mode** - Gear icon on the collection window title bar toggles between normal and manage mode
- **Normal Mode** - All clicks (left, right, middle + modifiers) and tooltips pass through to the original addon button untouched
- **Manage Mode** - Left-click toggles favorites, right-click opens MO context menu (categories, release)

### Changed
- Original button tooltips are now shown in normal mode instead of MO's custom tooltip
- Original button click handlers (including right-click and middle-click) are now preserved
- Manage mode automatically resets when the collection window is closed
- Redesigned title bar buttons using native Blizzard atlas textures for a cleaner, more consistent look
- Gear icon now uses proper hover, pressed, and active states matching Blizzard's UI style
- Improved window dragging to prevent cursor offset issues

### Fixed
- Original button tooltips were being overwritten with MO-only information ([#7](https://github.com/atmuccio/MinimapOrganizer/issues/7))
- Right-click and middle-click on collected buttons were not forwarded to the original addon ([#7](https://github.com/atmuccio/MinimapOrganizer/issues/7))
- Window drag now anchors correctly to the cursor position

## [1.3.1] - WoW 12.0.1 Compatibility

### Changed
- Updated Interface version to 120001 for WoW 12.0.1 (Midnight launch)
- Fixed addon version string being out of sync between TOC and runtime

## [1.3.0] - Hide Filter & Discord Notifications

### Added
- **Hide Category Filter** - New setting to hide the category filter dropdown from the collection window
- **Discord Notifications** - GitHub Actions workflow for Discord notifications on new PRs, issues, and release deployments

## [1.2.1] - Themes & Customization

### Added
- **Theme Selection** - Choose from Default, Dark, Transparent, or Minimal themes
- **Window Opacity** - Adjustable window background opacity (30%-100%)

### Fixed
- Icons now render correctly across all themes (fixed frame strata/level for LibDBIcon buttons)

## [1.2.0] - Localization & Polish

### Added
- **Localization Support** - Added locale files for German, Spanish (ES/MX), French, Italian, Korean, Portuguese (BR), Russian, and Chinese (Simplified/Traditional)

### Changed
- Improved collection window layout with better spacing and alignment
- Category filter dropdown is now left-aligned with proper padding
- Title bar and close button are now properly aligned
- Category header divider lines now dynamically adjust to text width

## [1.1.0] - UI Enhancements

### Added
- **Exclusion Management UI** - View and restore excluded buttons from Settings
- **Category Ordering** - Reorder categories with up/down buttons in Settings
- **Title Bar** - Collection window now has a proper title bar with backdrop
- **Category Headers** - "All" view with category sort shows section headers between groups
- **Favorites Section** - Favorites grouped under "Favorites" header when shown first
- **Smart Addon Names** - Tooltips show friendly addon names via LibDBIcon and TOC metadata

### Changed
- Uncategorized category always appears last in sorting and category management
- Categories cannot be moved below Uncategorized
- TomTom waypoint arrows and pins are now properly excluded from collection

### Removed
- Button size setting (temporarily removed pending fixes)

## [1.0.0] - Initial Release

### Features
- Collects minimap buttons into a movable window
- Custom categories with create/delete support
- Favorites system (star indicator)
- Exclude buttons to keep them on minimap
- Auto-collect new buttons option
- Configurable grid layout (buttons per row)
- Window scale adjustment
- Modern Settings API integration
- Migration support from MBB addon
- Slash commands: `/mo`, `/minimaporganizer`

### Settings
- Hide/lock minimap button
- Buttons per row (4-16)
- Window scale (0.5x-2.0x)
- Close on button click
- Sort method (alphabetical/by category)
- Auto-collect new buttons
- Show favorites first
