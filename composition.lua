local function serialize_composition(composition)
    local serialized_data = minetest.serialize(composition)
    local compressed_data = minetest.compress(serialized_data, "deflate")
    return minetest.encode_base64(compressed_data)
end

local function deserialize_composition(str)
    local compressed_data = minetest.decode_base64(str)
    local serialized_data = minetest.decompress(compressed_data, "deflate")
    return minetest.deserialize(serialized_data)
end

-- playername -> tool-id
local active_tools = {}

-- tool-id -> composition
local compositions = {}

-- TODO: sync inventory with global state

local function get_current_composition_tool(playername)
    local id = active_tools[playername]
    if not id then
        return
    end

    local player = minetest.get_player_by_name(playername)
    local inv = player:get_inventory()

    local list = inv:get_list("main")
    for _, itemstack in ipairs(list) do
        if itemstack:get_name() == "pick_and_place:composition" then
            local meta = itemstack:get_meta()
            local stack_id = meta:get_string("id")
            if stack_id == id then
                -- match
                return itemstack
            end
        end
    end
end

local function set_current_composition_tool(playername, new_itemstack)
    local id = active_tools[playername]
    if not id then
        return
    end

    local player = minetest.get_player_by_name(playername)
    local inv = player:get_inventory()

    local list = inv:get_list("main")
    for i, itemstack in ipairs(list) do
        if itemstack:get_name() == "pick_and_place:composition" then
            local meta = itemstack:get_meta()
            local stack_id = meta:get_string("id")
            if stack_id == id then
                -- match
                inv:set_stack("main", i, new_itemstack)
                return
            end
        end
    end
end

local function update(itemstack, playername, state)
    local meta = itemstack:get_meta()
    pick_and_place.update_composition_tool(meta)
    local id = meta:get_string("id")

    if state then
        meta:set_string("state", state)

        if state == "record" then
            meta:set_string("color", "#ff0000") -- red
            active_tools[playername] = id
            local data = meta:get_string("data")
            if data ~= "" then
                -- existing composition
                compositions[id] = deserialize_composition(data)
            else
                -- new composition
                compositions[id] = { entries = {} }
            end
        else
            meta:set_string("color", "#0000ff") -- blue
            active_tools[playername] = nil
            compositions[id] = nil
        end
    end

    -- TODO: check state
    pick_and_place.update_composition_tool(meta)
end

function pick_and_place.update_composition_tool(meta)
    local id = meta:get_string("id")
    if id == "" then
        -- initialize
        id = pick_and_place.create_id()
        meta:set_string("id", id)
    end

    local name = meta:get_string("name")
    local data = meta:get_string("data")
    local bytes = #data
    local entries = meta:get_int("entries")

    local desc = string.format("Composition tool '%s' (id: %s, %d entries, %d bytes)", name, id, entries, bytes)
    meta:set_string("description", desc)
end

function pick_and_place.update_composition_fields(itemstack, playername, fields)
    local meta = itemstack:get_meta()
    meta:set_string("name", fields.name)
    update(itemstack, playername)
end

function pick_and_place.record_composition(itemstack, playername)
    update(itemstack, playername, "record")
end

function pick_and_place.pause_composition(itemstack, playername)
    update(itemstack, playername, "pause")
end

function pick_and_place.play_composition(itemstack, playername)
    local meta = itemstack:get_meta()

    local origin = meta:get_string("origin")
    local pos = minetest.string_to_pos(origin)
    if not pos then
        return
    end

    local data = meta:get_string("data")
    if data ~= "" then
        local composition = deserialize_composition(data)

        local success, msg = pick_and_place.start_playback(playername, pos, composition)
        if not success then
            minetest.chat_send_player(playername, msg)
        end
    end
end

function pick_and_place.mark_composition_area(itemstack, playername)
    local meta = itemstack:get_meta()
    local origin = minetest.string_to_pos(meta:get_string("origin"))
    if not origin then
        return
    end

    local data = meta:get_string("data")
    if not data then
        return
    end

    local composition = deserialize_composition(data)
    if not composition then
        return
    end

    if not minetest.get_modpath("worldedit") then
        return
    end

    if composition.min_pos then
        local pos1 = vector.add(origin, composition.min_pos)
        worldedit.pos1[playername] = pos1
        worldedit.mark_pos1(playername);
    end

    if composition.max_pos then
        local pos2 = vector.add(origin, composition.max_pos)
        worldedit.pos2[playername] = pos2
        worldedit.mark_pos2(playername);
    end
end

