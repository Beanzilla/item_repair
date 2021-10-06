local S = minetest.get_translator("item_repair")

-- Please don't change this, I don't protect against division by zero!
local base_time = 1.0 -- 0.4 max
local base_repair = 65535.0 * (item_repair_settings.repair_percent / 100.0)

item_repair_internal.update = function (pos, elapsed)
    local meta=minetest.get_meta(pos)
    local inv=meta:get_inventory()
    local repair=base_repair
    local time=base_time
    if not inv:is_empty("upgrades") then
        for i, s in ipairs(inv:get_list("upgrades")) do
--            minetest.log("action", "[item_repair] Slot: "..i.." Contains: "..s:get_name())
            if s:get_name() == "item_repair:upgrade_amount" then
                -- This item focuses on amount
                repair = repair + base_repair
            elseif s:get_name() == "item_repair:upgrade_time" then
                -- This item focuses on time
                time = time - 0.2 -- 0.4
            elseif s:get_name() == "item_repair:upgrade_multi" then
                -- This item applies a weaker version of both (To be considered "better" is not quite right)
                repair = repair + (base_repair * 0.75)
                time = time - 0.1 -- 0.7
            end
        end
    end
    meta:set_float("repair_amount", repair)
    meta:set_float("repair_time", time)
    local repairs_per_sec = repair / time
    -- The repair time has updated, restart the timer with the new value
    local timer = minetest.get_node_timer(pos)
    timer:stop()
    meta:set_int("state", 2)

    if inv:is_empty("done") then
        minetest.get_node_timer(pos):stop()
        meta:set_int("state", 0)
        item_repair_internal.inv_update(pos) -- Update the formspec
        if item_repair_settings.log_deep then
            minetest.log("action", "[item_repair] item_repair:repair_active at ("..pos.x..", "..pos.y..", "..pos.z..") by '"..meta:get_string("owner").."' will repair "..repair.." amount every "..time.." second(s) ("..string.format("%.1f", repairs_per_sec).."/s")
            minetest.log("action", "[item_repair] stopped")
        end
        local reported = false
        if inv:is_empty("done") and not reported then
            meta:set_string("infotext", "Item Repair [Nothing to repair] (" .. meta:get_string("owner") .. ")")
            reported = true
        end

        minetest.swap_node(pos, {name ="item_repair:repair"})
        return false
    else
        for i, s in ipairs(inv:get_list("done")) do
            s:add_wear(-repair)
            if s:get_wear() ~= 0 and item_repair_settings.log_production then
                minetest.log("action", "[item_repair] item_repair:repair_active at "..minetest.pos_to_string(pos).." by '"..meta:get_string("owner").."' Slot: "..i.." now has "..s:get_wear().." remaining.")
            end
            inv:set_stack("done", i, s)
        end
    end
    item_repair_internal.inv_update(pos) -- Update the formspec
    if item_repair_settings.log_deep then
        minetest.log("action", "[item_repair] update "..repair.." / "..time.." = "..string.format("%.1f", repairs_per_sec))
    end
    meta:set_string("infotext", "Item Repair "..string.format("%.1f", repairs_per_sec).."/s (" .. meta:get_string("owner") .. ")")
    return false
end

-- Attempt to get the MCL formspec to build a formspec able to be shown via their stuff
local mclform = rawget(_G, "mcl_formspec") or nil

