
-- registry of templates
-- id => { pos1 = {}, pos2 = {}, name = "" }
local registry = {}

function pick_and_place.register_template(pos1, pos2, name, id)
    registry[id] = { pos1=pos1, pos2=pos2, name=name }
end

function pick_and_place.get_template(id)
    return registry[id]
end