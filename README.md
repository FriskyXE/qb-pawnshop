# QB-Pawnshop Rework

Just a clean, simplified rework of the classic pawnshop script. I stripped out the old stuff and swapped it for the Overextended (ox) ecosystem. It's lighter, faster, and much easier to set up.

## What's new?
- **Full ox_lib integration:** 
    - Uses `lib.registerContext` and `lib.showContext` for all menus.
    - Uses `lib.inputDialog` for item selling quantities.
    - Uses `lib.callback` for faster and more reliable server-client communication.
    - Uses `lib.notify` and `lib.showTextUI` for a cleaner UI experience.
- **Native ox_inventory:** Built to work natively with `ox_inventory` functions like `AddItem`, `RemoveItem`, and `GetInventoryItems`. It uses `.count` and `.label` properties directly from the inventory.
- **Smart Interactions:** 
    - No more global toggles. It handles Peds and Zones automatically per location. 
    - If a target entry has a `ped` model, it spawns the NPC and sets up an `ox_target` interaction.
    - If the `ped` is missing (commented out), it automatically creates an `ox_lib` box zone with a `[E]` TextUI prompt.
- **Per-Location Shops:** Every shop can have its own inventory and price list. 
- **Time-Synced Doorlocks:** Fully integrated with `ox_doorlock`. Doors automatically lock and unlock based on the in-game clock (synced with the shop's operating hours).
- **Clean Locales:** All translations are moved to categorized JSON files (`en.json` and `th.json`).

## Requirements
You'll need these installed:
- `qb-core`
- `ox_lib`
- `ox_inventory`
- `ox_target`
- `ox_doorlock` (Optional, for door integration)

## Setup
1. Drop the folder into your resources.
2. Make sure it's named `qb-pawnshop`.
3. Add `ensure qb-pawnshop` in your `server.cfg` (after `ox_lib`, `ox_inventory`, and `ox_target`).

## Quick Config Guide
Inside `config.lua`, each location in `Config.PawnLocation` is a standalone setup:

```lua
[1] = {
    blip = { id = 59, colour = 69, scale = 0.8 }, -- Map blip settings
    inventory = { -- Items this specific shop will buy
        { name = 'goldchain', price = 100 },
        { name = 'rolex', price = 250 },
    },
    locations = { vec3(25.7, -1347.3, 29.49) }, -- Where the blips appear
    doors = { 1, 2 }, -- Door IDs from ox_doorlock to manage automatically
    targets = {
        -- To use a Zone, just comment out the 'ped' line below
        { 
            ped = 'a_f_o_ktown_01', 
            scenario = 'WORLD_HUMAN_STAND_IMPATIENT', 
            loc = vec3(25.7, -1347.3, 29.49), 
            heading = 90.0 
        },
    }
}
```

## Support
This is open-source. Feel free to use and modify it for your server.

---
*Made with ❤️ for the FiveM community.*
