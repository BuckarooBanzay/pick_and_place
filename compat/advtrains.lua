assert(type(advtrains.ndb.update) == "function")

local advtrains_nodeids = {}

minetest.register_on_mods_loaded(function()
    for nodename, nodedef in pairs(minetest.registered_nodes) do
        if nodedef.groups and nodedef.groups.save_in_at_nodedb then
            advtrains_nodeids[minetest.get_content_id(nodename)] = true
        end
    end
end)

-- area-key -> table[pos]
local removed_nodes = {}

local function get_area_key(pos1, pos2)
    return minetest.pos_to_string(pos1) .. "-" .. minetest.pos_to_string(pos2)
end

-- register to be removed nodedb positions
pick_and_place.register_on_before_remove(function(pos1, pos2, node_ids)
    if not advtrains_nodeids[node_ids] then
        -- nothing to do
        return
    end

    local poslist = minetest.find_nodes_in_area(pos1, pos2, {"group:save_in_at_nodedb"})
    local areakey = get_area_key(pos1, pos2)
    removed_nodes[areakey] = poslist
end)

-- update removed nodedb positions
pick_and_place.register_on_remove(function(pos1, pos2)
    local areakey = get_area_key(pos1, pos2)
    local poslist = removed_nodes[areakey]
    if not poslist then
        return
    end
    removed_nodes[areakey] = nil

    for _, pos in ipairs(poslist) do
        advtrains.ndb.update(pos)
    end
end)

-- update all nodedb positions
pick_and_place.register_on_place(function(pos1, pos2, node_ids)
    if not advtrains_nodeids[node_ids] then
        -- nothing to do
        return
    end

    local poslist = minetest.find_nodes_in_area(pos1, pos2, {"group:save_in_at_nodedb"})
    for _, pos in ipairs(poslist) do
        advtrains.ndb.update(pos)
    end
end)