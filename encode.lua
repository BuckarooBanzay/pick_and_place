
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

function pick_and_place.encode_schematic(schematic)
    -- list of strings
    local node_id_data = {}
    local param2_data = {}
    local nodeid_mapping = {}

    -- nodeid -> true
    local nodeids = {}

    for i = 1, #schematic.node_id_data do
        local node_id = schematic.node_id_data[i]
        nodeids[node_id] = true
        table.insert(node_id_data, encode_uint16(node_id))
        table.insert(param2_data, char(schematic.param2_data[i]))
    end

    for nodeid in pairs(nodeids) do
        local name = nodeid_name_mapping[nodeid]
        if not name then
            name = minetest.get_name_from_content_id(nodeid)
            nodeid_name_mapping[nodeid] = name
        end

        nodeid_mapping[nodeid] = name
    end

    local serialized_data = minetest.serialize({
        version = 2,
        node_id_data = table.concat(node_id_data),
        param2_data = table.concat(param2_data),
        metadata = schematic.metadata,
        nodeid_mapping = nodeid_mapping,
        size = schematic.size
    })
    local compressed_data = minetest.compress(serialized_data, "deflate")
    local encoded_data = minetest.encode_base64(compressed_data)

    return encoded_data
end

-- name -> nodeid
local name_nodeid_mapping = {}

function pick_and_place.decode_schematic(encoded_data)
    local compressed_data = minetest.decode_base64(encoded_data)
    local serialized_data = minetest.decompress(compressed_data, "deflate")
    local data = minetest.deserialize(serialized_data)

    if data.version ~= 2 then
        return false, "invalid version: " .. (data.version or "nil")
    end

    local schematic = {
        node_id_data = {},
        param2_data = {},
        metadata = data.metadata,
        size = data.size
    }

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

    for i = 1, #data.param2_data do
        -- localize nodeid mapping
        local foreign_nodeid = decode_uint16(data.node_id_data, 1 + ((i-1) * 2))
        local local_nodeid = localized_id_mapping[foreign_nodeid]

        table.insert(schematic.node_id_data, local_nodeid)
        table.insert(schematic.param2_data, byte(data.param2_data, i))
    end

    return schematic
end