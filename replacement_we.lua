local function check_region(name)
	return worldedit.volume(worldedit.pos1[name], worldedit.pos2[name])
end

worldedit.register_command("pnp_replace", {
    params = "<group>",
	description = "transform the worldedit selection to replacement nodes",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
    parse = function(param)
		return true, param
	end,
	func = function(playername, groupname)
        local pos1 = worldedit.pos1[playername]
        local pos2 = worldedit.pos2[playername]
        pos1, pos2 = vector.sort(pos1, pos2)

        if not pos1 or not pos2 then
            return false, "pos1 or pos2 not defined"
        end
        minetest.load_area(pos1, pos2)

        local count = 0
        for x = pos1.x, pos2.x do
            for y = pos1.y, pos2.y do
                for z = pos1.z, pos2.z do
                    local pos = vector.new(x,y,z)
                    local node = minetest.get_node(pos)
                    local node_def = minetest.registered_nodes[node.name]

                    if node_def then
                        if node_def.paramtype2 == "wallmounted" then
                            pick_and_place.convert_to_replacement_wallmounted(pos, node, groupname)
                        else
                            pick_and_place.convert_to_replacement(pos, node, groupname)
                        end
                        count = count + 1
                    end
                end
            end
        end

        worldedit.player_notify(playername, count .. " nodes replaced")
    end
})


worldedit.register_command("pnp_replace_add", {
    params = "<nodename>",
	description = "adds another node to the replacement nodes in the area",
	privs = {worldedit=true},
	require_pos = 2,
	nodes_needed = check_region,
    parse = function(param)
		return true, param
	end,
	func = function(playername, nodename)
        local pos1 = worldedit.pos1[playername]
        local pos2 = worldedit.pos2[playername]
        pos1, pos2 = vector.sort(pos1, pos2)

        if not minetest.registered_nodes[nodename] then
            return false, "unknown nodename: " .. nodename
        end

        if not pos1 or not pos2 then
            return false, "pos1 or pos2 not defined"
        end
        minetest.load_area(pos1, pos2)

        local count = 0
        for x = pos1.x, pos2.x do
            for y = pos1.y, pos2.y do
                for z = pos1.z, pos2.z do
                    local pos = vector.new(x,y,z)
                    local node = minetest.get_node(pos)
                    local node_def = minetest.registered_nodes[node.name]

                    if node_def and node_def.groups.pnp_replacement_node then
                        local meta = minetest.get_meta(pos)
                        local inv = meta:get_inventory()
                        inv:add_item("main", ItemStack(nodename .. " 1"))
                        count = count + 1
                    end
                end
            end
        end

        worldedit.player_notify(playername, count .. " nodes changed")
    end
})