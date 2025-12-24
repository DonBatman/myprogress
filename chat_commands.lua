core.register_chatcommand("mystats2", {
    description = "Show your current skill levels",
    func = function(name)
        local stats = myprogress.players[name]
        if not stats then return false, "No data found." end
        
        local msg = "--- YOUR STATS ---\n"
        msg = msg .. "Mining: " .. stats.mlevel .. " | Lumber: " .. stats.llevel .. "\n"
        msg = msg .. "Digging: " .. stats.dlevel .. " | Farming: " .. stats.flevel .. "\n"
        msg = msg .. "Combat: " .. stats.clevel .. " | Building: " .. stats.blevel
        
        return true, msg
    end,
})
core.register_chatcommand("mystats", {
    description = "Show your skill levels and XP progress.",
    func = function(name)
        myprogress.show_stats_formspec(name)
        return true
    end,
})

core.register_chatcommand("resetstats", {
    params = "<playername>",
    description = "Reset a player's progress and quests",
    privs = {server = true},
    func = function(name, param)
        if param == "" then return false, "Please specify a player name." end
        
        if myprogress.players[param] then
            myprogress.players[param] = {
                mining=0, mlevel=0, lumbering=0, llevel=0, 
                digging=0, dlevel=0, farming=0, flevel=0, 
                building=0, blevel=0, combat=0, clevel=0
            }
            myquests.players[param] = { awards = { miner=0, miner_level=0, digger=0, digger_level=0, logger=0, logger_level=0, builder=0, builder_level=0, farmer=0, farmer_level=0 } }
            
            myprogress.save_data()
            myquests.save_data()
            
            local player = core.get_player_by_name(param)
            if player then myprogress.update_hud(player) end
            
            return true, "Stats reset for " .. param
        end
        return false, "Player not found."
    end,
})
core.register_chatcommand("testeffect", {
    func = function(name)
        local player = core.get_player_by_name(name)
        myprogress.level_up_effect(player)
        return true, "Effect triggered!"
    end,
})
core.register_chatcommand("setskill", {
    params = "<skill> <level>",
    description = "Set your skill level (Dev use only). Skills: mining, digging, lumbering, farming, building, combat",
    privs = {server = true},
    func = function(name, param)
        local skill, level = param:match("^(%S+)%s+(%d+)$")
        if not skill or not level then
            return false, "Usage: /setskill <skill> <level>"
        end
        
        level = tonumber(level)
        local p = myprogress.players[name]
        local q = myquests.players[name]
        
        if not p or not q then 
            return false, "Player data not found." 
        end

        local key_map = {
            mining="mlevel", digging="dlevel", lumbering="llevel", 
            farming="flevel", building="blevel", combat="clevel"
        }
        
        local award_map = {
            mining="miner_level", digging="digger_level", lumbering="logger_level",
            farming="farmer_level", building="builder_level", combat="slayer_level"
        }

        local l_key = key_map[skill]
        local a_key = award_map[skill]

        if l_key and a_key then
            p[l_key] = level
            if not q.awards then q.awards = {} end
            q.awards[a_key] = level
            
            myprogress.save_data()
            myquests.save_data()
            myprogress.update_hud(core.get_player_by_name(name))
            
            return true, "Set " .. skill .. " to Level " .. level .. ". Check /mystats!"
        else
            return false, "Invalid skill name."
        end
    end,
})
