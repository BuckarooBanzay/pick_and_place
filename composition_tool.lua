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

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMSPEC_NAME then
        return false
    end

    local itemstack = player:get_wielded_item()
    if itemstack:get_name() ~= "pick_and_place:composition" then
        return true
    end

    if fields.record then
        pick_and_place.record_composition(itemstack)
    elseif fields.pause then
        pick_and_place.pause_composition(itemstack)
    elseif fields.play then
        pick_and_place.play_composition(itemstack)
    elseif fields.set_origin then
        pick_and_place.set_composition_origin(itemstack)
    end

    player:set_wielded_item(itemstack)

    return true
end)