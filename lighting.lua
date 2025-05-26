
minetest.register_node("pick_and_place:lighting_column", {
	description = "Pick and place lighting column",
	tiles = {"pick_and_place_lighting.png"},
	drawtype = "allfaces",
	use_texture_alpha = "blend",
	paramtype = "light",
    light_source = 14,
	sunlight_propagates = true,
	groups = {
		oddly_breakable_by_hand = 3
	}
})

minetest.register_node("pick_and_place:lighting_node", {
	description = "Pick and place artifical lighting ",
    inventory_image = "pick_and_place_lighting.png",
	drawtype = "airlike",
    light_source = 14,
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	buildable_to = true,
	diggable = false,
	pointable = false,
	groups = {
        not_in_creative_inventory = 1
    }
})

local lighting_node_cid = minetest.get_content_id("pick_and_place:lighting_node")
local lighting_column_cid = minetest.get_content_id("pick_and_place:lighting_column")
local air_cid = minetest.get_content_id("air")

local column_range = 32

pick_and_place.register_on_place(function(pos1, pos2, node_ids)
    if not node_ids[lighting_column_cid] then
        return
    end

    -- lighting column end position a few mapblocks lower
    pos1 = vector.subtract(pos1, { x = 0, y = 16*3, z = 0})

    -- all lighting column spawners
    local poslist = minetest.find_nodes_in_area(pos1, pos2, {"pick_and_place:lighting_column"})

    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()

    for _, pos in ipairs(poslist) do
        for y = pos.y, pos.y-column_range, -1 do
            local i = area:index(pos.x,y,pos.z)
            -- replace air and column nodes with light node
            if node_data[i] == air_cid or node_data[i] == lighting_column_cid then
                node_data[i] = lighting_node_cid
            else
                break
            end
        end
    end

    manip:set_data(node_data)
    manip:write_to_map()
end)