# qb-pawnshop (Refactored)

A modern, optimized pawn shop script for FiveM built for **QB-Core** and fully integrated with the **ox** ecosystem.

## 🚀 Features

- **ox_lib Integration**: Uses `ox_lib` for high-performance context menus, input dialogs, notifications, and proximity zones.
- **ox_inventory Support**: Fully compatible with `ox_inventory` native functions and item data structures.
- **Dynamic Interactions**: 
  - Supports **ox_target** for immersive NPC interactions.
  - Automatically falls back to **ox_lib Box Zones** with **TextUI** prompts if a Ped is not configured (or commented out).
- **Location-Specific Inventories**: Define different items and prices for each pawn shop location.
- **Categorized Localization**: Support for multiple languages (**English** & **Thai** included) using standard JSON format.
- **Optimized Performance**: Clean, centralized initialization and automatic resource cleanup.

## 📦 Dependencies

- [qb-core](https://github.com/qbcore-framework/qb-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)

## 🛠️ Installation

1. Clone or download this repository into your `resources` folder.
2. Ensure the folder is named `qb-pawnshop`.
3. Add `ensure qb-pawnshop` to your `server.cfg` **after** `ox_lib`, `ox_inventory`, and `ox_target`.

## ⚙️ Configuration

The script is highly customizable via `config.lua`:

- **PawnLocation**: Set up blips, NPC peds, interaction zones, and specific shop inventories.
- **UseTimes**: Toggle whether shops should only be open during specific GTA hours.
- **TimeOpen/TimeClosed**: Define the operating hours.

### Example Interaction Switch
To use a Zone instead of an NPC, simply comment out the `ped` line in `config.lua`:
```lua
targets = {
    { 
        -- ped = 'mp_m_shopkeep_01', -- Comment this to use a Zone
        loc = vec3(412.34, 314.81, 103.13), 
        heading = 207.0 
    },
}
```

## 🌍 Localization

Translations are located in the `locales/` directory in JSON format.
- `en.json`: English
- `th.json`: Thai (ภาษาไทย)

To add a new language, create a new `.json` file and update your `ox_lib` locale settings.

## 📄 License
This project is open-source. Feel free to use and modify it for your server.
