# Changelog

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
