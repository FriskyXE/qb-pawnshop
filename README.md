# QB-Pawnshop Rework

Just a clean, simplified rework of the classic pawnshop script. I stripped out the old stuff and swapped it for the Overextended (ox) ecosystem. It's lighter, faster, and much easier to set up.

## What's new?
- **Full ox_lib:** Context menus, input dialogs, and notifications. No more messy UI stuff.
- **Ox Inventory:** Built to work natively with `ox_inventory` (AddItem/RemoveItem).
- **Smart Interactions:** It handles Peds and Zones automatically. If you want a Ped, put it in the config. If you don't, it just makes a box zone with TextUI. Easy.
- **Per-Location Shops:** You can set up different items for different shops. Want one shop to only buy jewelry and another to buy electronics? You can do that.
- **Better Locales:** Everything is in JSON now. (English and Thai included).
- **Doorlock Integration:** Automatically locks and unlocks doors using `ox_doorlock` based on shop operating hours (when `Config.UseTimes` is enabled).

## Requirements
You'll need these installed for the script to work:
- `qb-core`
- `ox_lib`
- `ox_inventory`
- `ox_target`

## Setup
1. Drop the folder into your resources.
2. Make sure it's named `qb-pawnshop`.
3. Start it in your `server.cfg` after your dependencies.

## Config Tips
Inside `config.lua`, you can customize everything per location.

**Switching between NPC and Zone:**
To use a Proximity Zone instead of an NPC, just comment out the `ped` line in your `targets`. The script will detect it's missing and switch to a BoxZone automatically.

```lua
targets = {
    { 
        -- ped = 'mp_m_shopkeep_01', -- Commenting this out enables Zone mode
        loc = vec3(412.34, 314.81, 103.13), 
        heading = 207.0 
    },
}
```

## Support
This is open-source. Feel free to use and modify it for your server.

---
*Made with ❤️ for the FiveM community.*
