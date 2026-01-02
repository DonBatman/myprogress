-- ==========================================================
-- ADMIN AND PLAYER CHAT COMMANDS (chat_commands.lua)
-- ==========================================================

-- 1. Check detailed levels and XP
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

-- 2. Brief stats overview
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

-- 3. Open the Formspec Stats Menu
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

-- 4. Reset a player's progress (Admin only)
core.register_chatcommand("resetstats", {
    params = "<playername>",
    description = "Reset a player's progress and quests",
    privs = {server = true},
    func = function(name, param)
        if param == "" then return false, "Please specify a player name." end
        
        if myprogress.players[param] then
            myprogress.players[param] = {
                total_xp = 0,
                mining=0, mlevel=0, lumbering=0, llevel=0, 
                digging=0, dlevel=0, farming=0, flevel=0, 
                building=0, blevel=0, combat=0, clevel=0
            }
            
            if myquests.players then
                myquests.players[param] = { 
                    awards = {},
                    given_awards = {}
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

-- 5. Test Level-up Visuals
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

-- 6. Set Skill Exactly (Admin only)
core.register_chatcommand("setskill", {
    params = "<skill> <level.fraction>",
    description = "Set a skill level exactly (e.g. mining 4.9)",
    privs = {server = true},
    func = function(name, param)
        local skill, level_str = param:match("^(%S+)%s+(%S+)$")
        local player = core.get_player_by_name(name)
        
        if not skill or not level_str or not player then
            return false, "Usage: /setskill <mining|lumbering|digging|farming|building|combat> <level>"
        end

        local level_val = tonumber(level_str)
        if not level_val then return false, "Invalid level number." end

        local stats = myprogress.players[name]
        if not stats then return false, "Player data not loaded." end

        local skill_map = {
            mining = {xp = "mining", lvl = "mlevel"},
            lumbering = {xp = "lumbering", lvl = "llevel"},
            digging = {xp = "digging", lvl = "dlevel"},
            farming = {xp = "farming", lvl = "flevel"},
            building = {xp = "building", lvl = "blevel"},
            combat = {xp = "combat", lvl = "clevel"}
        }

        local keys = skill_map[skill]
        if not keys then return false, "Unknown skill: " .. skill end

        local floor_lvl = math.floor(level_val)
        local fraction = level_val - floor_lvl
        local scale = (myprogress.xp_scaling and myprogress.xp_scaling[skill]) or 100
        local start_xp = math.pow(floor_lvl, 2) * scale
        local next_xp = math.pow(floor_lvl + 1, 2) * scale
        local gap = next_xp - start_xp
        local target_xp = math.floor(start_xp + (gap * fraction))

        stats[keys.lvl] = floor_lvl
        stats[keys.xp] = target_xp
        
        stats.total_xp = (stats.mining or 0) + (stats.lumbering or 0) + 
                         (stats.digging or 0) + (stats.farming or 0) + 
                         (stats.building or 0) + (stats.combat or 0)
        
        myprogress.update_hud(player)
        myprogress.save_data()

        return true, "Set " .. skill .. " to Level " .. level_val .. " (" .. target_xp .. " XP)."
    end,
})
