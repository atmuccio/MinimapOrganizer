# MinimapOrganizer

A World of Warcraft addon that collects minimap buttons into a clean, organized window.

## Features

- **Collects minimap buttons** into a movable grid window
- **Custom categories** - Create, rename, reorder, and delete your own categories
- **Favorites** - Mark buttons with a star for quick access
- **Exclude buttons** - Keep specific buttons on the minimap
- **Auto-collect** - Automatically gather new addon buttons
- **Category headers** - Visual separators when viewing all buttons by category
- **Smart tooltips** - Shows friendly addon names instead of frame names
- **Configurable layout** - Adjust buttons per row and window scale
- **Theme selection** - Choose from Default, Dark, Transparent, or Minimal themes
- **Window opacity** - Adjustable background transparency
- **Modern settings** - Full integration with WoW's addon settings panel
- **MBB migration** - Automatically imports settings from MinimapButtonBag

## Installation

1. Download the latest release
2. Extract to `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`

## Usage

### Opening the Window
- **Left-click** the minimap button, or
- Type `/mo` in chat

### Managing Buttons
- **Left-click** a button to use it
- **Right-click** a button for options:
  - Toggle favorite
  - Set category
  - Release back to minimap
- **Ctrl+click** to quickly toggle favorite

### Slash Commands

| Command | Description |
|---------|-------------|
| `/mo` | Toggle the collection window |
| `/mo settings` | Open addon settings |
| `/mo reset` | Reset window position |

## Settings

Access via `/mo settings` or the WoW addon settings panel:

- **Hide Minimap Button** - Use slash commands only
- **Lock Minimap Button** - Prevent dragging
- **Buttons Per Row** - 4 to 16
- **Window Scale** - 0.5x to 2.0x
- **Window Opacity** - 30% to 100%
- **Theme** - Default, Dark, Transparent, or Minimal
- **Close on Click** - Auto-close after clicking a button
- **Hide Category Filter** - Hide the category filter dropdown
- **Sort Method** - Alphabetical or by category
- **Auto-Collect** - Automatically bag new buttons
- **Show Favorites First** - Pin favorites to the top
- **Manage Categories** - Reorder and delete categories
- **Manage Exclusions** - View and restore excluded buttons

## Requirements

- World of Warcraft Retail 12.0+

## License

MIT License - See [LICENSE](LICENSE) for details.
