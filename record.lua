
-- current state of recording
local state = false

-- current recording entry
local recording

-- current recording origin
local origin

local function reset_recording()
    recording = {
        entries = {}
    }
end
reset_recording()

minetest.register_chatcommand("pnp_record_save", {
    params = "[filename]",
    description = "save the current recording to a file in the world-directory",
    func = function(_, param)
        local json = minetest.write_json(recording)
        local filename = minetest.get_worldpath() .. "/" .. param .. ".json"
        local f = io.open(filename, "w")
        f:write(json)
        f:close()
        return true, "saved " .. #recording.entries .. " entries to '" .. filename .. "'"
    end
})

minetest.register_chatcommand("pnp_record_load", {
    params = "[filename]",
    description = "loads a recording from a file in the world-directory",
    func = function(_, param)
        local filename = minetest.get_worldpath() .. "/" .. param .. ".json"
        local f = io.open(filename, "r")
        if not f then
            return false, "file not found: '" .. filename .. "'"
        end
        recording = minetest.parse_json(f:read("*all"))
        if not recording then
            reset_recording()
            return false, "could not parse file '" .. filename .. "'"
        end
        return true, "read " .. #recording.entries .. " entries from '" .. filename .. "'"
    end
})



minetest.register_chatcommand("pnp_record", {
    params = "[origin|start|info|pause|reset|play]",
    description = "manages the recording state or plays the current recording",
    func = function(name, param)
        if param == "origin" then
            if state then
                return false, "origin can't be set while the recording is active"
            end
            -- set origin to current player pos
            local player = minetest.get_player_by_name(name)
            if not player then
                return false, "player not found"
            end
            origin = vector.round(player:get_pos())
            return true, "origin set to: " .. minetest.pos_to_string(origin)
        end

        if not origin then
            return false, "origin not set, please use '/pnp_record origin' first"
        end

        if param == "start" then
            state = true
            return true, "recording started"

        elseif param == "pause" then
            state = false
            return true, "recording paused"

        elseif param == "reset" then
            reset_recording()
            return true, "recording reset"

        elseif param == "play" then
            return pick_and_place.start_playback(name, origin, recording)

        else
            local msg = "recording state: "

            if state then
                msg = msg .. "running"
            else
                msg = msg .. "stopped/paused"
            end

            msg = msg .. ", entries: " .. #recording.entries

            msg = msg .. ", origin: "
            if origin then
                msg = msg .. minetest.pos_to_string(origin)
            else
                msg = msg .. "<not set>"
            end

            if recording.min_pos then
                msg = msg .. ", min_pos: " .. minetest.pos_to_string(recording.min_pos)
            end
            if recording.max_pos then
                msg = msg .. ", max_pos: " .. minetest.pos_to_string(recording.max_pos)
            end
            return true, msg
        end
    end
})

local function track_min_max_pos(pos)
    if not recording.min_pos then
        recording.min_pos = vector.copy(pos)
    elseif pos.x < recording.min_pos.x then
        recording.min_pos.x = pos.x
    elseif pos.y < recording.min_pos.y then
        recording.min_pos.y = pos.y
    elseif pos.z < recording.min_pos.z then
        recording.min_pos.z = pos.z
    end

    if not recording.max_pos then
        recording.max_pos = vector.copy(pos)
    elseif pos.x > recording.max_pos.x then
        recording.max_pos.x = pos.x
    elseif pos.y > recording.max_pos.y then
        recording.max_pos.y = pos.y
    elseif pos.z > recording.max_pos.z then
        recording.max_pos.z = pos.z
    end
end

function pick_and_place.record_removal(pos1, pos2)
    if not state or not origin then
        return
    end
    if #recording.entries == 0 then
        return
    end

    local rel_pos1 = vector.subtract(pos1, origin)
    local rel_pos2 = vector.subtract(pos2, origin)
    track_min_max_pos(rel_pos1)
    track_min_max_pos(rel_pos2)

    -- search and remove exact pos1/2 matches
    local entry_removed = false
    for i, entry in ipairs(recording.entries) do
        if vector.equals(entry.pos1, rel_pos1) and vector.equals(entry.pos2, rel_pos2) then
            -- remove matching entry
            table.remove(recording.entries, i)
            entry_removed = true
            break
        end
    end

    if not entry_removed then
        -- non-aligned removal, just record
        table.insert(recording.entries, {
            type = "remove",
            pos1 = rel_pos1,
            pos2 = rel_pos2
        })
    end
end

function pick_and_place.record_placement(pos1, pos2, rotation, name)
    if not state or not origin then
        return
    end

    local rel_pos1 = vector.subtract(pos1, origin)
    local rel_pos2 = vector.subtract(pos2, origin)
    track_min_max_pos(rel_pos1)
    track_min_max_pos(rel_pos2)

    table.insert(recording.entries, {
        type = "place",
        pos1 = rel_pos1,
        pos2 = rel_pos2,
        rotation = rotation,
        name = name
    })
end