-- This formspec will auto-change if MCL detected
item_repair_internal.inv_update = function(pos)
    local meta=minetest.get_meta(pos)
    local inv=meta:get_inventory()
    local names=meta:get_string("names")
    local op=meta:get_int("open")
    local open=""
    if op==0 then
        open="Only U"
    elseif op==1 then
        open="Members"  
    else
        open="Public"
    end
    local state = meta:get_int("state")
    local repair = meta:get_float("repair_amount")
    local time = meta:get_float("repair_time")
    local repairs_per_sec = ""
    local per_sec = repair / time
    if item_repair_settings.log_deep then
        minetest.log("action", "[item_repair] inv_update "..repair.." / "..time.." = "..string.format("%.1f", per_sec))
    end
    if state~=0 then
        repairs_per_sec = ""..string.format("%.1f", per_sec).."/s"
    else
        repairs_per_sec = "0/s"
    end
    if item_repair.game_mode() == "MTG" then
        meta:set_string("formspec",
            "size[8,11]" ..
            "label[0.3,0.3;"..minetest.formspec_escape(repairs_per_sec).."]" ..
            "list[context;upgrades;2,0;3,1;]" ..
            "button[0,1; 1.5,1;save;Save]" ..
            "button[0,2; 1.5,1;open;" .. open .."]" ..
            "textarea[2.2,1.3;6,1.8;names;Members List (Inventory access);" .. names  .."]"..
            "list[context;done;0,2.9;8,4;]" ..
            "list[current_player;main;0,7;8,4;]" ..
            "listring[current_player;main]"  ..
            "listring[current_name;done]"
        )
    elseif item_repair.game_mode() == "MCL" and mclform ~= nil then
        meta:set_string("formspec",
            "size[9, 10.5]"..
            "label[0.3,0.3;"..minetest.formspec_escape(repairs_per_sec).."]"..
            "list[context;upgrades;2,0;3,1;]"..
            mclform.get_itemslot_bg(2, 0, 3, 1)..
            "button[0,1; 1.9,1;save;Save]"..
            "button[0,2; 1.9,1;open;" .. open .."]" ..
            "label[2.16, 0.9;Members List (Inventory Access)]"..
            "textarea[2.2,1.3;6,1.8;names;;" .. names  .."]"..
            "list[context;done;0,2.9;9,3;]" ..
            mclform.get_itemslot_bg(0, 2.9, 9, 3)..
            "label[0,5.85;"..minetest.formspec_escape("Inventory").."]"..
--            "list[current_player;main;0,6.5;9,4;]" ..
--            mclform.get_itemslot_bg(0, 6.5, 9, 4)..
		    "list[current_player;main;0,6.5;9,3;9]"..
		    mclform.get_itemslot_bg(0,6.5,9,3)..
		    "list[current_player;main;0,9.74;9,1;]"..
		    mclform.get_itemslot_bg(0,9.74,9,1)..
            "listring[current_player;main]"  ..
            "listring[current_name;done]"
        )
    end
end

item_repair_internal.inv = function (placer, pos)
    local meta=minetest.get_meta(pos)
    item_repair_internal.inv_update(pos)
    meta:set_string("infotext", "Item Repair (" .. placer:get_player_name() .. ")")
end

-- Now we use all this to make our machine
local mod_name = "item_repair_"
local extent = ".png"
local grouping = nil
local sounding = nil
if item_repair.game_mode() == "MCL" then
    local mcl_sounds = rawget(_G, "mcl_sounds") or item_repair_internal.throw_error("Failed to obtain MCL Sounds")
    grouping = {handy=1}
    sounding = mcl_sounds.node_sound_metal_defaults()
elseif item_repair.game_mode() == "MTG" then
    local default = rawget(_G, "default") or item_repair_internal.throw_error("Failed to obtain MTG Sounds")
    grouping = {crumbly = 3}
    sounding = default.node_sound_metal_defaults()
else
    grouping = {crumbly = 3, handy=1}
