local elevator_cid = minetest.get_content_id("travelnet:elevator")
local owner = "singleplayer"

pick_and_place.register_on_place(function(pos1, pos2, nodeids)
    if not nodeids[elevator_cid] then
        return
    end

    local poslist = minetest.find_nodes_in_area(pos1, pos2, {"travelnet:elevator"})

    -- key -> table[pos]
    local elevator_buckets = {}

    for _, pos in ipairs(poslist) do
        local network_name = travelnet.elevator_network(pos)
        local bucket = elevator_buckets[network_name]
        if not bucket then
            bucket = {}
            elevator_buckets[network_name] = bucket
        end
        table.insert(bucket, pos)
    end

    local travelnets = travelnet.get_travelnets(owner)
    local timestamp = os.time()

    for network_name, bucket in pairs(elevator_buckets) do
        local network = travelnets[network_name]
        if not network then
            network = {}
            travelnets[network_name] = network
        end

        -- determine min, max station-nr
        local nr_min = 0
        local nr_max = 0
        local ground_y
        for nr, station in pairs(network) do
            if nr == "G" then
                -- ground floor
                ground_y = station.pos.y
            else
                -- other floors
                local n = tonumber(nr)
                if n > nr_max then
                    nr_max = n
                elseif n < nr_min then
                    nr_min = n
                end
            end
        end

        -- determine order
        if ground_y and pos1.y < ground_y then
            -- below
            table.sort(bucket, function(a,b) return a.y > b.y end)
        else
            -- ground or above
            table.sort(bucket, function(a,b) return a.y < b.y end)
        end

        for _, pos in ipairs(bucket) do
            local station_name = "G"

            -- calculate new floor number
            if ground_y then
                -- not the first elevator in this position
                if pos.y > ground_y then
                    -- above
                    station_name = "" .. (nr_max + 1)
                    nr_max = nr_max + 1
                elseif pos.y < ground_y then
                    -- below
                    station_name = "" .. (nr_min - 1)
                    nr_min = nr_min - 1
                end
            else
                ground_y = pos.y
            end

            network[station_name] = {
                nr = " ",
                pos = pos,
                timestamp = timestamp
            }

            timestamp = timestamp + 1

            local meta = minetest.get_meta(pos)
            meta:set_string("owner", owner)
            meta:set_string("station_network", network_name)
            meta:set_string("station_name", station_name)
            meta:set_string("infotext", "Elevator, level " .. station_name)
            meta:set_int("timestamp", timestamp)
        end
    end

    travelnet.set_travelnets(owner, travelnets)
end)

pick_and_place.register_on_before_remove(function(pos1, pos2)
    local poslist = minetest.find_nodes_in_area(pos1, pos2, {"travelnet:elevator"})
    if #poslist == 0 then
        return
    end

    local travelnets = travelnet.get_travelnets(owner)

    for _, pos in ipairs(poslist) do
        local meta = minetest.get_meta(pos)
        local station_name = meta:get_string("station_name")
        local network_name = travelnet.elevator_network(pos)

        local network = travelnets[network_name]
        if network then
            network[station_name] = nil
        end
    end

    travelnet.set_travelnets(owner, travelnets)
end)