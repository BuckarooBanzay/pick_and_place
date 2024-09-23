local air_cid = minetest.get_content_id("air")
local replacement_cid = minetest.get_content_id("pick_and_place:replacement")

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
    for y=pos1.y,pos2.y do
    for x=pos1.x,pos2.x do
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

    return {
        node_id_data = node_id_data,
        param2_data = param2_data,
        metadata = metadata,
        size = vector.add(vector.subtract(pos2, pos1), 1)
    }
end

-- table: fn(pos1, pos2, node_ids)
local place_callbacks = {}
local before_place_callbacks = {}

function pick_and_place.deserialize(pos1, schematic, disable_replacements)
    local pos2 = vector.add(pos1, vector.subtract(schematic.size, 1))

    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
	local param2 = manip:get_param2_data()
    local node_ids = {}

    local disabled_metadata_placement = {}

    local ctx = {}
    local j = 1
    for z=pos1.z,pos2.z do
    for y=pos1.y,pos2.y do
    for x=pos1.x,pos2.x do
        local i = area:index(x,y,z)
        local nodeid = schematic.node_id_data[j]
        node_ids[nodeid] = true

        if nodeid == replacement_cid and not disable_replacements then
            -- replacement placement
            local abs_pos = {x=x, y=y, z=z}
            local rel_pos = vector.subtract(abs_pos, pos1)
            local pos_str = minetest.pos_to_string(rel_pos)
            local metadata = schematic.metadata[pos_str]
            local repl_id = pick_and_place.get_replacement_nodeid(ctx, metadata)
            if repl_id then
                -- set new node
                node_data[i] = repl_id
                param2[i] = schematic.param2_data[j]
                -- mark metadata to not deserialize
                disabled_metadata_placement[pos_str] = true
            end
        elseif nodeid ~= air_cid then
            -- normal placement
            node_data[i] = nodeid
            param2[i] = schematic.param2_data[j]
        end
        j = j + 1
    end
    end
    end

    for _, fn in ipairs(before_place_callbacks) do
        fn(pos1, pos2, node_ids)
    end

    -- set nodeid's and param2
    manip:set_data(node_data)
    manip:set_param2_data(param2)
    manip:write_to_map()

    -- set metadata
    for pos_str, meta_table in pairs(schematic.metadata) do
        if not disabled_metadata_placement[pos_str] then
            local pos = minetest.string_to_pos(pos_str)
            local abs_pos = vector.add(pos1, pos)
            local meta = minetest.get_meta(abs_pos)
            meta:from_table(meta_table)
        end
    end

    for _, fn in ipairs(place_callbacks) do
        fn(pos1, pos2, node_ids)
    end

    return true
end

function pick_and_place.register_on_place(fn)
    table.insert(place_callbacks, fn)
end

function pick_and_place.register_on_before_place(fn)
    table.insert(before_place_callbacks, fn)
end