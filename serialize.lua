
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

function pick_and_place.serialize(pos1, pos2)
    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
	local param2 = manip:get_param2_data()

    local mapdata = {}
    local metadata = {}

    for z=pos1.z,pos2.z do
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
        local i = area:index(x,y,z)
        table.insert(mapdata, encode_uint16(node_data[i]))
        table.insert(mapdata, char(param2[i]))
    end
    end
    end

    -- TODO: metadata

    local size = vector.add(vector.subtract(pos2, pos1), 1)

    local data = {
        mapdata = table.concat(mapdata),
        metadata = metadata,
        size = size
    }

    local serialized_data = minetest.serialize(data)
    local compressed_data = minetest.compress(serialized_data, "deflate")
    local encoded_data = minetest.encode_base64(compressed_data)

    -- TODO
    print(dump({
        fn = "pick_and_place.serialize",
        size = data.size,
        serialized_data_len = #serialized_data,
        compressed_data_len = #compressed_data,
        encoded_data_len = #encoded_data
    }))

    return encoded_data
end


function pick_and_place.deserialize(pos1, encoded_data)

    local compressed_data = minetest.decode_base64(encoded_data)
    local serialized_data = minetest.decompress(compressed_data, "deflate")
    local data = minetest.deserialize(serialized_data)

    local pos2 = vector.add(pos1, vector.subtract(data.size, 1))

    local manip = minetest.get_voxel_manip()
	local e1, e2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})

    local node_data = manip:get_data()
	local param2 = manip:get_param2_data()

    local j = 1

    for z=pos1.z,pos2.z do
    for x=pos1.x,pos2.x do
    for y=pos1.y,pos2.y do
        local i = area:index(x,y,z)
        node_data[i] = decode_uint16(data.mapdata, j)
        j = j + 2
        param2[i] = byte(data.mapdata, j)
        j = j + 1
    end
    end
    end

    manip:set_data(node_data)
    manip:set_param2_data(param2)
    manip:write_to_map()
end