function pick_and_place.duplicate_composition_tool(itemstack, playername)
    itemstack = ItemStack(itemstack)
    local meta = itemstack:get_meta()
    meta:set_string("id", pick_and_place.create_id())
    pick_and_place.update_composition_tool(meta)

    local player = minetest.get_player_by_name(playername)
    local inv = player:get_inventory()
    inv:add_item("main", itemstack)
end

function pick_and_place.set_composition_origin(itemstack, playername)
    local player = minetest.get_player_by_name(playername)
    if not player then
        return
    end
    local pos = vector.round(player:get_pos())
    local meta = itemstack:get_meta()
    meta:set_string("origin", minetest.pos_to_string(pos))
end

function pick_and_place.tp_composition_origin(itemstack, playername)
    local player = minetest.get_player_by_name(playername)
    if not player then
        return
    end

    local meta = itemstack:get_meta()
    local origin = meta:get_string("origin")
    local pos = minetest.string_to_pos(origin)
    if not pos then
        return
    end

    player:set_pos(pos)
end

local function track_min_max_pos(composition, pos)
    if not composition.min_pos then
        composition.min_pos = vector.copy(pos)
    elseif pos.x < composition.min_pos.x then
        composition.min_pos.x = pos.x
    elseif pos.y < composition.min_pos.y then
        composition.min_pos.y = pos.y
    elseif pos.z < composition.min_pos.z then
        composition.min_pos.z = pos.z
    end

    if not composition.max_pos then
        composition.max_pos = vector.copy(pos)
    elseif pos.x > composition.max_pos.x then
        composition.max_pos.x = pos.x
    elseif pos.y > composition.max_pos.y then
        composition.max_pos.y = pos.y
    elseif pos.z > composition.max_pos.z then
        composition.max_pos.z = pos.z
    end
end

function pick_and_place.record_removal(playername, pos1, pos2)
    local itemstack = get_current_composition_tool(playername)
    if not itemstack then
        return
    end

    local meta = itemstack:get_meta()
    local id = meta:get_string("id")
    local origin = minetest.string_to_pos(meta:get_string("origin"))
    if not origin then
        return
    end

    local composition = compositions[id]
    if not composition or #composition.entries == 0 then
        return
    end

    local rel_pos1 = vector.subtract(pos1, origin)
    local rel_pos2 = vector.subtract(pos2, origin)
    track_min_max_pos(composition, rel_pos1)
    track_min_max_pos(composition, rel_pos2)

    -- search and remove exact pos1/2 matches
    local entry_removed = false
    for i, entry in ipairs(composition.entries) do
        if vector.equals(entry.pos1, rel_pos1) and vector.equals(entry.pos2, rel_pos2) then
            -- remove matching entry
            table.remove(composition.entries, i)
            entry_removed = true
            break
        end
    end

    if not entry_removed then
        -- non-aligned removal, just record
        table.insert(composition.entries, {
            type = "remove",
            pos1 = rel_pos1,
            pos2 = rel_pos2
        })
    end

    meta:set_string("entries", #composition.entries)
    meta:set_string("data", serialize_composition(composition))
    set_current_composition_tool(playername, itemstack)
end

function pick_and_place.record_placement(playername, pos1, pos2, rotation, name, id)
    local itemstack = get_current_composition_tool(playername)
    if not itemstack then
        return
    end

    local meta = itemstack:get_meta()
    local tool_id = meta:get_string("id")
    local origin = minetest.string_to_pos(meta:get_string("origin"))
    if not origin then
        -- set origin to pos1
        origin = vector.copy(pos1)
        meta:set_string("origin", minetest.pos_to_string(origin))
    end

    local composition = compositions[tool_id]
    local rel_pos1 = vector.subtract(pos1, origin)
    local rel_pos2 = vector.subtract(pos2, origin)
    track_min_max_pos(composition, rel_pos1)
    track_min_max_pos(composition, rel_pos2)

    -- search and remove exact pos1/2 matches
    for i, entry in ipairs(composition.entries) do
        if vector.equals(entry.pos1, rel_pos1) and vector.equals(entry.pos2, rel_pos2) then
            -- remove matching entry
            table.remove(composition.entries, i)
            break
        end
    end

    table.insert(composition.entries, {
        type = "place",
        pos1 = rel_pos1,
        pos2 = rel_pos2,
        rotation = rotation,
        name = name,
        id = id
    })

    meta:set_string("entries", #composition.entries)
    meta:set_string("data", serialize_composition(composition))
    set_current_composition_tool(playername, itemstack)
end