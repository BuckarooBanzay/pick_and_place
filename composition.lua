--[[
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
--]]

-- playername -> tool-id
local active_tools = {}

-- tool-id -> composition
local compositions = {}

-- playername -> origin
local origins = {}

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
    local name = meta:get_string("name")
    local id = meta:get_string("id")
    if id == "" then
        -- initialize
        id = pick_and_place.create_id()
        meta:set_string("id", id)
    end

    local data = meta:get_string("data")
    local bytes = #data
    local entries = meta:get_int("entries")

    if state then
        meta:set_string("state", state)
        if state == "play" then
            meta:set_string("color", "#00ff00") -- green
            -- TODO: defer playback somewhere
        elseif state == "record" then
            meta:set_string("color", "#ff0000") -- red
            active_tools[playername] = id
        else
            meta:set_string("color", "#0000ff") -- blue
            active_tools[playername] = nil
        end
    end

    -- TODO: check state
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
    update(itemstack, playername, "play")
end

function pick_and_place.set_composition_origin(itemstack, playername)
    -- TODO
end