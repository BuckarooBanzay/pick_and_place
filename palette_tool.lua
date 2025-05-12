local FORMSPEC_NAME = "pick_and_place:palette_tool"

local function get_formspec(meta)
    -- category selection
    local selected_category = meta:get_string("category")
    local selected_category_index = 1

    local categories = pick_and_place.get_template_categories()
    local category_list = table.concat(categories, ",")

    for i, name in ipairs(categories) do
        if name == selected_category then
            selected_category_index = i
            break
        end
    end

    -- template name selection
    local selected_name = meta:get_string("name")
    local selected_name_index = 1

    local templates = pick_and_place.get_templates_by_category(selected_category)
    local template_names = {}

    for i, template in ipairs(templates) do
        if selected_name == template.name then
            selected_name_index = i
        end
        table.insert(template_names, template.name)
    end

    local template_name_list = table.concat(template_names, ",")

    return [[
        size[10,10;]
        real_coordinates[true]
        dropdown[0.1,0.1;9.8,0.9;category;]] .. category_list .. [[;]] .. selected_category_index .. [[;true]
        textlist[0.1,1.1;9.8,7.7;name;]] .. template_name_list .. [[;]] .. selected_name_index .. [[]
        button_exit[0.1,9;9.8,0.8;select;Select]
    ]]
end

minetest.register_tool("pick_and_place:palette", {
    description = "Placement configuration palette tool",
    inventory_image = "pick_and_place_palette.png^[colorize:#ffffff",
    stack_max = 1,
    range = 0,
    on_use = function(itemstack, player)
        local meta = itemstack:get_meta()
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)

    end,
    on_secondary_use = function(itemstack, player)
        local meta = itemstack:get_meta()
        local playername = player:get_player_name()
        local fs = get_formspec(meta)
        minetest.show_formspec(playername, FORMSPEC_NAME, fs)
    end,
    on_step = function(_, player)
        local playername = player:get_player_name()
        local pointed_pos = pick_and_place.get_pointed_position(player)
        local text = pick_and_place.get_formatted_size(pointed_pos, nil)

        -- update preview
        pick_and_place.show_preview(
            playername,
            "pick_and_place_plus.png",
            "#0000ff",
            pointed_pos,
            nil,
            text
        )
    end,
    on_deselect = function(_, player)
        local playername = player:get_player_name()
        pick_and_place.clear_preview(playername)
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= FORMSPEC_NAME then
        return false
    end

    local itemstack = player:get_wielded_item()
    if itemstack:get_name() ~= "pick_and_place:palette" then
        return true
    end

    local playername = player:get_player_name()
    local meta = itemstack:get_meta()

    if fields.select then
        -- already selected
        return true
    elseif fields.name then
        -- set name
        local parts = fields.name:split(":")
        print(dump(parts))
        if parts[1] == "CHG" and #parts == 2 then
            local selected = tonumber(parts[2]) or 1
            local category = meta:get_string("category")

            local templates = pick_and_place.get_templates_by_category(category)
            if templates and templates[selected] then
                meta:set_string("name", templates[selected].name)
                meta:set_string("id", templates[selected].id)
            end
        end
    elseif fields.category then
        -- set category
        local categories = pick_and_place.get_template_categories()
        local category = categories[tonumber(fields.category) or 1]
        meta:set_string("category", category)

        -- first entry
        local templates = pick_and_place.get_templates_by_category(category)
        if templates and templates[1] then
            meta:set_string("name", templates[1].name)
            meta:set_string("id", templates[1].id)
        end

        -- show new formspec
        local fs = get_formspec(meta)
        minetest.show_formspec(playername, FORMSPEC_NAME, fs)
    end

    -- update description
    local desc = string.format("Palette tool, selection: '%s' / '%s' (Id: %s)",
        meta:get_string("category"), meta:get_string("name"), meta:get_string("id"))
    meta:set_string("description", desc)

    player:set_wielded_item(itemstack)

    return true
end)