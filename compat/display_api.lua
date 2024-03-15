local display_nodeids = {}

minetest.register_on_mods_loaded(function()
    for nodename, nodedef in pairs(minetest.registered_nodes) do
        if nodedef.groups and nodedef.groups.display_api then
            display_nodeids[minetest.get_content_id(nodename)] = true
        end
    end
end)

pick_and_place.register_on_place(function(pos1, pos2, nodeids)
    local match = false
    for display_nodeid in pairs(display_nodeids) do
        if nodeids[display_nodeid] then
            match = true
        end
    end

    if not match then
        return
    end

    local poslist = minetest.find_nodes_in_area(pos1, pos2, {"group:display_api"})
    for _, pos in ipairs(poslist) do
        display_api.update_entities(pos)
    end
end)
