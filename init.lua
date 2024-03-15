
pick_and_place = {}

local MP = minetest.get_modpath("pick_and_place")
dofile(MP .. "/common.lua")
dofile(MP .. "/rotate.lua")
dofile(MP .. "/rotate_tool.lua")
dofile(MP .. "/schematic_rotate.lua")
dofile(MP .. "/schematic_flip.lua")
dofile(MP .. "/schematic_orient.lua")
dofile(MP .. "/schematic_transpose.lua")
dofile(MP .. "/replacement.lua")
dofile(MP .. "/pointed.lua")
dofile(MP .. "/configure.lua")
dofile(MP .. "/remove.lua")
dofile(MP .. "/encode.lua")
dofile(MP .. "/serialize.lua")
dofile(MP .. "/entity.lua")
dofile(MP .. "/handle_node.lua")
dofile(MP .. "/create_tool.lua")
dofile(MP .. "/configure_tool.lua")
dofile(MP .. "/pick_tool.lua")
dofile(MP .. "/place_tool.lua")
dofile(MP .. "/preview.lua")
dofile(MP .. "/craft.lua")
dofile(MP .. "/record.lua")
dofile(MP .. "/playback.lua")
dofile(MP .. "/registry.lua")
dofile(MP .. "/snap.lua")

if minetest.get_modpath("travelnet") then
	dofile(MP .. "/compat/travelnet.lua")
end

if minetest.get_modpath("mtt") and mtt.enabled then
	dofile(MP .. "/configure.spec.lua")
	dofile(MP .. "/create_tool.spec.lua")
	dofile(MP .. "/encode.spec.lua")
	dofile(MP .. "/schematic_rotate.spec.lua")
end