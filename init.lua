-- ==========================================================
-- MYPROGRESS MOD - CORE INITIALIZATION (init.lua)
-- ==========================================================

myprogress = {}
myquests = {}

myprogress.players = {}
myprogress.player_huds = {}

--[[ XP Scaling Configuration
myprogress.xp_scaling = {
    mining    = 100,
    lumbering = 80,
    digging   = 100,
    farming   = 50,
    building  = 200,
    combat    = 60
}
--]]
myprogress.xp_scaling = {
    mining    = 1,
    lumbering = 1,
    digging   = 1,
    farming   = 1,
    building  = 1,
    combat    = 1
}
-- Mapping helper for logic consistency across files
myprogress.skill_map = {
    mining = "mlevel",
    lumbering = "llevel",
    farming = "flevel",
    digging = "dlevel",
    building = "blevel",
    combat = "clevel"
}

-- Load Settings
myquests.settings = {
    difficulty = core.settings:get("myprogress_difficulty") or "normal" 
}

local path = core.get_modpath("myprogress")

-- Load Persistence Module First
dofile(path .. "/data.lua")

-- Initial Load from data.lua
myprogress.load_data()

-- Load Sub-Modules
dofile(path .. "/nodes.lua")      
dofile(path .. "/hud.lua")        
dofile(path .. "/awards.lua")     
dofile(path .. "/functions.lua")
dofile(path .. "/chat_commands.lua")
dofile(path .. "/leaderboard.lua")

-- Player Join Logic
core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    -- Initialize fresh player table if missing
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
    
    -- Delay HUD update to ensure engine is ready
    core.after(2, function()
        if player:is_player() and myprogress.update_hud then
            myprogress.update_hud(player)
        end
    end)
end)

-- Save on Leave
core.register_on_leaveplayer(function(player)
    myprogress.save_data()
end)

-- Save on Server Shutdown
core.register_on_shutdown(function()
    myprogress.save_data()
end)

-- Helper for Machine Inventory (referenced by other files)
function myprogress.setup_machine_inv(pos)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size("src", 1)
    inv:set_size("dst", 2)
end
