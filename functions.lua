function myprogress.add_xp(player, skill, amount)
    if not player or not skill or not amount then return end
    
    local name = player:get_player_name()
    local stats = myprogress.players[name]
    if not stats then 
        myprogress.players[name] = {
            total_xp=0, mining=0, mlevel=0, lumbering=0, llevel=0,
            digging=0, dlevel=0, farming=0, flevel=0, building=0,
            blevel=0, combat=0, clevel=0
        }
        stats = myprogress.players[name]
    end

    local l_key = "mlevel"
    if skill == "mining"        then l_key = "mlevel"
    elseif skill == "digging"   then l_key = "dlevel"
    elseif skill == "combat"    then l_key = "clevel"
    elseif skill == "lumbering" then l_key = "llevel"
    elseif skill == "farming"   then l_key = "flevel"
    elseif skill == "building"  then l_key = "blevel"
    end

    stats[skill] = (stats[skill] or 0) + amount
    stats.total_xp = (stats.total_xp or 0) + amount

    local current_level = stats[l_key] or 0
    local scale = myprogress.xp_scaling[skill] or 50
    local next_lvl_xp = math.pow(current_level + 1, 2) * scale

    if myquests.settings.difficulty == "easy" then
        next_lvl_xp = math.ceil(next_lvl_xp * 0.5)
    end
    
    if stats[skill] >= next_lvl_xp then
        stats[l_key] = current_level + 1
        stats[skill] = 0
        
        myprogress.level_up_effect(player)
        core.sound_play("default_cool_lava", {to_player = name, gain = 1.0})
        
        core.chat_send_player(name, core.colorize("#00FF00", ">> LEVEL UP: " .. skill:upper() .. " is now " .. stats[l_key] .. "! <<"))
    end
    myprogress.update_hud(player)
end

function myprogress.level_up_effect(player)
    if not player then return end
    local pos = player:get_pos()
    
    core.sound_play("default_gravel_footstep", {
        pos = pos,
        gain = 1.0,
        max_hear_distance = 10,
    })

    core.add_particlespawner({
        amount = 60,
        time = 0.5,
        minpos = {x = pos.x - 0.5, y = pos.y + 0.2, z = pos.z - 0.5},
        maxpos = {x = pos.x + 0.5, y = pos.y + 2.0, z = pos.z + 0.5},
        minvel = {x = -2, y = 2, z = -2},
        maxvel = {x = 2, y = 5, z = 2},
        minacc = {x = 0, y = -5, z = 0},
        maxacc = {x = 0, y = -9, z = 0},
        minexptime = 1,
        maxexptime = 1.5,
        minsize = 2,
        maxsize = 5,
        collisiondetection = true,
        texture = "default_item_smoke.png^[colorize:#FFD700:200",
        glow = 14,
    })
end

function award_for_digging(node_name, player_name)
    local player = core.get_player_by_name(player_name)
    if not player or not myquests.players[player_name] then return end
    local q = myquests.players[player_name]
    
    for _, n in pairs(myprogress_nodes.mining) do
        if node_name == n then
            q.awards.miner = (q.awards.miner or 0) + 1
            if q.awards.miner >= (myquests.settings.miner or 10) then
                q.awards.miner = 0 
                q.awards.miner_level = (q.awards.miner_level or 0) + 1
                
                local tier = "bronze"
                if q.awards.miner_level >= 10 then tier = "master"
                elseif q.awards.miner_level >= 8 then tier = "diamond"
                elseif q.awards.miner_level >= 5 then tier = "gold"
                elseif q.awards.miner_level >= 3 then tier = "silver"
                end
                
                player:get_inventory():add_item("main", "myprogress:award_miner_"..tier.." 1")
                core.chat_send_player(player_name, "You earned a " .. tier:upper() .. " Mining Trophy!")
            end
        end
    end
end

