
local char, byte = string.char, string.byte

local function encode_uint16(int)
	local a, b = int % 0x100, int / 0x100
	return char(a, b)
end

local function decode_uint16(str, ofs)
	ofs = ofs or 1
	local a = byte(str, ofs)
    local b = byte(str, ofs + 1)
	return a + b * 0x100
end

-- nodeid -> name
local nodeid_name_mapping = {}

function pick_and_place.serialize(pos1, pos2)
    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
	local param2 = manip:get_param2_data()

    local mapdata = {}
    local metadata = {}

    -- nodeid -> true
    local nodeids = {}

    for z=pos1.z,pos2.z do
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
        local i = area:index(x,y,z)
        nodeids[node_data[i]] = true
        table.insert(mapdata, encode_uint16(node_data[i]))
        table.insert(mapdata, char(param2[i]))
    end
    end
    end

    -- id -> name
    local nodeid_mapping = {}

    for nodeid in pairs(nodeids) do
        local name = nodeid_name_mapping[nodeid]
        if not name then
            name = minetest.get_name_from_content_id(nodeid)
            nodeid_name_mapping[nodeid] = name
        end

        nodeid_mapping[nodeid] = name
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

    local data = {
        version = 1,
        mapdata = table.concat(mapdata),
        metadata = metadata,
        nodeid_mapping = nodeid_mapping,
        size = vector.add(vector.subtract(pos2, pos1), 1)
    }

    local serialized_data = minetest.serialize(data)
    local compressed_data = minetest.compress(serialized_data, "deflate")
    local encoded_data = minetest.encode_base64(compressed_data)

    return encoded_data
end

-- name -> nodeid
local name_nodeid_mapping = {}

function pick_and_place.deserialize(pos1, encoded_data)
    local compressed_data = minetest.decode_base64(encoded_data)
    local serialized_data = minetest.decompress(compressed_data, "deflate")
    local data = minetest.deserialize(serialized_data)

    if data.version ~= 1 then
        return false, "invalid version: " .. (data.version or "nil")
    end

    local pos2 = vector.add(pos1, vector.subtract(data.size, 1))

    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
	local param2 = manip:get_param2_data()

    -- foreign_nodeid -> local_nodeid
    local localized_id_mapping = {}

    for foreign_nodeid, name in pairs(data.nodeid_mapping) do
        local local_nodeid = name_nodeid_mapping[name]
        if not local_nodeid then
            local_nodeid = minetest.get_content_id(name)
            name_nodeid_mapping[name] = local_nodeid
        end

        localized_id_mapping[foreign_nodeid] = local_nodeid
    end

    local j = 1
    for z=pos1.z,pos2.z do
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
        local i = area:index(x,y,z)
        local foreign_nodeid = decode_uint16(data.mapdata, j)

        -- localize nodeid mapping
        local local_nodeid = localized_id_mapping[foreign_nodeid]
        node_data[i] = local_nodeid

        j = j + 2
        param2[i] = byte(data.mapdata, j)
        j = j + 1
    end
    end
    end

    -- metadata
    for pos_str, meta_table in pairs(data.metadata) do
        local pos = minetest.string_to_pos(pos_str)
        local abs_pos = vector.add(pos1, pos)
        local meta = minetest.get_meta(abs_pos)
        meta:from_table(meta_table)
    end

    manip:set_data(node_data)
    manip:set_param2_data(param2)
    manip:write_to_map()

    return true
end
