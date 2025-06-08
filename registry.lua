local has_mapsync = minetest.get_modpath("mapsync")

-- registry of templates
-- id => { pos1 = {}, pos2 = {}, name = "", category = "" }
local registry = {}

function pick_and_place.get_template(id)
    return registry[id]
end

function pick_and_place.get_template_size(template)
    return vector.add(vector.subtract(template.pos2, template.pos1), vector.new(1,1,1))
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
    if has_mapsync then
        -- mapsync has priority if available, ignore everything else
        registry = mapsync.load_data("pick_and_place_registry") or {}
        return
    end

    local json = pick_and_place.store:get_string("registry")
    if json ~= "" then
        local list = minetest.parse_json(json, {})
        local i = 0
        for id, template in pairs(list) do
            if template.id and template.name then
                -- provide defaults
                template.category = template.category or ""
                registry[id] = template
                i = i + 1
            end
        end
        minetest.log("action", "[pick_and_place] loaded " .. i .. " templates from mod-storage")
    end
end

minetest.register_on_mods_loaded(load)

local save_pending = false

local function save()
    if has_mapsync then
        -- mapsync storage has priority if available
        mapsync.save_data("pick_and_place_registry", registry)
    else
        -- fall back to world-storage
        pick_and_place.store:set_string("registry", minetest.write_json(registry))
    end
    save_pending = false
end

function pick_and_place.register_template(pos1, pos2, name, category, id)
    registry[id] = {
        pos1 = pos1,
        pos2 = pos2,
        name = name,
        category = category,
        id = id
    }

    if not save_pending then
        save_pending = true
        minetest.after(2, save)
    end
end

function pick_and_place.unregister_template(id)
    registry[id] = nil

    if not save_pending then
        save_pending = true
        minetest.after(2, save)
    end
end