end
minetest.register_node("item_repair:repair", {
    description = "Item Repair",
    _doc_items_long_desc = S("Repairs are technology from the future, they can repair multiple items, and can be upgraded."),
    _dock_items_usagehelp = S("Place the item wished to be repair in the middle slots, place upgrades in the top slots, or add players (1 per line) to allow others and change to Members."),
    _dock_items_hidden=false,
    tiles = {
        mod_name.."plate_off"..extent,
        mod_name.."plate_off"..extent,
        mod_name.."plate_off"..extent,
        mod_name.."plate_off"..extent,
        mod_name.."plate_off"..extent,
        mod_name.."plate_off"..extent,
    },
    groups = grouping,
    sounds = sounding,
    paramtype2 = "facedir",
    light_source = 1,
    drop = "item_repair:repair",
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Item Repair")
        meta:set_string("owner", "")
        meta:set_int("open", 0)
        meta:set_int("state", 0)
        meta:set_string("names", "")
        meta:set_float("repair_amount", base_repair) -- Add the base value
        meta:set_float("repair_time", base_time) -- Add the base value
        local inv = meta:get_inventory()
        if item_repair.game_mode() == "MTG" then
            inv:set_size("done", 32) -- 4*8
        elseif item_repair.game_mode() == "MCL" then
            inv:set_size("done", 27) -- 3*9
        end
        inv:set_size("upgrades", 3)
    end,
    after_place_node = function(pos, placer, itemstack)
        local meta = minetest.get_meta(pos)
        meta:set_string("owner", (placer:get_player_name() or ""))
        local inv = meta:get_inventory()
        item_repair_internal.inv(placer,pos)
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        local meta=minetest.get_meta(pos)
        local open=meta:get_int("open")
        local name=player:get_player_name()
        local owner=meta:get_string("owner")
        if meta:get_int("state") ~= 1 then
            minetest.get_node_timer(pos):start(meta:get_int("repair_time"))
            minetest.swap_node(pos, {name ="item_repair:repair_active"})
            meta:set_int("state", 1)
        end
        if name==owner then return stack:get_count() end
        if open==2 and listname=="done" then return stack:get_count() end
        if open==1 and listname=="done" then
            local names=meta:get_string("names")
            local txt=names.split(names,"\n")
            for i in pairs(txt) do
                if name==txt[i] then
                    return stack:get_count()
                end
            end
        end
        return 0
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local meta=minetest.get_meta(pos)
        local open=meta:get_int("open")
        local name=player:get_player_name()
        local owner=meta:get_string("owner")
        if meta:get_int("state") ~= 1 then
            minetest.get_node_timer(pos):start(meta:get_int("repair_time"))
            minetest.swap_node(pos, {name ="item_repair:repair_active"})
            meta:set_int("state", 1)
        end
        if name==owner then return stack:get_count() end
        if open==2 and listname=="done" then return stack:get_count() end
        if open==1 and listname=="done" then
            local names=meta:get_string("names")
            local txt=names.split(names,"\n")
            for i in pairs(txt) do
                if name==txt[i] then
                    return stack:get_count()
                end
            end
        end
        return 0
    end,
    can_dig = function(pos, player)
        local meta=minetest.get_meta(pos)
        local owner=meta:get_string("owner")
        local inv=meta:get_inventory()
        if (inv:is_empty("upgrades") and inv:is_empty("done")) then
            -- Only check it's the owner
            if (player:get_player_name()==owner) and owner ~= "" then
                minetest.get_node_timer(pos):stop()
            end
            return (player:get_player_name()==owner and
                    owner~="")
        else
            return false
        end
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        local meta = minetest.get_meta(pos)
        if meta:get_int("state") ~= 1 then
            minetest.get_node_timer(pos):start(meta:get_int("repair_time"))
            minetest.swap_node(pos, {name ="item_repair:repair_active"})
            meta:set_int("state", 1)
        end
        if meta:get_int("open")==0 and player:get_player_name()~=meta:get_string("owner") then
            return 0
        end
        return count
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        if sender:get_player_name() ~= meta:get_string("owner") then
            return false
        end

        if fields.save then
            meta:set_string("names", fields.names)
            item_repair_internal.inv(sender,pos)
        end

        if fields.open then
            local open=meta:get_int("open")
            open=open+1
            if open>2 then open=0 end
            meta:set_int("open",open)
            item_repair_internal.inv(sender,pos)
        end
    end,
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local rc = item_repair_internal.update(pos, elapsed)
        if meta:get_int("state") == 2 then
            if item_repair_settings.log_deep then
                minetest.log("action", "[item_repair] Timer set to "..meta:get_float("repair_time").." for "..minetest.pos_to_string(pos))
            end
            minetest.get_node_timer(pos):start(meta:get_float("repair_time"))
            meta:set_int("state", 1)
        end
        return rc
    end
})

