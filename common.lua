
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

function pick_and_place.get_formatted_size(pos1, pos2)
        pos2 = pos2 or pos1
        pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)
        return minetest.pos_to_string(vector.add(vector.subtract(pos2, pos1), 1))
end

function pick_and_place.create_id()
        local template = "xxxxxx"
        return string.gsub(template, '[x]', function ()
                return string.format('%x', math.random(0, 0xf))
        end)
end

-- returns the outer corners for the handle nodes
function pick_and_place.get_outer_corners(pos1, pos2)
        pos1, pos2 = pick_and_place.sort_pos(pos1, pos2)
        pos1 = vector.subtract(pos1, 1)
        pos2 = vector.add(pos2, 1)

        return {
                { x=pos1.x, y=pos1.y, z=pos1.z },
                { x=pos1.x, y=pos1.y, z=pos2.z },
                { x=pos1.x, y=pos2.y, z=pos1.z },
                { x=pos1.x, y=pos2.y, z=pos2.z },
                { x=pos2.x, y=pos1.y, z=pos1.z },
                { x=pos2.x, y=pos1.y, z=pos2.z },
                { x=pos2.x, y=pos2.y, z=pos1.z },
                { x=pos2.x, y=pos2.y, z=pos2.z }
        }
end


function pick_and_place.get_replacement_nodeid(ctx, metadata)
    local group = metadata.fields.group
    local selected_name
    if group and group ~= "" and ctx[group] then
        -- group placement
        selected_name = metadata.inventory.main[ctx[group]]
    else
        -- random placement
        local replacement_names = {}
        for _, name in ipairs(metadata.inventory.main) do
            if name ~= "" then
                table.insert(replacement_names, name)
            end
        end

        if #replacement_names == 0 then
            -- no replacement
            return
        end

        local i = math.random(#replacement_names)
        selected_name = replacement_names[i]

        -- set group context
        if group and group ~= "" then
            ctx[group] = i
        end
    end

    local stack = ItemStack(selected_name)
    local nodename = stack:get_name()

    if not minetest.registered_nodes[nodename] then
        -- node not found
        return
    end

    local nodeid = minetest.get_content_id(nodename)
    return nodeid
end

local has_mapsync = minetest.get_modpath("mapsync")
local has_blockexchange = minetest.get_modpath("blockexchange")

-- notify supported mods of changes
function pick_and_place.notify_change(pos1, pos2)
    if has_blockexchange then
        blockexchange.mark_changed(pos1, pos2)
    end
    if has_mapsync then
        mapsync.mark_changed(pos1, pos2)
    end
end