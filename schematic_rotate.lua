local zero = { x=0, y=0, z=0 }

-- creates a buffer for the rotation
local function create_buffer(data, size, max)
    local area_src = VoxelArea:new({MinEdge=zero, MaxEdge=size})
    local area_dst = VoxelArea:new({MinEdge=zero, MaxEdge=max})

    local buf = {}

    for z=0,size.z do
    for x=0,size.x do
    for y=0,size.y do
        local i_src = area_src:index(x,y,z)
        local i_dst = area_dst:index(x,y,z)
        buf[i_dst] = data[i_src]
    end
    end
    end

    return buf
end

-- extracts the rotated new size from the buffer
local function extract_from_buffer(buf, size, max, offset)
    local area_src = VoxelArea:new({MinEdge=zero, MaxEdge=max})
    local area_dst = VoxelArea:new({MinEdge=zero, MaxEdge=size})

    local data = {}

    for z=0,size.z do
    for x=0,size.x do
    for y=0,size.y do
        local i_src = area_src:index(x+offset.x,y+offset.y,z+offset.z)
        local i_dst = area_dst:index(x,y,z)
        data[i_dst] = buf[i_src]
    end
    end
    end

    return data
end

function pick_and_place.schematic_rotate(schematic, rotation)
    if rotation <= 0 or rotation > 270 then
        -- invalid or no rotation
        return
    end

    local other1, other2 = "x", "z"
    local rotated_size = pick_and_place.rotate_size(schematic.size, rotation)

    local metadata = schematic.metadata

    local max_xz_axis = math.max(schematic.size.x, schematic.size.z)
    local max = { x=max_xz_axis-1, y=schematic.size.y-1, z=max_xz_axis-1 }

    -- create transform buffers
    local node_id_buf = create_buffer(schematic.node_id_data, vector.subtract(schematic.size, 1), max)
    local param2_buf = create_buffer(schematic.param2_data, vector.subtract(schematic.size, 1), max)

    -- rotate
    if rotation == 90 then
        pick_and_place.schematic_flip(node_id_buf, param2_buf, metadata, max, other1)
        pick_and_place.schematic_transpose(node_id_buf, param2_buf, metadata, max, other1, other2)
    elseif rotation == 180 then
        pick_and_place.schematic_flip(node_id_buf, param2_buf, metadata, max, other1)
        pick_and_place.schematic_flip(node_id_buf, param2_buf, metadata, max, other2)
    elseif rotation == 270 then
        pick_and_place.schematic_transpose(node_id_buf, param2_buf, metadata, max, other1, other2)
        pick_and_place.schematic_flip(node_id_buf, param2_buf, metadata, max, other1)
    end

    -- extract from buffer with offset
    local offset = {x=0, y=0, z=0}
    local z_larger = schematic.size.z > schematic.size.x
    local x_larger = schematic.size.z < schematic.size.x
    local xz_diff = math.abs(schematic.size.x - schematic.size.z)
    if rotation == 90 then
        if z_larger then
            offset.z = xz_diff
        end
    elseif rotation == 180 then
        if x_larger then
            offset.z = xz_diff
        elseif z_larger then
            offset.x = xz_diff
        end
    elseif rotation == 270 then
        if x_larger then
            offset.x = xz_diff
        end
    end
    schematic.node_id_data = extract_from_buffer(node_id_buf, vector.subtract(rotated_size, 1), max, offset)
    schematic.param2_data = extract_from_buffer(param2_buf, vector.subtract(rotated_size, 1), max, offset)

    -- rotate size
    schematic.size = rotated_size

    -- orient rotated schematic
    pick_and_place.schematic_orient(
        schematic.node_id_data,
        schematic.param2_data,
        vector.subtract(rotated_size, 1),
        rotation
    )
end

