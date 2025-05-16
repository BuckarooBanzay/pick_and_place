-- playername -> hud-id
local hud_data = {}

local function check_player_hud(player)
    local playername = player:get_player_name()
    local active_pos = pick_and_place.get_active_composition_pos()

    local name = ""
    if active_pos then
        local meta = minetest.get_meta(active_pos)
        name = meta:get_string("infotext")
    end

    if hud_data[playername] and not active_pos then
        -- active -> inactive
        player:hud_remove(hud_data[playername])
        hud_data[playername] = nil

    elseif not hud_data[playername] and active_pos then
        -- inactive -> active
        hud_data[playername] = player:hud_add({
            type = "waypoint",
            text = "m",
            name = name,
            number = 0x00FF00,
            world_pos = active_pos
        })

    elseif hud_data[playername] and active_pos then
        -- update
        player:hud_change(hud_data[playername], "name", name)
        player:hud_change(hud_data[playername], "world_pos", active_pos)

    end
end

minetest.register_on_joinplayer(check_player_hud)
minetest.register_on_leaveplayer(function(player)
    local playername = player:get_player_name()
    hud_data[playername] = nil
end)

function pick_and_place.update_composition_huds()
    for _, player in ipairs(minetest.get_connected_players()) do
        check_player_hud(player)
    end
end
