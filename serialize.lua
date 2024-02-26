local air_cid = minetest.get_content_id("air")

function pick_and_place.serialize(pos1, pos2)
    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
	local param2 = manip:get_param2_data()

    local node_id_data = {}
    local param2_data = {}
    local metadata = {}

    for z=pos1.z,pos2.z do
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
        local i = area:index(x,y,z)
        table.insert(node_id_data, node_data[i])
        table.insert(param2_data, param2[i])
    end
    end
    end

    -- store metadata
    local nodes_with_meta = minetest.find_nodes_with_meta(pos1, pos2)
    for _, pos in ipairs(nodes_with_meta) do
        local rel_pos = vector.subtract(pos, pos1)
        local meta = minetest.get_meta(pos)
        local meta_table = meta:to_table()

        -- Convert metadata item stacks to item strings
        for _, invlist in pairs(meta_table.inventory) do
            for index = 1, #invlist do
                local itemstack = invlist[index]
                if itemstack.to_string then
                    invlist[index] = itemstack:to_string()
                end
            end
        end

        metadata[minetest.pos_to_string(rel_pos)] = meta_table
    end

    local schematic = {
        node_id_data = table.concat(node_id_data),
        param2_data = table.concat(param2_data),
        metadata = metadata,
        size = vector.add(vector.subtract(pos2, pos1), 1)
    }

    return pick_and_place.encode_schematic(schematic)
end


function pick_and_place.deserialize(pos1, encoded_data)
    local schematic, err = pick_and_place.decode_schematic(encoded_data)
    if err then
        return false, "Decode error: " .. err
    end

    local pos2 = vector.add(pos1, vector.subtract(schematic.size, 1))

    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
	local param2 = manip:get_param2_data()

    for z=pos1.z,pos2.z do
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
        local i = area:index(x,y,z)

        -- localize nodeid mapping
        local nodeid = schematic.node_id_data[i]

        if nodeid ~= air_cid then
            node_data[i] = nodeid
            param2[i] = schematic.param2_data[i]
        end
    end
    end
    end

    -- set metadata
    for pos_str, meta_table in pairs(schematic.metadata) do
        local pos = minetest.string_to_pos(pos_str)
        local abs_pos = vector.add(pos1, pos)
        local meta = minetest.get_meta(abs_pos)
        meta:from_table(meta_table)
    end

    -- set nodeid's and param2
    manip:set_data(node_data)
    manip:set_param2_data(param2)
    manip:write_to_map()

    return true
end
