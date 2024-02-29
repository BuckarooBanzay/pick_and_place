
-- rotates the size for a given rotation
function pick_and_place.rotate_size(size, rotation)
    if rotation == 90 or rotation == 270 then
        -- invert x/z
        return {
            x = size.z,
            y = size.y,
            z = size.x
        }
    end
    -- unchanged in 180 or 0 degrees
    return size
end

-- look direction in 90-degree increments
function pick_and_place.get_player_rotation(player)
	local yaw = player:get_look_horizontal()
	local degrees = yaw / math.pi * 180
	local rotation = 0
	if degrees > 45 and degrees < (90+45) then
		-- x-
		rotation = 180
	elseif degrees > (90+45) and degrees < (180+45) then
		-- z-
		rotation = 90
	elseif degrees < 45 or degrees > (360-45) then
		-- z+
		rotation = 270
	end
	return rotation
end
