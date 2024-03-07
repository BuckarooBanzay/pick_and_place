local FORMSPEC_NAME = "pick_and_place:place"

local has_mapsync = minetest.get_modpath("mapsync")
local has_blockexchange = minetest.get_modpath("blockexchange")

local function get_pos(meta, player)
    local size = minetest.string_to_pos(meta:get_string("size"))
    local distance = vector.distance(vector.new(), size)
    local radius = math.ceil(distance / 2)
    local offset = vector.round(vector.divide(size, 2))

    local pos1 = pick_and_place.get_pointed_position(player, radius + 2)
    pos1 = vector.subtract(pos1, offset)
    local pos2 = vector.add(pos1, vector.subtract(size, 1))

    return pos1, pos2
end

-- notify supported mods of changes
local function notify_change(pos1, pos2)
    if has_blockexchange then
        blockexchange.mark_changed(pos1, pos2)
    end
    if has_mapsync then
        mapsync.mark_changed(pos1, pos2)
    end
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

        local pos1, pos2 = get_pos(meta, player)

        if controls.aux1 then
            -- removal
            pick_and_place.remove_area(pos1, pos2)
            notify_change(pos1, pos2)
        else
            -- placement
            local disable_replacements = controls.zoom
            local schematic = meta:get_string("schematic")
            local success, msg = pick_and_place.deserialize(pos1, schematic, disable_replacements)
            if not success then
                minetest.chat_send_player(playername, "Placement error: " .. msg)
            else
                notify_change(pos1, pos2)
            end
        end
    end,
    on_secondary_use = function(_, player)
        local playername = player:get_player_name()

        -- show name input
        minetest.show_formspec(playername, FORMSPEC_NAME, [[
            size[9,1]
            real_coordinates[true]
            button_exit[0.1,0.1;2.8,0.8;deg90;90°]
            button_exit[3.1,0.1;2.8,0.8;deg180;180°]
            button_exit[6.1,0.1;2.8,0.8;deg270;270°]
        ]])
    end,
    on_step = function(itemstack, player)
        local playername = player:get_player_name()
        local controls = player:get_player_control()

        local meta = itemstack:get_meta()
        local pos1, pos2 = get_pos(meta, player)

        if controls.aux1 then
            -- removal preview
            pick_and_place.show_preview(playername, "pick_and_place_minus.png", "#ff0000", pos1, pos2)
        else
            -- build preview
            pick_and_place.show_preview(playername, "pick_and_place_plus.png", "#0000ff", pos1, pos2)
        end
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

    local rotation = 0
    if fields.deg90 then
        rotation = 90
    elseif fields.deg180 then
        rotation = 180
    elseif fields.deg270 then
        rotation = 270
    end

    if rotation == 0 then
        -- nothing to do
        return true
    end

    local itemstack = player:get_wielded_item()
    local success, err = pick_and_place.rotate_tool(itemstack, rotation)
    if not success then
        minetest.chat_send_player(player:get_player_name(), "Rotation error: " .. err)
        return true
    end

    -- set tool
    player:set_wielded_item(itemstack)

    return true
end)