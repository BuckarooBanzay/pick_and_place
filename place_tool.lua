local has_mapsync = minetest.get_modpath("mapsync")

local function extract_schematic_info(meta, player)
    local size = minetest.string_to_pos(meta:get_string("size"))
    local distance = vector.distance(vector.new(), size)
    local radius = math.ceil(distance / 2)
    local offset = vector.round(vector.divide(size, 2))

    local player_rotation = pick_and_place.get_player_rotation(player)
    local pickup_rotation = meta:get_int("rotation")

    -- placement rotation from 0 to 270 degrees
    local rotation = player_rotation - pickup_rotation
    if rotation < 0 then rotation = rotation + 360 end
    if rotation > 270 then rotation = rotation - 360 end

    -- rotation building size
    size = pick_and_place.rotate_size(size, rotation)

    local pos1 = pick_and_place.get_pointed_position(player, radius + 2)
    pos1 = vector.subtract(pos1, offset)
    local pos2 = vector.add(pos1, vector.subtract(size, 1))

    return pos1, pos2, rotation
end

minetest.register_tool("pick_and_place:place", {
    description = "Placement tool",
    inventory_image = "pick_and_place_plus.png^[colorize:#0000ff",
    stack_max = 1,
    range = 0,
    groups = {
        not_in_creative_inventory = 1
    },
    on_use = function(itemstack, player)
        local playername = player:get_player_name()
        local controls = player:get_player_control()

        local meta = itemstack:get_meta()

        local pos1, pos2, rotation = extract_schematic_info(meta, player)

        if controls.aux1 then
            -- removal
            pick_and_place.remove_area(pos1, pos2)
        else
            -- placement
            local schematic = meta:get_string("schematic")
            local success, msg = pick_and_place.deserialize(pos1, schematic, rotation)
            if not success then
                minetest.chat_send_player(playername, "Placement error: " .. msg)
            end
        end
    end,
    on_step = function(itemstack, player)
        local playername = player:get_player_name()
        local controls = player:get_player_control()

        local meta = itemstack:get_meta()
        local pos1, pos2 = extract_schematic_info(meta, player)

        if controls.aux1 then
            -- removal preview
            pick_and_place.show_preview(playername, "pick_and_place_minus.png", "#ff0000", pos1, pos2)
        else
            -- build preview
            pick_and_place.show_preview(playername, "pick_and_place_plus.png", "#0000ff", pos1, pos2)
        end

        if has_mapsync then
            mapsync.mark_changed(pos1, pos2)
        end
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        pick_and_place.clear_preview(playername)
    end
})