minetest.register_node("item_repair:repair_active", {
    description = "Item Repair",
    tiles = {
        mod_name.."plate_on"..extent,
        mod_name.."plate_on"..extent,
        mod_name.."plate_on"..extent,
        mod_name.."plate_on"..extent,
        mod_name.."plate_on"..extent,
        mod_name.."plate_on"..extent,
    },
    groups = grouping,
    sounds = sounding,
    paramtype2 = "facedir",
    light_source = 5,
    drop = "item_repair:repair",
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Item Repair")
        meta:set_string("owner", "")
        meta:set_int("open", 0)
        meta:set_int("state", 0)
        meta:set_string("names", "")
        meta:set_float("repair_amount", base_repair) -- Add the base value
        meta:set_float("repair_time", base_time) -- Add the base value
        local inv = meta:get_inventory()
        if item_repair.game_mode() == "MTG" then
            inv:set_size("done", 32) -- 8*4
        elseif item_repair.game_mode() == "MCL" then
            inv:set_size("done", 27) -- 9*3
        end
        inv:set_size("upgrades", 3)
    end,
    after_place_node = function(pos, placer, itemstack)
        local meta = minetest.get_meta(pos)
        if meta:get_string("owner") == "" then
            meta:set_string("owner", placer:get_player_name() or "")
        end
        local inv = meta:get_inventory()
        item_repair_internal.inv(placer,pos)
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        local meta=minetest.get_meta(pos)
        local open=meta:get_int("open")
        local name=player:get_player_name()
        local owner=meta:get_string("owner")
        if meta:get_int("state") ~= 1 then
            minetest.get_node_timer(pos):start(meta:get_int("repair_time"))
            minetest.swap_node(pos, {name = "item_repair:repair_active"})
            meta:set_int("state", 1)
        end
        if name==owner then return stack:get_count() end
        if open==2 and listname=="done" then return stack:get_count() end
        if open==1 and listname=="done" then
            local names=meta:get_string("names")
            local txt=names.split(names,"\n")
            for i in pairs(txt) do
                if name==txt[i] then
                    return stack:get_count()
                end
            end
        end
        return 0
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        local meta=minetest.get_meta(pos)
        local open=meta:get_int("open")
        local name=player:get_player_name()
        local owner=meta:get_string("owner")
        if meta:get_int("state") ~= 1 then
            minetest.get_node_timer(pos):start(meta:get_int("repair_time"))
            minetest.swap_node(pos, {name ="item_repair:repair_active"})
            meta:set_int("state", 1)
        end
        if name==owner then return stack:get_count() end
        if open==2 and listname=="done" then return stack:get_count() end
        if open==1 and listname=="done" then
            local names=meta:get_string("names")
            local txt=names.split(names,"\n")
            for i in pairs(txt) do
                if name==txt[i] then
                    return stack:get_count()
                end
            end
        end
        return 0
    end,
    can_dig = function(pos, player)
        local meta=minetest.get_meta(pos)
        local owner=meta:get_string("owner")
        local inv=meta:get_inventory()
        if (inv:is_empty("upgrades") and inv:is_empty("done")) then
            -- Only check it's the owner
            if (player:get_player_name()==owner) and owner ~= "" then
                minetest.get_node_timer(pos):stop()
            end
            return (player:get_player_name()==owner and
                    owner~="")
        else
            return false
        end
    end,
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        local meta = minetest.get_meta(pos)
        if meta:get_int("state") ~= 1 then
            minetest.get_node_timer(pos):start(meta:get_int("repair_time"))
            minetest.swap_node(pos, {name ="item_repair:repair_active"})
            meta:set_int("state", 1)
        end
        if meta:get_int("open")==0 and player:get_player_name()~=meta:get_string("owner") then
            return 0
        end
        return count
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        local meta = minetest.get_meta(pos)
        if sender:get_player_name() ~= meta:get_string("owner") then
            return false
        end

        if fields.save then
            meta:set_string("names", fields.names)
            item_repair_internal.inv(sender,pos)
        end

        if fields.open then
            local open=meta:get_int("open")
            open=open+1
            if open>2 then open=0 end
            meta:set_int("open",open)
            item_repair_internal.inv(sender,pos)
        end
    end,
    on_timer = function(pos, elapsed)
        local meta = minetest.get_meta(pos)
        local rc = item_repair_internal.update(pos, elapsed)
        if meta:get_int("state") == 2 then
            if item_repair_settings.log_deep then
                minetest.log("action", "[item_repair] Timer set to "..meta:get_float("repair_time").." for "..minetest.pos_to_string(pos))
            end
            minetest.get_node_timer(pos):start(meta:get_float("repair_time"))
            meta:set_int("state", 1)
        end
        return rc
    end
})

minetest.register_craftitem("item_repair:upgrade_amount", {
    description = "Repair Upgrade Capacitor",
    inventory_image = "item_repair_upgrade_amount.png",
    stack_max = 1
})

