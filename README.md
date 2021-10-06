# Item Repair [![ContentDB](https://content.minetest.net/packages/ApolloX/item_repair/shields/downloads/)](https://content.minetest.net/packages/ApolloX/item_repair/) V1.0 Inital

Repair multiple items with ease.

## What's in the box

* [Internal Assitant Functions](INTERNALS.md)
* [Settings](SETTINGS.md)
* Multi-player support
* Security
* Multiple Games support (This mod supports MTG and MCL2)
* Need [help](HELP.md)?

## Quick-Start

1. Get this repo!
2. Drop this directory/repo into your Minetest mods folder.
3. Edit settings.lua to your liking.
4. Add `load_mod_item_repair = true` to your worlds world.mt file.
5. Enjoy the mod.

## A note about logging

This mod can dump a lot of information out to your log file (`debug.txt`).

Please turn off the following settings like so, below:

```lua
item_repair_settings.log_production = false
item_repair_settings.log_deep = false
```

## Notice

Yes most of this code, it's formspecs, and it's images were taken from my other mod [item_replicator](https://content.minetest.net/packages/ApolloX/item_replicator/).