function myprogress.show_stats_formspec(name, tab)
    local p = myprogress.players[name]
    if not myquests.players[name] then
        myquests.players[name] = {awards = {}}
    end
    local q = myquests.players[name]

    if not p then return end

	tab = tab or 0
    local formspec = "size[10,10.2]" ..
        "background[0,0;10,10.2;gui_formbg.png;true]" ..
        "tabheader[0,0;stats_tabs;Stats,Trophy Gallery;" .. (tab + 1) .. ";true;false]"

    if tab == 0 then
        formspec = formspec .. "label[3.8,0.5;== PLAYER STATISTICS ==]" ..
            "label[4.2,1;Total XP: " .. (p.total_xp or 0) .. "]"
        
        local skills = {
            {id="mining",    l="mlevel",  c="#FFD700", icon="default_tool_steelpick.png", n="Mining"},
            {id="digging",   l="dlevel",  c="#C0C0C0", icon="default_tool_steelshovel.png", n="Digging"},
            {id="lumbering", l="llevel",  c="#55FF55", icon="default_tool_steelaxe.png", n="Lumbering"},
            {id="farming",   l="flevel",  c="#00FF00", icon="farming_wheat_8.png", n="Farming"},
            {id="building",  l="blevel",  c="#AAAAAA", icon="default_brick.png", n="Building"},
            {id="combat",    l="clevel",  c="#FF5555", icon="default_tool_steelsword.png", n="Combat"}
        }

        local y = 2
        for _, s in ipairs(skills) do
            local lvl = p[s.l] or 0
            local xp = p[s.id] or 0
            local scale = (myprogress.xp_scaling and myprogress.xp_scaling[s.id]) or 50
            local goal = math.pow(lvl + 1, 2) * scale
            if (core.settings:get("myprogress_difficulty") or "hard") == "easy" then goal = math.ceil(goal * 0.5) end
            local percent = (goal > 0) and math.min(100, math.floor((xp / goal) * 100)) or 0

            formspec = formspec ..
                "image[1," .. y .. ";0.8,0.8;" .. s.icon .. "]" ..
                "label[2," .. y .. ";" .. core.colorize(s.c, s.n) .. "]" ..
                "label[2," .. y + 0.4 .. ";Level: " .. lvl .. "]" ..
                "box[4.5," .. y + 0.1 .. ";4,0.4;#333333]" ..
                "box[4.5," .. y + 0.1 .. ";" .. (4 * (percent/100)) .. ",0.4;" .. s.c .. "]" ..
                "label[5.8," .. y + 0.5 .. ";" .. xp .. " / " .. goal .. " XP]"
            y = y + 1
        end
    else
        formspec = formspec .. "label[3.8,0.5;== TROPHY GALLERY ==]"
        local trophies = {
            {id="miner",     key="miner_level",  n="Mining"},
            {id="digger",    key="digger_level", n="Digging"},
            {id="logger", key="logger_level", n="Lumbering"},
            {id="farmer",   key="farmer_level", n="Farming"},
            {id="builder",   key="builder_level", n="Building"},
            {id="combat",    key="slayer_level", n="Slayer"}
        }
        local tiers = {
            {id="bronze", req=1}, {id="silver", req=3}, {id="gold", req=5}, 
            {id="mese", req=8}, {id="diamond", req=10}
        }

        local total_unlocked = 0
        local total_possible = #trophies * #tiers

        for row, t in ipairs(trophies) do
            local y_pos = 0.2 + row
            formspec = formspec .. "label[0.5," .. (y_pos + 0.3) .. ";" .. t.n .. "]"
            
            local awards = q.awards or {}
            local p_lvl = awards[t.key] or 0
            
            for col, tier in ipairs(tiers) do
                local item = "myprogress:award_" .. t.id .. "_" .. tier.id
                if p_lvl < tier.req then
                    formspec = formspec .. "item_image[" .. (col + 2) .. "," .. y_pos .. ";0.8,0.8;" .. item .. "]" ..
                               "image[" .. (col + 2) .. "," .. y_pos .. ";0.8,0.8;default_stone.png^[opacity:180]"
                else
                    formspec = formspec .. "item_image[" .. (col + 2) .. "," .. y_pos .. ";1,1;" .. item .. "]"
                    total_unlocked = total_unlocked + 1
                end
            end

		local completion_pct = math.floor((total_unlocked / total_possible) * 100)
        local bar_color = "#00FF00" 
        if completion_pct < 30 then bar_color = "#FF5555" 
        elseif completion_pct < 70 then bar_color = "#FFFF55" end 

        formspec = formspec .. 
            "label[1,8.0;Total Completion: ]" .. --completion_pct .. "% (" .. total_unlocked .. "/" .. total_possible .. ")]" ..
            "box[1,7.5;8,0.4;#333333]" .. 
            "box[1,8.5;" .. (8 * (completion_pct / 100)) .. ",0.4;" .. bar_color .. "]" ..
            "button_exit[4,9.8;2,0.5;close;Close]"
        --
        end
    end

    core.show_formspec(name, "myprogress:stats", formspec)
end
core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "myprogress:stats" then return end
    if fields.stats_tabs then
        local tab = tonumber(fields.stats_tabs) - 1
        myprogress.show_stats_formspec(player:get_player_name(), tab)
    end
    if fields.stats_tabs then
    local name = player:get_player_name()
    	core.sound_play("gui_click", {to_player = name, gain = 0.5})
    	
    	local tab = tonumber(fields.stats_tabs) - 1
    	myprogress.show_stats_formspec(name, tab)
	end
end)
