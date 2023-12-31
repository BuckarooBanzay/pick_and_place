
--- sorts the position by ascending order
-- @param pos1 @{node_pos} the first position
-- @param pos2 @{node_pos} the second position
-- @return @{node_pos} the lower position
-- @return @{node_pos} the upper position
function pick_and_place.sort_pos(pos1, pos2)
        pos1 = {x=pos1.x, y=pos1.y, z=pos1.z}
        pos2 = {x=pos2.x, y=pos2.y, z=pos2.z}
        if pos1.x > pos2.x then
                pos2.x, pos1.x = pos1.x, pos2.x
        end
        if pos1.y > pos2.y then
                pos2.y, pos1.y = pos1.y, pos2.y
        end
        if pos1.z > pos2.z then
                pos2.z, pos1.z = pos1.z, pos2.z
        end
        return pos1, pos2
end
