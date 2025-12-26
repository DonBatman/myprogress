-- ==========================================================
-- CHAT COMMANDS (chat_commands.lua)
-- ==========================================================

-- Check current levels and XP (Text version)
core.register_chatcommand("level", {
    description = "Check your current levels and total XP",
    func = function(name)
        local stats = myprogress.players[name]
        if not stats then return false, "No data found." end
        
        local overall = (stats.mlevel or 0) + (stats.llevel or 0) + (stats.dlevel or 0) + 
                        (stats.flevel or 0) + (stats.blevel or 0) + (stats.clevel or 0)
        
        local msg = core.colorize("#00FFFF", "\n--- " .. name:upper() .. "'S PROGRESS ---") ..
                    "\nOverall Level: " .. overall ..
                    "\nMining: L." .. (stats.mlevel or 0) .. " (" .. (stats.mining or 0) .. " XP)" ..
                    "\nWood: L." .. (stats.llevel or 0) .. " (" .. (stats.lumbering or 0) .. " XP)" ..
                    "\nDigging: L." .. (stats.dlevel or 0) .. " (" .. (stats.digging or 0) .. " XP)" ..
                    "\nFarming: L." .. (stats.flevel or 0) .. " (" .. (stats.farming or 0) .. " XP)" ..
                    "\nBuilding: L." .. (stats.blevel or 0) .. " (" .. (stats.building or 0) .. " XP)" ..
                    "\nCombat: L." .. (stats.clevel or 0) .. " (" .. (stats.combat or 0) .. " XP)"
        
        return true, msg
    end,
})

-- Shortened summary of skill levels
core.register_chatcommand("mystats2", {
    description = "Show your current skill levels",
    func = function(name)
        local stats = myprogress.players[name]
        if not stats then return false, "No data found." end
        
        local msg = "--- YOUR STATS ---\n"
        msg = msg .. "Mining: " .. (stats.mlevel or 0) .. " | Lumber: " .. (stats.llevel or 0) .. "\n"
        msg = msg .. "Digging: " .. (stats.dlevel or 0) .. " | Farming: " .. (stats.flevel or 0) .. "\n"
        msg = msg .. "Combat: " .. (stats.clevel or 0) .. " | Building: " .. (stats.blevel or 0)
        
        return true, msg
    end,
})

-- Open the GUI Formspec for stats
core.register_chatcommand("mystats", {
    description = "Show your skill levels and XP progress in a menu.",
    func = function(name)
        if myprogress.show_stats_formspec then
            myprogress.show_stats_formspec(name)
            return true
        else
            return false, "Stats menu not available."
        end
    end,
})

-- Reset a player's progress (Admin only)
core.register_chatcommand("resetstats", {
    params = "<playername>",
    description = "Reset a player's progress and quests",
    privs = {server = true},
    func = function(name, param)
        if param == "" then return false, "Please specify a player name." end
        
        if myprogress.players[param] then
            -- Reset Skill Progress
            myprogress.players[param] = {
                total_xp = 0,
                mining=0, mlevel=0, lumbering=0, llevel=0, 
                digging=0, dlevel=0, farming=0, flevel=0, 
                building=0, blevel=0, combat=0, clevel=0
            }
            
            -- Reset Quests/Awards if table exists
            if myquests.players then
                myquests.players[param] = { 
                    awards = { 
                        miner=0, miner_level=0, digger=0, digger_level=0, 
                        logger=0, logger_level=0, builder=0, builder_level=0, 
                        farmer=0, farmer_level=0 
                    } 
                }
            end
            
            myprogress.save_data()
            if myquests.save_data then myquests.save_data() end
            
            local player = core.get_player_by_name(param)
            if player then myprogress.update_hud(player) end
            
            return true, "Stats and progress reset for " .. param
        end
        return false, "Player not found."
    end,
})

-- Test the level-up visual effect
core.register_chatcommand("testeffect", {
    description = "Trigger the level-up visual effect for yourself",
    func = function(name)
        local player = core.get_player_by_name(name)
        if player and myprogress.level_up_effect then
            myprogress.level_up_effect(player)
            return true, "Effect triggered!"
        end
        return false, "Effect function or player not found."
    end,
})

-- Manually set a skill level (Admin/Dev only)
core.register_chatcommand("setskill", {
    params = "<skill> <level>",
    description = "Set your skill level. Skills: mining, digging, lumbering, farming, building, combat",
    privs = {server = true},
    func = function(name, param)
        local skill, level = param:match("^(%S+)%s+(%d+)$")
        if not skill or not level then
            return false, "Usage: /setskill <skill> <level>"
        end
        
        level = tonumber(level)
        local p = myprogress.players[name]
        
        if not p then 
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

        if l_key then
            p[l_key] = level
            
            -- Sync with Quest awards if applicable
            if myquests.players and myquests.players[name] then
                local q = myquests.players[name]
                if not q.awards then q.awards = {} end
                if a_key then q.awards[a_key] = level end
                if myquests.save_data then myquests.save_data() end
            end
            
            myprogress.save_data()
            myprogress.update_hud(core.get_player_by_name(name))
            
            return true, "Set " .. skill .. " to Level " .. level .. ". Check your HUD or /mystats!"
        else
            return false, "Invalid skill name. Choose: mining, digging, lumbering, farming, building, or combat."
        end
    end,
})
