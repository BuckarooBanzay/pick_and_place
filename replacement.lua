local FORMSPEC_NAME = "pick_and_place:replacement"

local function get_formspec()

    return [[
        size[12,13]
        real_coordinates[true]
        label[0.5,0.5;Pick and place replacement mapping (source -> replacement)]
        list[current_player;pnp_replacement;0.3,1.2;2,5;0]
        list[current_player;pnp_replacement;3.3,1.2;2,5;10]
        list[current_player;pnp_replacement;6.3,1.2;2,5;20]
        list[current_player;pnp_replacement;9.3,1.2;2,5;30]
        list[current_player;main;1,7.5;8,4;]
        listring[]
    ]]
end

-- playername -> {source_id:replacement_id}
local replacements = {}

local function parse_replacements(player)
    local inv = player:get_inventory()
    local list = inv:get_list("pnp_replacement")
    local player_replacements = {}

    for i=1,#list,2 do
        local source_name = list[i]:get_name()
        local target_name = list[i+1]:get_name()

        if source_name ~= "" and
            target_name ~= "" and
            minetest.registered_nodes[source_name] and
            minetest.registered_nodes[target_name] then

            player_replacements[minetest.get_content_id(source_name)] = minetest.get_content_id(target_name)
        end
    end

    replacements[player:get_player_name()] = player_replacements
end

minetest.register_on_player_receive_fields(function(player, formname)
    if formname ~= FORMSPEC_NAME then
        return false
    end

    -- refresh replacements after formspec close
    parse_replacements(player)
    return true
end)

minetest.register_chatcommand("pnp_replace_global", {
    description = "configure per-player global replacements",
    func = function(playername)
        minetest.show_formspec(playername, FORMSPEC_NAME, get_formspec())
    end
})

minetest.register_on_joinplayer(function(player)
    local inv = player:get_inventory()
    inv:set_size("pnp_replacement", 20 * 2)

    -- initial parsing
    parse_replacements(player)
end)

-- returns a nodeid:replacement_id table
function pick_and_place.get_player_replacements(playername)
    return replacements[playername] or {}
end