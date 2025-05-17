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

-- pos or nil
local active_composition_pos

-- composition instance or nil
local active_composition

function pick_and_place.get_active_composition_pos()
    return active_composition_pos
end

function pick_and_place.set_active_composition_pos(pos)
    active_composition_pos = pos

    if pos then
        local meta = minetest.get_meta(pos)
        local data = meta:get_string("data")
        if data ~= "" then
            -- existing composition
            active_composition = deserialize_composition(data)
        else
            -- new composition
            active_composition = { entries = {} }
        end

        pick_and_place.store:set_string("active_composition_pos", minetest.pos_to_string(pos))
    else
        -- clear
        active_composition = nil
        pick_and_place.store:set_string("active_composition_pos", "")
    end

    pick_and_place.update_composition_huds()
end

local function load()
    local pos = pick_and_place.store:get_string("active_composition_pos")
    if pos and pos ~= "" then
        pick_and_place.set_active_composition_pos(minetest.string_to_pos(pos))
    end
end
minetest.after(0, load)

local function persist_active_composition()
    local meta = minetest.get_meta(active_composition_pos)
    meta:set_string("entries", #active_composition.entries)
    meta:set_string("data", serialize_composition(active_composition))
    pick_and_place.update_composition_node(meta)
    pick_and_place.update_composition_huds()
    pick_and_place.notify_change(active_composition_pos, active_composition_pos)
end

function pick_and_place.get_replacements(pos)
    local replacements = {}
    pos = pos or active_composition_pos
    if not pos then
        return replacements
    end

    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local list = inv:get_list("replacements")

    for i=1,#list,2 do
        local source_name = list[i]:get_name()
        local target_name = list[i+1]:get_name()

        if source_name ~= "" and
            target_name ~= "" and
            minetest.registered_nodes[source_name] and
            minetest.registered_nodes[target_name] then
                replacements[minetest.get_content_id(source_name)] = minetest.get_content_id(target_name)
        end
    end

    return replacements
end

function pick_and_place.update_composition_node(meta)
    local inv = meta:get_inventory()
    inv:set_size("replacements", 20 * 2)

    local name = meta:get_string("name")
    local data = meta:get_string("data")
    local bytes = #data
    local entries = meta:get_int("entries")

    local desc = string.format("Composition '%s' (%d entries, %d bytes)", name, entries, bytes)
    meta:set_string("description", desc)
    meta:set_string("infotext", desc)
end

function pick_and_place.update_composition_fields(meta, fields)
    meta:set_string("name", fields.name)
    pick_and_place.update_composition_node(meta)
end

function pick_and_place.play_composition(pos, meta, playername)
    local data = meta:get_string("data")
    if data ~= "" then
        local composition = deserialize_composition(data)

        local success, msg = pick_and_place.start_playback(playername, pos, composition)
        if not success then
            minetest.chat_send_player(playername, msg)
        end
    end
end

function pick_and_place.mark_composition_area(pos, meta, playername)
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
        local pos1 = vector.add(pos, composition.min_pos)
        worldedit.pos1[playername] = pos1
        worldedit.mark_pos1(playername);
    end

    if composition.max_pos then
        local pos2 = vector.add(pos, composition.max_pos)
        worldedit.pos2[playername] = pos2
        worldedit.mark_pos2(playername);
    end
end

function pick_and_place.duplicate_composition_node(old_meta, playername)
    local itemstack = ItemStack("pick_and_place:composition")
    local meta = itemstack:get_meta()
    for _, key in ipairs({"name", "data", "entries", "description"}) do
        meta:set_string(key, old_meta:get_string(key))
    end

    -- serialize replacements
    local oldinv = old_meta:get_inventory()
    local replacements = {}
    for _, r in ipairs(oldinv:get_list("replacements")) do
        table.insert(replacements, r:to_string())
    end
    meta:set_string("replacements", minetest.serialize(replacements))

    local player = minetest.get_player_by_name(playername)
    local inv = player:get_inventory()
    inv:add_item("main", itemstack)
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

function pick_and_place.is_composition_in_area(pos1, pos2)
    if not active_composition_pos then
        return false
    end
    return vector.in_area(active_composition_pos, pos1, pos2)
end

function pick_and_place.record_removal(pos1, pos2)
    if not active_composition or #active_composition.entries == 0 then
        return
    end

    local rel_pos1 = vector.subtract(pos1, active_composition_pos)
    local rel_pos2 = vector.subtract(pos2, active_composition_pos)
    track_min_max_pos(active_composition, rel_pos1)
    track_min_max_pos(active_composition, rel_pos2)

    -- search and remove exact pos1/2 matches
    local entry_removed = false
    for i, entry in ipairs(active_composition.entries) do
        if vector.equals(entry.pos1, rel_pos1) and vector.equals(entry.pos2, rel_pos2) then
            -- remove matching entry
            table.remove(active_composition.entries, i)
            entry_removed = true
            break
        end
    end

    if not entry_removed then
        -- non-aligned removal, just record
        table.insert(active_composition.entries, {
            type = "remove",
            pos1 = rel_pos1,
            pos2 = rel_pos2
        })
    end

    persist_active_composition()
end

function pick_and_place.record_placement(pos1, pos2, rotation, name, id)
    if not active_composition_pos then
        return
    end

    local rel_pos1 = vector.subtract(pos1, active_composition_pos)
    local rel_pos2 = vector.subtract(pos2, active_composition_pos)
    track_min_max_pos(active_composition, rel_pos1)
    track_min_max_pos(active_composition, rel_pos2)

    -- search and remove exact pos1/2 matches
    for i, entry in ipairs(active_composition.entries) do
        if vector.equals(entry.pos1, rel_pos1) and vector.equals(entry.pos2, rel_pos2) then
            -- remove matching entry
            table.remove(active_composition.entries, i)
            break
        end
    end

    table.insert(active_composition.entries, {
        type = "place",
        pos1 = rel_pos1,
        pos2 = rel_pos2,
        rotation = rotation,
        name = name,
        id = id
    })

    persist_active_composition()
end

minetest.register_chatcommand("pnp_composition_move", {
    params = "[axis] [amount]",
    privs = { server = true },
    description = "moves the currently active composition node by this amount (and offsets all placements)",
    func = function(_, param)
        -- validate input and state
        if not active_composition_pos then
            return false, "no composition active/recording"
        end

        local _, _, axis, amount_str = string.find(param, "^([^%s]+)%s+(.*)$")
        if not axis or not amount_str then
            return false, "missing parameters"
        end

        local amount = tonumber(amount_str)
        if not amount or amount > 30000 or amount < -30000 or amount == 0 then
            return false, "invalid amount"
        end
        amount = math.floor(amount)

        -- create offsets
        local offset
        if axis == "x" then
            offset = vector.new(amount, 0, 0)
        elseif axis == "y" then
            offset = vector.new(0, amount, 0)
        elseif axis == "z" then
            offset = vector.new(0, 0, amount)
        else
            return false, "invalid axis"
        end

        -- prepare metadata
        local new_pos = vector.add(active_composition_pos, offset)
        minetest.set_node(new_pos, { name = "pick_and_place:composition" })
        local new_meta = minetest.get_meta(new_pos)
        local new_inv = new_meta:get_inventory()
        local old_meta = minetest.get_meta(active_composition_pos)
        local old_inv = old_meta:get_inventory()

        -- offset entries
        for _, entry in ipairs(active_composition.entries) do
            entry.pos1 = vector.subtract(entry.pos1, offset)
            entry.pos2 = vector.subtract(entry.pos2, offset)
        end

        -- persist changes
        persist_active_composition()

        -- move metadata
        for _, key in ipairs({"name", "description", "infotext", "data", "entries"}) do
            new_meta:set_string(key, old_meta:get_string(key))
        end

        -- move inventory
        new_inv:set_list("replacements", old_inv:get_list("replacement"))

        -- clear old pos
        minetest.set_node(active_composition_pos, { name = "air" })

        -- set new pos
        pick_and_place.set_active_composition_pos(new_pos)

        return true, string.format("moved current composition by %d nodes into the %s axis", amount, axis)
    end
})