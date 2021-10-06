
local mod_path = minetest.get_modpath("item_repair")

-- The API
item_repair = {}

-- The Internal stuff
item_repair_internal = {}

-- My version
function item_repair.version()
    -- DO NOT TOUCH THIS, This lets me know what version of the code your really running
    return "1.0 Inital"
end

-- Attempt to detect what gamemode/game these folks are running on
function item_repair.game_mode()
    local reported = false -- Have we send a report
    local game_mode = "???" -- let's even return that
    if (minetest.get_modpath("default") or false) and not reported then
        reported = true
        game_mode = "MTG"
    end
    if (minetest.get_modpath("mcl_core") or false) and not reported then
        reported = true
        game_mode = "MCL"
    end
    return game_mode
end

-- Just a helper to report issues in the test suite
function item_repair_internal.throw_error(msg)
    minetest.log("action", "[item_repair] Error: "..msg)
    minetest.log("action", "[item_repair] Version: "..item_repair.version())
    minetest.log("action", "[item_repair] GameMode: "..item_repair.game_mode())
    error("[item_repair] Please make an issue on my repo with the logs from your debug.txt")
end

-- Initalize Settings
dofile(mod_path.."/settings.lua")

-- Register the machine
dofile(mod_path.."/register.lua")
