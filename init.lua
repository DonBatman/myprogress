-- ==========================================================
-- MAIN INITIALIZATION (init.lua)
-- ==========================================================
myprogress = {}
myquests = {}

-- Initialize global tables immediately to prevent nil indexing errors
myprogress.players = {}
myprogress.player_huds = {}

-- XP Scaling Configuration: determines how fast players level up
myprogress.xp_scaling = {
    mining    = 100,
    lumbering = 80,
    digging   = 100,
    farming   = 50,
    building  = 200,
    combat    = 60
}

-- Difficulty Settings
myquests.settings = {
    difficulty = "normal" 
}

-- Define paths for data persistence
local path = core.get_modpath("myprogress")
local world_path = core.get_worldpath()
local save_file = world_path .. "/myprogress_data.json"

-- Load modules in specific order
dofile(path .. "/nodes.lua")      
dofile(path .. "/hud.lua")        
dofile(path .. "/awards.lua")     
dofile(path .. "/functions.lua")
dofile(path .. "/chat_commands.lua") -- Load separate chat commands
dofile(path .. "/leaderboard.lua")   -- Load separate leaderboard

-- ==========================================================
-- DATA PERSISTENCE (Save/Load)
-- ==========================================================

function myprogress.save_data()
    local file = io.open(save_file, "w")
    if file then
        file:write(core.serialize(myprogress.players))
        file:close()
        core.log("action", "[myprogress] All player data saved to world folder.")
    else
        core.log("error", "[myprogress] Failed to save data!")
    end
end

function myprogress.load_data()
    local file = io.open(save_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = core.deserialize(content)
        if type(data) == "table" then
            myprogress.players = data
            core.log("action", "[myprogress] Player data loaded successfully.")
        end
    else
        core.log("action", "[myprogress] No existing save file found. Starting fresh.")
    end
end

-- Initial load on startup
myprogress.load_data()

-- ==========================================================
-- PLAYER EVENTS
-- ==========================================================

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    if not myprogress.players[name] then
        myprogress.players[name] = {
            total_xp = 0,
            mining = 0, mlevel = 0,
            lumbering = 0, llevel = 0,
            digging = 0, dlevel = 0,
            farming = 0, flevel = 0,
            building = 0, blevel = 0,
            combat = 0, clevel = 0
        }
    end
    
    core.after(2, function()
        if player:is_player() and myprogress.update_hud then
            myprogress.update_hud(player)
        end
    end)
end)

core.register_on_leaveplayer(function(player)
    myprogress.save_data()
end)

core.register_on_shutdown(function()
    myprogress.save_data()
end)
