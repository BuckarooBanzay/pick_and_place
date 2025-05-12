local FORMSPEC_NAME = "pick_and_place:palette_tool"

local function get_formspec(meta)
    local categories = pick_and_place.get_template_categories()
    local category_list = table.concat(categories, ",")

    return [[
        size[10,10;]
        real_coordinates[true]
        dropdown[0.1,0.1;9.8,0.9;category;]] .. category_list .. [[;1;true]
        textlist[0.1,1.1;9.8,7.7;buildingname;x,y,z;2]
        button_exit[0.1,9;9.8,0.8;select;Select]
    ]]
end

minetest.register_tool("pick_and_place:palette", {
    description = "Placement configuration palette tool",
    inventory_image = "pick_and_place_palette.png^[colorize:#ffffff",
    stack_max = 1,
    range = 0,
    on_use = function(_, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)

    end,
    on_secondary_use = function(itemstack, player)
        local meta = itemstack:get_meta()
        local playername = player:get_player_name()
        local fs = get_formspec(meta)
        minetest.show_formspec(playername, FORMSPEC_NAME, fs)
    end,
    on_step = function(_, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)
        local text = pick_and_place.get_formatted_size(pointed_pos, nil)

        -- update preview
        pick_and_place.show_preview(
            playername,
            "pick_and_place_plus.png",
            "#0000ff",
            pointed_pos,
            nil,
            text
        )
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        pick_and_place.clear_preview(playername)
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMSPEC_NAME then
        return false
    end

    local itemstack = player:get_wielded_item()
    if itemstack:get_name() ~= "pick_and_place:palette" then
        return true
    end

    print(dump(fields))


    -- TODO

    return true
end)