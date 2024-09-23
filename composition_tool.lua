local FORMSPEC_NAME = "pick_and_place:composition"

local function get_formspec()
    return [[
        size[10,2]
        real_coordinates[true]

        label[0,0.5;Name]
        field[2,0;8,1;name;;]

        button_exit[0,1;10,1;save;Save]
    ]]
end

minetest.register_tool("pick_and_place:composition", {
    description = "Composition tool (new)",
    inventory_image = "pick_and_place_composition.png",
    stack_max = 1,
    range = 0,
    color = "#0000ff",
    on_use = function(itemstack, player)
        local meta = itemstack:get_meta()
        local playername = player:get_player_name()
        minetest.show_formspec(playername, FORMSPEC_NAME, get_formspec(player, meta))
    end
})

minetest.register_on_player_receive_fields(function(player, formname)
    if formname ~= FORMSPEC_NAME then
        return false
    end

    local itemstack = player:get_wielded_item()
    if itemstack:get_name() ~= "pick_and_place:composition" then
        return true
    end

    local meta = itemstack:get_meta()
    meta:set_string("description", "Composition")
    meta:set_string("color", "#00ff00")

    player:set_wielded_item(itemstack)
    -- TODO

    return true
end)