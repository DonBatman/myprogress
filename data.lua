local file_path = core.get_worldpath() .. "/myprogress_data.txt"

function myprogress.save_data()
    if not myprogress.players or next(myprogress.players) == nil then
        core.log("warning", "[MyProgress] table is empty, skipping save to prevent data loss!")
        return
    end

    local file = io.open(file_path, "w")
    if file then
        file:write(core.serialize(myprogress.players))
        file:close()
        core.log("action", "[MyProgress] Player data saved to " .. file_path)
    else
        core.log("error", "[MyProgress] Failed to open data file for writing!")
    end
end

function myprogress.load_data()
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        if not content or content == "" then
            core.log("warning", "[MyProgress] Data file is empty.")
            return
        end

        local data = core.deserialize(content)
        if type(data) == "table" then
            myprogress.players = data
            core.log("action", "[MyProgress] Player data loaded successfully.")
        else
            core.log("error", "[MyProgress] Failed to deserialize player data!")
        end
    else
        core.log("action", "[MyProgress] No existing data file found.")
    end
end
