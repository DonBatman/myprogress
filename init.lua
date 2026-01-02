myprogress = {}
myquests = {}

myprogress.players = {}
myprogress.player_huds = {}

myprogress.xp_scaling = {
    mining    = 100,
    lumbering = 80,
    digging   = 100,
    farming   = 50,
    building  = 200,
    combat    = 60
}

myprogress.skill_map = {
    mining = "mlevel",
    lumbering = "llevel",
    farming = "flevel",
    digging = "dlevel",
    building = "blevel",
    combat = "clevel"
}

myquests.settings = {
    difficulty = core.settings:get("myprogress_difficulty") or "normal" 
}

local path = core.get_modpath("myprogress")

dofile(path .. "/data.lua")

myprogress.load_data()

dofile(path .. "/nodes.lua")      
dofile(path .. "/hud.lua")        
dofile(path .. "/awards.lua")     
dofile(path .. "/functions.lua")
dofile(path .. "/chat_commands.lua")
dofile(path .. "/leaderboard.lua")

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

function myprogress.setup_machine_inv(pos)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size("src", 1)
    inv:set_size("dst", 2)
end
