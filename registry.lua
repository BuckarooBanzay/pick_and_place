
-- registry of templates
-- id => { pos1 = {}, pos2 = {}, name = "", category = "" }
local registry = {}

function pick_and_place.register_template(pos1, pos2, name, category, id)
    assert(type(name) == "string")
    assert(type(category) == "string")
    registry[id] = { pos1=pos1, pos2=pos2, name=name, category=category, id=id }
end

function pick_and_place.unregister_template(id)
    registry[id] = nil
end

function pick_and_place.get_template(id)
    return registry[id]
end

function pick_and_place.get_template_categories()
    local list = {}
    local visited = {}
    for _, entry in pairs(registry) do
        -- defaults
        entry.category = entry.category or ""

        if not visited[entry.category] then
            table.insert(list, entry.category)
            visited[entry.category] = true
        end
    end
    table.sort(list)
    return list
end

function pick_and_place.get_templates_by_category(category)
    local list = {}
    for _, entry in pairs(registry) do
        if entry.category == category then
            table.insert(list, entry)
        end
    end
    table.sort(list, function(a,b)
        return a.name < b.name
    end)
    return list
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