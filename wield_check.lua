-- playername -> name
local last_wielded_item = {}

-- check for tools
local function wield_check()
    for _, player in ipairs(minetest.get_connected_players()) do
        local itemstack = player:get_wielded_item()
        local playername = player:get_player_name()
        local id, name
        if itemstack then
            name = itemstack:get_name()
            local meta = itemstack:get_meta()
            id = meta:get_int("id")
        end
        local is_placer = name == "pick_and_place:placer"

        if last_wielded_item[playername] and name ~= last_wielded_item[playername] then
            -- last item got out of focus
            local item_def = minetest.registered_items[last_wielded_item[playername]]
            if item_def and type(item_def.on_blur) == "function" then
                item_def.on_blur(player)
            end
        end

        if is_placer then
            pick_and_place.on_step(itemstack, player)
        end

        last_wielded_item[playername] = name
    end
    minetest.after(0, wield_check)
end

minetest.after(0, wield_check)
minetest.register_on_leaveplayer(function(player)
    last_wielded_item[player:get_player_name()] = nil
end)