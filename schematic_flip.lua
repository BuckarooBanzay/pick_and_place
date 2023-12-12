
local function flip_data(data, size, indexFn, axis)
	local pos = {x=0, y=0, z=0}
	local max = { x=size.x, y=size.y, z=size.z }
	local start = max[axis]
	max[axis] = math.floor(max[axis] / 2)

	while pos.x <= max.x do
		pos.y = 0
		while pos.y <= max.y do
			pos.z = 0
			while pos.z <= max.z do
				local data_1 = data[indexFn(pos)]
				local value = pos[axis] -- Save position
				pos[axis] = start - value -- Shift position
				local data_2 = data[indexFn(pos)]
				data[indexFn(pos)] = data_1
				pos[axis] = value -- Restore position
				data[indexFn(pos)] = data_2
				pos.z = pos.z + 1
			end
			pos.y = pos.y + 1
		end
		pos.x = pos.x + 1
	end
end

function pick_and_place.schematic_flip(node_ids, param2_data, metadata, max, axis)
    local min = { x=0, y=0, z=0 }
	local area = VoxelArea:new({MinEdge=min, MaxEdge=max})

	local vmanipIndex = function(pos) return area:indexp(pos) end
	local metaIndex = function(pos) return minetest.pos_to_string(pos) end

	flip_data(node_ids, max, vmanipIndex, axis)
	flip_data(param2_data, max, vmanipIndex, axis)

	if metadata then
		flip_data(metadata, max, metaIndex, axis)
	end
end
