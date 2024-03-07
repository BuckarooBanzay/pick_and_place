local playback_active = false

local function get_cache_key(name, rotation)
    return name .. "/" .. rotation
end

local function playback(ctx)
    ctx = ctx or {
        playername = "singleplayer",
        i = 0,
        cache = {}
    }

    -- shift
    ctx.i = ctx.i + 1

    -- pick next entry
    local entry = ctx.recording.entries[ctx.i]
    if not entry then
        minetest.chat_send_player(ctx.playername, "pnp playback done with " .. ctx.i .. " entries")
        playback_active = false
        return
    end

    if ctx.i % 10 == 0 then
        -- status update
        minetest.chat_send_player(ctx.playername, "pnp playback: entry " .. ctx.i .. "/" .. #ctx.recording.entries)
    end

    -- TODO: place/remove
    if entry.type == "place" then
        local tmpl = pick_and_place.get_template(entry.name)
        if tmpl then
            local key = get_cache_key(entry.name, entry.rotation)
            local schematic = ctx.cache[key]

            if not schematic then
                -- cache schematic with rotation
                schematic = pick_and_place.serialize(entry.pos1, entry.pos2)
                pick_and_place.schematic_rotate(schematic, entry.rotation)
                ctx.cache[key] = schematic
            end

            pick_and_place.deserialize(entry.pos1, schematic)
        end
    elseif entry.type == "remove" then
        pick_and_place.remove_area(entry.pos1, entry.pos2)
    end

    -- re-schedule
    minetest.after(0, playback, ctx)
end

function pick_and_place.start_playback(playername, recording)
    if playback_active then
        return false, "playback already running"
    end

    playback({
        playername = playername,
        recording = recording
    })

    return true, "playback started"
end
