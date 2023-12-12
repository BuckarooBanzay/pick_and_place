globals = {
	"pick_and_place"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	-- Minetest
	"vector", "ItemStack",
	"dump", "dump2",
	"VoxelArea",
	"minetest",

	-- mods
	"mapsync", "mtt"
}
