local function flip_pos(rel_pos, max, axis)
	rel_pos[axis] = max[axis] - rel_pos[axis]
end

local function transpose_pos(rel_pos, axis1, axis2)
	rel_pos[axis1], rel_pos[axis2] = rel_pos[axis2], rel_pos[axis1]
end

--- rotate a position around the y axis
-- @param rel_pos @{node_pos} the relative position to rotate
-- @param max @{node_pos} the maximum position to rotate in
-- @param rotation_y the clock-wise rotation, either 0,90,180 or 270
-- @return @{node_pos} the rotated position
function pick_and_place.rotate_pos(rel_pos, max_pos, rotation_y)
	local new_pos = {x=rel_pos.x, y=rel_pos.y, z=rel_pos.z}
	if rotation_y == 90 then
		flip_pos(new_pos, max_pos, "x")
		transpose_pos(new_pos, "x", "z")
	elseif rotation_y == 180 then
		flip_pos(new_pos, max_pos, "x")
		flip_pos(new_pos, max_pos, "z")
	elseif rotation_y == 270 then
		flip_pos(new_pos, max_pos, "z")
		transpose_pos(new_pos, "x", "z")
	end
	return new_pos
end

--- rotate a size vector
-- @param size @{node_pos} a size vector
-- @param rotation_y the clock-wise rotation, either 0,90,180 or 270
-- @return @{node_pos} the rotated size
function pick_and_place.rotate_size(size, rotation_y)
	local new_size = {x=size.x, y=size.y, z=size.z}
	if rotation_y == 90 or rotation_y == 270 then
		-- swap x and z axes
		transpose_pos(new_size, "x", "z")
	end
	return new_size
end

function pick_and_place.schematic_rotate(node_ids, param2_data, metadata, max, rotation)
    if rotation <= 0 or rotation > 270 then
        -- invalid or no rotation
        return
    end

    local other1, other2 = "x", "z"

    if rotation == 90 then
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other1)
        pick_and_place.schematic_transpose(node_ids, param2_data, metadata, max, other1, other2)
    elseif rotation == 180 then
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other1)
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other2)
    elseif rotation == 270 then
        pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, other1)
        pick_and_place.schematic_transpose(node_ids, param2_data, metadata, max, other1, other2)
    end

    pick_and_place.schematic_orient(node_ids, param2_data, max, rotation)
end

