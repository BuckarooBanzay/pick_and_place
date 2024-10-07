local FORMSPEC_NAME = "pick_and_place:composition"

local function get_formspec(_, meta)
    local name = minetest.formspec_escape(meta:get_string("name"))
    local id = meta:get_string("id")

    local origin = meta:get_string("origin")
    local data = meta:get_string("data")
    local bytes = #data
    local entries = meta:get_int("entries")

    local state = meta:get_string("state")

    return [[
        size[10,5]
        real_coordinates[true]

        label[0.1,0.5;Name]
        field[2,0;6,1;name;;]] .. name .. [[]
        button_exit[8,0;2,1;save;Save]

        label[0.1,1.5;Origin]
        label[2.1,1.5;]] .. (origin ~= "" and origin or "<not set>") .. [[]
        button_exit[6,1;2,1;set_origin;Set origin]
        button_exit[8,1;2,1;tp_origin;Teleport]

        label[0.1,2.5;Stats]
        label[2,2.5;]] .. "ID: " .. id .. " Entries: " .. entries .. " / " .. bytes .. " bytes" .. [[]

        label[0.1,3.5;Status]
        label[2,3.5;]] .. "Not active" .. [[]

        label[0.1,4.5;Actions]
        button_exit[2,4;4,1;]] .. (state == "record" and "pause;Pause" or "record;Record") .. [[]
        button_exit[6,4;4,1;playback;Playback]
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
        pick_and_place.update_composition_tool(meta)
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

    local playername = player:get_player_name()
    if fields.save then
        pick_and_place.update_composition_fields(itemstack, playername, fields)
    elseif fields.record then
        pick_and_place.record_composition(itemstack, playername)
    elseif fields.pause then
        pick_and_place.pause_composition(itemstack, playername)
    elseif fields.playback then
        pick_and_place.play_composition(itemstack, playername)
    elseif fields.set_origin then
        pick_and_place.set_composition_origin(itemstack, playername)
    elseif fields.tp_origin then
        pick_and_place.tp_composition_origin(itemstack, playername)

    end

    player:set_wielded_item(itemstack)

    return true
end)