minetest.register_craftitem("item_repair:upgrade_time", {
    description = "Repair Upgrade Processor",
    inventory_image = "item_repair_upgrade_time.png",
    stack_max = 1
})

minetest.register_craftitem("item_repair:upgrade_multi", {
    description = "Repair Upgrade Complex",
    inventory_image = "item_repair_upgrade_multi.png",
    stack_max = 1
})

if item_repair_settings.craft then
    if minetest.get_modpath("default") or false then
        local planks = "group:wood"
        local obsidian = "default:obsidian"
        local tin = "default:tin_ingot"
        local copper = "default:copper_ingot"
        local bronze = "default:bronze_ingot"
        local mese_crystal = "default:mese_crystal"

        -- Machine
        minetest.register_craft({
            output = "item_repair:repair",
            recipe = {
                {planks, planks, planks},
                {planks, obsidian, planks},
                {planks, planks, planks}
            }
        })
        -- Upgrades
        minetest.register_craft({
            output = "item_repair:upgrade_amount",
            recipe = {
                {"", tin, ""},
                {tin, mese_crystal, tin},
                {"", tin, ""}
            }
        })
        minetest.register_craft({
            output = "item_repair:upgrade_time",
            recipe = {
                {"", copper, ""},
                {copper, mese_crystal, copper},
                {"", copper, ""}
            }
        })
        minetest.register_craft({
            output = "item_repair:upgrade_multi",
            recipe = {
                {"", bronze, ""},
                {bronze, mese_crystal, bronze},
                {"", bronze, ""}
            }
        })
    end
    if (minetest.get_modpath("mcl_core") or false) then
        local plank = "group:wood"
        local anvil = "mcl_anvils:anvil"
        local anvil_1 = "mcl_anvils:anvil_damage_1"
        local anvil_2 = "mcl_anvils:anvil_damage_2"
        local iron = "mcl_core:iron_ingot"
        local gold = "mcl_core:gold_ingot"
        local redstone = "mcl_core:diamond"

        -- Machine
        minetest.register_craft({
            output = "item_repair:repair",
            recipe = {
                {plank, plank, plank},
                {plank, anvil, plank},
                {plank, plank, plank}
            }
        })
        minetest.register_craft({
            output = "item_repair:repair",
            recipe = {
                {plank, plank, plank},
                {plank, anvil_1, plank},
                {plank, plank, plank}
            }
        })
        minetest.register_craft({
            output = "item_repair:repair",
            recipe = {
                {plank, plank, plank},
                {plank, anvil_2, plank},
                {plank, plank, plank}
            }
        })
        -- Upgrades
        minetest.register_craft({
            output = "item_repair:upgrade_amount",
            recipe = {
                {"", iron, ""},
                {iron, redstone, iron},
                {"", iron, ""}
            }
        })
        minetest.register_craft({
            output = "item_repair:upgrade_time",
            recipe = {
                {"", gold, ""},
                {gold, redstone, gold},
                {"", gold, ""}
            }
        })
        minetest.register_craft({
            output = "item_repair:upgrade_multi",
            recipe = {
                {iron, gold, iron},
                {gold, redstone, gold},
                {iron, gold, iron}
            }
        })
    end
end

-- Allow the item to be "recycled" (if so desired)
minetest.register_craft({
    type = "fuel",
    recipe = "item_repair:repair",
    burntime = 300
})
minetest.register_craft({
    type = "fuel",
    recipe = "item_repair:repair_active",
    burntime = 300
})
minetest.register_craft({
    type = "fuel",
    recipe = "item_repair:upgrade_amount",
    burntime = 100
})
minetest.register_craft({
    type = "fuel",
    recipe = "item_repair:upgrade_time",
    burntime = 100
})
minetest.register_craft({
    type = "fuel",
    recipe = "item_repair:upgrade_multi",
    burntime = 150
})

-- For those who don't want an active repairs in their inventory. (Looks only)
minetest.register_craft({
    type = "shapeless",
    output = "item_repair:repair",
    recipe = {
        "item_repair:repair_active",
    }
}) -- Or perhaps you want it to look active.
minetest.register_craft({
    type = "shapeless",
    output = "item_repair:repair_active",
    recipe = {
        "item_repair:repair",
    }
})
