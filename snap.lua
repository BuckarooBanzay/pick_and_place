
-- playername -> pos
local origin_map = {}

-- playername -> size
local size_map = {}

minetest.register_on_joinplayer(function(player)
    local meta = player:get_meta()
    local origin = meta:get_string("pnp_snap_origin")
    local size = meta:get_string("pnp_snap_size")

    if origin == "" or size == "" then
        return
    end

    local playername = player:get_player_name()
    origin_map[playername] = minetest.string_to_pos(origin)
    size_map[playername] = minetest.string_to_pos(size)
end)

local function save(playername)
    local player = minetest.get_player_by_name(playername)
    if not player then
        return
    end

    local meta = player:get_meta()

    if not origin_map[playername] or not size_map[playername] then
        meta:set_string("pnp_snap_origin", "")
        meta:set_string("pnp_snap_size", "")
        return
    end

    meta:set_string("pnp_snap_origin", minetest.pos_to_string(origin_map[playername]))
    meta:set_string("pnp_snap_size", minetest.pos_to_string(size_map[playername]))
end

local function snap_axis(axis, origin, size, pos)
    local half_size = math.ceil(size[axis] / 2)

    -- delta from origin
    local diff = pos[axis] - origin[axis]
    local o = diff % size[axis]
    if o >= half_size then
        -- round up
        pos[axis] = pos[axis] + (size[axis] - o)
    elseif o > 0 then
        -- round down
        pos[axis] = pos[axis] - o
    end
end

function pick_and_place.get_placement_pos(size, player)
    local distance = vector.distance(vector.new(), size)
    local radius = math.ceil(distance / 2)
    local offset = vector.round(vector.divide(size, 2))
    local playername = player:get_player_name()

    local pos1 = pick_and_place.get_pointed_position(player, radius + 2)
    pos1 = vector.subtract(pos1, offset)

    local origin = origin_map[playername]
    local snap_size = size_map[playername]
    if origin and snap_size then
        -- apply grid-snapping
        snap_axis("x", origin, snap_size, pos1)
        snap_axis("y", origin, snap_size, pos1)
        snap_axis("z", origin, snap_size, pos1)
    end

    local pos2 = vector.add(pos1, vector.subtract(size, 1))
    return pos1, pos2
end

function pick_and_place.is_snap_enabled(player)
    local meta = player:get_meta()
    local origin = meta:get_string("pnp_snap_origin")
    local size = meta:get_string("pnp_snap_size")

    return origin ~= "" and size ~= ""
end

function pick_and_place.enable_snap(player)
    if not player then
        return false, "player not found"
    end

    local playername = player:get_player_name()
    local itemstack = player:get_wielded_item()

    if itemstack:get_name() == "pick_and_place:place" then
        local meta = itemstack:get_meta()
        local size = minetest.string_to_pos(meta:get_string("size"))
        local pos1 = pick_and_place.get_placement_pos(size, player)

        origin_map[playername] = pos1
        size_map[playername] = size

    elseif itemstack:get_name() == "pick_and_place:palette" then
        local meta = itemstack:get_meta()

        local id = meta:get_string("id")
        if not id then
            return
        end

        local template = pick_and_place.get_template(id)
        if not template then
            return
        end

        local rotation = meta:get_int("rotation")
        local size = pick_and_place.get_template_size(template)
        size = pick_and_place.rotate_size(size, rotation)
        local pos1 = pick_and_place.get_placement_pos(size, player)

        origin_map[playername] = pos1
        size_map[playername] = size
    else
        return false, "no valid tool selected"
    end

    save(playername)
end

function pick_and_place.disable_snap(player)
    local playername = player:get_player_name()
    origin_map[playername] = nil
    size_map[playername] = nil

    save(playername)
end

minetest.register_chatcommand("pnp_snap", {
    params = "[on|off]",
    description = "enable or disable grid snapping with the current placement tool dimensions and origin",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)

        if param == "on" then
            -- enable grid
            local success, msg = pick_and_place.enable_snap(player)
            if not success then
                return false, msg
            end

        elseif param == "off" then
            -- disable grid
            pick_and_place.disable_snap(player)
        end


        if origin_map[name] then
            return true, "grid set with origin: " .. minetest.pos_to_string(origin_map[name]) ..
                " and size: " .. minetest.pos_to_string(size_map[name])
        else
            return true, "grid disabled"
        end
    end
})