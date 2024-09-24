--[[
local function serialize_records(records)
    local serialized_data = minetest.serialize(records)
    local compressed_data = minetest.compress(serialized_data, "deflate")
    return minetest.encode_base64(compressed_data)
end

local function deserialize_records(str)
    local compressed_data = minetest.decode_base64(str)
    local serialized_data = minetest.decompress(compressed_data, "deflate")
    return minetest.deserialize(serialized_data)
end
--]]

local function update(itemstack, state)
    local meta = itemstack:get_meta()
    local name = meta:get_string("name")
    local id = meta:get_string("id")
    if id == "" then
        -- initialize
        id = pick_and_place.create_id()
        meta:set_string("id", id)
    end

    meta:set_string("state", state)

    if state == "play" then
        meta:set_string("color", "#00ff00") -- green
    elseif state == "record" then
        meta:set_string("color", "#ff0000") -- red
    else
        meta:set_string("color", "#0000ff") -- blue
    end

    -- TODO: check state
    local desc = string.format("Composition tool '%s' (%s)", name, id)
    meta:set_string("description", desc)
end

function pick_and_place.record_composition(itemstack)
    update(itemstack, "record")
end

function pick_and_place.pause_composition(itemstack)
    update(itemstack, "pause")
end

function pick_and_place.play_composition(itemstack)
    update(itemstack, "play")
end

function pick_and_place.set_composition_origin()
    -- TODO
end