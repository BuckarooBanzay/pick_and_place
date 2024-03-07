
-- registry of templates
-- name => { pos1 = {}, pos2 = {} }
local registry = {}

function pick_and_place.register_template(name, pos1, pos2)
    registry[name] = { pos1=pos1, pos2=pos2}
end

function pick_and_place.get_template(name)
    return registry[name]
end