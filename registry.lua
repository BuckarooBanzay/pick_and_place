
-- registry of templates
-- id => { pos1 = {}, pos2 = {}, name = "" }
local registry = {}

function pick_and_place.register_template(pos1, pos2, name, id)
    registry[id] = { pos1=pos1, pos2=pos2, name=name }
end

function pick_and_place.get_template(id)
    return registry[id]
end

local function load()
    local json = pick_and_place.store:get_string("registry")
    if json ~= "" then
        registry = minetest.parse_json(json, {})
    end
end

load()

local function save()
    pick_and_place.store:set_string("registry", minetest.write_json(registry))
end

minetest.register_on_shutdown(save)