local playback_active = false

local function get_cache_key(id, rotation)
    return id .. "/" .. rotation
end

local function playback(ctx)
    -- shift
    ctx.i = ctx.i + 1

    -- pick next entry
    local entry = ctx.composition.entries[ctx.i]
    if not entry then
        minetest.chat_send_player(
            ctx.playername, "composition playback done with " .. (ctx.i-1) .. " entries"
        )
        playback_active = false
        return
    end

    if ctx.i % 10 == 0 then
        -- status update
        minetest.chat_send_player(
            ctx.playername, "composition playback: entry " .. ctx.i .. "/" .. #ctx.composition.entries
        )
    end

    if entry.type == "place" then
        local tmpl = pick_and_place.get_template(entry.id)
        if tmpl then
            local key = get_cache_key(entry.id, entry.rotation)
            local schematic = ctx.cache[key]

            if not schematic then
                -- cache schematic with rotation
                schematic = pick_and_place.serialize(tmpl.pos1, tmpl.pos2)
                pick_and_place.schematic_rotate(schematic, entry.rotation)
                ctx.cache[key] = schematic
            end

            -- resolve absolute position
            local abs_pos1 = vector.add(ctx.origin, entry.pos1)
            local replacements = pick_and_place.get_replacements(ctx.origin)
            pick_and_place.deserialize(abs_pos1, schematic, false, replacements)
        else
            minetest.chat_send_player(ctx.playername, "composition playback: template not found: '" .. entry.id .. "'")
        end
    elseif entry.type == "remove" then
        local abs_pos1 = vector.add(ctx.origin, entry.pos1)
        local abs_pos2 = vector.add(ctx.origin, entry.pos2)

        pick_and_place.remove_area(abs_pos1, abs_pos2)
    end

    -- re-schedule
    minetest.after(0, playback, ctx)
end

function pick_and_place.start_playback(playername, origin, composition)
    if playback_active then
        return false, "playback already running"
    end

    playback({
        playername = playername,
        origin = origin,
        composition = composition,
        i = 0,
        cache = {}
    })

    return true, "playback started"
end
