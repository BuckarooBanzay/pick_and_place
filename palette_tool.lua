local FORMSPEC_NAME = "pick_and_place:palette_tool"

local has_isogen = minetest.get_modpath("isogen")

local preview_cache = {} -- id -> png

local function get_formspec_template_info(template)
    if not template then
        return "label[11,0.5;" .. minetest.colorize("#FF0000", "No template selected") .. "]"
    end

    local size = pick_and_place.get_template_size(template)

    local fs = [[
        label[10.5,0.5;Category:]
        label[12,0.5;]] .. minetest.colorize("#00FF00", template.category) .. [[]

        label[15.5,0.5;Position:]
        label[17,0.5;]] .. minetest.colorize("#00FF00", minetest.pos_to_string(template.pos1)) .. [[]

        label[10.5,1.0;Name:]
        label[12,1.0;]] .. minetest.colorize("#00FF00", template.name) .. [[]

        button_exit[15.5,1.0;2,0.5;teleport;Teleport]

        label[10.5,1.5;Size:]
        label[12,1.5;]] .. minetest.colorize("#00FF00", minetest.pos_to_string(size)) .. [[]
    ]]

    if has_isogen then
        local cube_len = 24
        local png = preview_cache[template.id]
        if not png then
            -- create preview and cache
            png = isogen.draw(template.pos1, template.pos2, {
                cube_len = cube_len
            })
            preview_cache[template.id] = png
        end

        -- calculate image size and position
        local width, height = isogen.calculate_image_size(size, cube_len)
        local max_width = 8
        local max_height = 6
        local ratio = math.min(max_width/width, max_height/height)
        height = height * ratio
        width = width * ratio
        local img_offset_x = (8 - width) / 2

        fs = fs .. [[
            image[]] .. (11 + img_offset_x) .. [[,2;]] .. width .. "," .. height ..
                [[;[png:]] .. minetest.encode_base64(png) .. [[]
        ]]
    end

    return fs
end

local function get_formspec(meta, player)
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
    local selected_template = templates[1]

    for i, template in ipairs(templates) do
        if selected_name == template.name then
            selected_name_index = i
            selected_template = template
        end
        local sanitized_name = string.gsub(template.name, ",", " ")
        table.insert(template_names, sanitized_name)
    end

    local template_name_list = table.concat(template_names, ",")

    -- rotation
    local rotation = meta:get_int("rotation") or 0
    local rotation_index = {
        [0] = "1",
        [90] = "2",
        [180] = "3",
        [270] = "4"
    }
    local selected_rotation = rotation_index[rotation]

    local snap_txt = "OFF"
    if pick_and_place.is_snap_enabled(player) then
        snap_txt = minetest.colorize("#00FF00", "ON")
    end


    return [[
        size[20,10;]
        real_coordinates[true]

        dropdown[0.1,0.1;9.8,0.9;category;]] .. category_list .. [[;]] .. selected_category_index .. [[;true]
        textlist[0.1,1.1;9.8,8.7;name;]] .. template_name_list .. [[;]] .. selected_name_index .. [[]

        ]] .. get_formspec_template_info(selected_template) .. [[

        image_button_exit[10.1,9;0.8,0.8;pick_and_place_rotate_ccw.png;rotate_ccw;]
        dropdown[11.1,9;1.1,0.8;rotation;0°,90°,180°,270°;]] .. selected_rotation .. [[;true]
        image_button_exit[12.4,9;0.8,0.8;pick_and_place_rotate_cw.png;rotate_cw;]

        button_exit[13.3,9;3.1,0.8;toggle_snap;Grid-snap: ]] .. snap_txt .. [[]
        button_exit[16.7,9;3.1,0.8;exit;Exit]
    ]]
end

minetest.register_tool("pick_and_place:palette", {
    description = "Placement configuration palette tool",
    inventory_image = "pick_and_place_palette.png^[colorize:#ffffff",
    stack_max = 1,
    range = 0,
    on_use = function(itemstack, player)
        local meta = itemstack:get_meta()
        local name = meta:get_int("name")

        local id = meta:get_string("id")
        if not id then
            return
        end

        local template = pick_and_place.get_template(id)
        if not template then
            return
        end

        local rotation = meta:get_int("rotation")
        local size = pick_and_place.get_template_size(template)
        size = pick_and_place.rotate_size(size, rotation)

        local target_pos1, target_pos2 = pick_and_place.get_placement_pos(size, player)
        local controls = player:get_player_control()

        if pick_and_place.is_composition_in_area(target_pos1, target_pos2) then
            minetest.chat_send_player(player:get_player_name(), "Placement denied, an active composition is within")
            return
        end

        if controls.aux1 then
            -- removal
            pick_and_place.remove_area(target_pos1, target_pos2)
            pick_and_place.record_removal(target_pos1, target_pos2)
            pick_and_place.notify_change(target_pos1, target_pos2)
        else
            -- placement
            pick_and_place.copy_area(template.pos1, template.pos2, target_pos1, rotation)
            pick_and_place.notify_change(target_pos1, target_pos2)
            pick_and_place.record_placement(target_pos1, target_pos2, rotation, name, id)
        end
    end,
    on_secondary_use = function(itemstack, player)
        local meta = itemstack:get_meta()
        local playername = player:get_player_name()
        local fs = get_formspec(meta, player)
        minetest.show_formspec(playername, FORMSPEC_NAME, fs)
    end,
    on_step = function(itemstack, player)
        local meta = itemstack:get_meta()
        local playername = player:get_player_name()

        local id = meta:get_string("id")
        if not id then
            return
        end

        local template = pick_and_place.get_template(id)
        if not template then
            return
        end

        local rotation = meta:get_int("rotation")
        local size = pick_and_place.get_template_size(template)
        size = pick_and_place.rotate_size(size, rotation)

        local pos1, pos2 = pick_and_place.get_placement_pos(size, player)
        local controls = player:get_player_control()

        local text = string.format("'%s', '%s', %s",
            template.name, template.category,
            pick_and_place.get_formatted_size(pos1, pos2))

        if controls.aux1 then
            -- removal preview
            pick_and_place.show_preview(playername, "pick_and_place_minus.png", "#ff0000", pos1, pos2)
        else
            -- build preview
            pick_and_place.show_preview(playername, "pick_and_place_plus.png", "#0000ff", pos1, pos2, text)
        end
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

    if fields.teleport then
        local id = meta:get_string("id")
        local template = pick_and_place.get_template(id)
        if not template then
            return true
        end

        local size = pick_and_place.get_template_size(template)
        local center = vector.add(template.pos1, vector.divide(size, 2))
        player:set_pos(center)
        return true

    elseif fields.toggle_snap then
        if pick_and_place.is_snap_enabled(player) then
            pick_and_place.disable_snap(player)
        else
            pick_and_place.enable_snap(player)
        end
        return true

    elseif fields.rotate_ccw then
        local rotation = meta:get_int("rotation")
        rotation = rotation - 90
        if rotation < 0 then
            rotation = 270
        end
        meta:set_int("rotation", rotation)

    elseif fields.rotate_cw then
        local rotation = meta:get_int("rotation")
        rotation = rotation + 90
        if rotation > 270 then
            rotation = 0
        end
        meta:set_int("rotation", rotation)

    elseif fields.exit or fields.quit then
        -- already selected
        return true
    elseif fields.name then
        -- set name
        local parts = fields.name:split(":")
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

    elseif fields.rotation then
        if fields.rotation == "1" then
            meta:set_int("rotation", 0)
        elseif fields.rotation == "2" then
            meta:set_int("rotation", 90)
        elseif fields.rotation == "3" then
            meta:set_int("rotation", 180)
        elseif fields.rotation == "4" then
            meta:set_int("rotation", 270)
        end
    end

    -- update description
    local desc = string.format("Palette tool, selection: '%s' / '%s' (Id: %s)",
        meta:get_string("category"), meta:get_string("name"), meta:get_string("id"))
    meta:set_string("description", desc)

    -- update palette tool
    player:set_wielded_item(itemstack)

    -- show new formspec
    local fs = get_formspec(meta, player)
    minetest.show_formspec(playername, FORMSPEC_NAME, fs)

    return true
end)