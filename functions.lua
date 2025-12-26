function myprogress.add_xp(player, skill, amount)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()
    local stats = myprogress.players[name]
    
    if not stats then return end

    stats[skill] = (stats[skill] or 0) + amount
    stats.total_xp = (stats.total_xp or 0) + amount

    local l_map = {
        mining = "mlevel", lumbering = "llevel", digging = "dlevel",
        farming = "flevel", building = "blevel", combat = "clevel"
    }
    local l_key = l_map[skill] or "mlevel"

    local cur_lvl = stats[l_key] or 0
    local scale = (myprogress.xp_scaling and myprogress.xp_scaling[skill]) or 100
    
    local next_level = cur_lvl + 1
    local goal = math.pow(next_level, 2) * scale
    
    if myquests.settings and myquests.settings.difficulty == "easy" then
        goal = math.ceil(goal * 0.5)
    end

    if stats[skill] >= goal then
        stats[l_key] = next_level
        
        core.chat_send_player(name, core.colorize("#00FF00", 
            "LEVEL UP! Your " .. skill:upper() .. " is now level " .. stats[l_key]))
        
        myprogress.level_up_effect(player)

        if myquests.get_trophy_tier then
            local tier = myquests.get_trophy_tier(stats[l_key])
            if tier then
                myquests.give_milestone_rewards(player, skill, stats[l_key], tier)
            end
        end
    end

    if myprogress.update_hud then
        myprogress.update_hud(player)
    end
end

function myprogress.level_up_effect(player)
    if not player then return end
    local pos = player:get_pos()
    pos.y = pos.y + 2
    
    core.add_particlespawner({
        amount = 50,
        time = 1,
        minpos = {x=pos.x-1, y=pos.y, z=pos.z-1},
        maxpos = {x=pos.x+1, y=pos.y+1, z=pos.z+1},
        minvel = {x=-1, y=2, z=-1},
        maxvel = {x=1, y=5, z=1},
        minacc = {x=0, y=-2, z=0},
        maxacc = {x=0, y=-4, z=0},
        minexptime = 1,
        maxexptime = 2,
        minsize = 1,
        maxsize = 3,
        texture = "heart.png^[colorize:#00FF00:150",
    })
end

function myprogress.show_stats_formspec(name, tab)
    if not myprogress.players then return end
    
    local p = myprogress.players[name]
    
    if not myquests.players then myquests.players = {} end
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
            local scale = (myprogress.xp_scaling and myprogress.xp_scaling[s.id]) or 100
            local goal = math.pow(lvl + 1, 2) * scale
            
            if myquests.settings and myquests.settings.difficulty == "easy" then 
                goal = math.ceil(goal * 0.5) 
            end
            
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
        formspec = formspec .. "button_exit[4,9.5;2,0.5;close;Close]"
    else
        formspec = formspec .. "label[3.8,0.5;== TROPHY GALLERY ==]"
        local trophies = {
            {id="miner",   key="mlevel",  n="Mining"},
            {id="digger",  key="dlevel",  n="Digging"},
            {id="logger",  key="llevel",  n="Lumbering"},
            {id="farmer",  key="flevel",  n="Farming"},
            {id="builder", key="blevel",  n="Building"},
            {id="combat",  key="clevel",  n="Slayer"}
        }
        local tiers = {
            {id="bronze", req=5}, {id="silver", req=10}, {id="gold", req=15}, 
            {id="diamond", req=20}, {id="master", req=25}
        }

        local total_unlocked = 0
        local total_possible = #trophies * #tiers

        for row, t in ipairs(trophies) do
            local y_pos = 0.5 + row
            formspec = formspec .. "label[0.5," .. (y_pos + 0.3) .. ";" .. t.n .. "]"
            
            local awards = q.awards or {}
            local p_lvl = p[t.key] or 0 
            
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
        end

        local completion_pct = math.floor((total_unlocked / total_possible) * 100)
        local bar_color = "#00FF00" 
        if completion_pct < 30 then bar_color = "#FF5555" 
        elseif completion_pct < 70 then bar_color = "#FFFF55" end 

        formspec = formspec .. 
            "label[1,8.0;Collection Completion: " .. completion_pct .. "% (" .. total_unlocked .. "/" .. total_possible .. ")]" ..
            "box[1,8.5;8,0.4;#333333]" .. 
            "box[1,8.5;" .. (8 * (completion_pct / 100)) .. ",0.4;" .. bar_color .. "]" ..
            "button_exit[4,9.5;2,0.5;close;Close]"
    end

    core.show_formspec(name, "myprogress:stats", formspec)
end

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "myprogress:stats" then return end
    if fields.stats_tabs then
        local name = player:get_player_name()
        local tab = tonumber(fields.stats_tabs) - 1
        core.sound_play("gui_click", {to_player = name, gain = 0.5})
        myprogress.show_stats_formspec(name, tab)
    end
end)

core.register_on_dignode(function(pos, oldnode, digger)
    if not digger or not digger:is_player() then return end
    local node_name = oldnode.name
    
    if myprogress_nodes.digging[node_name] then
        myprogress.add_xp(digger, "digging", myprogress_nodes.digging[node_name])
    elseif myprogress_nodes.mining[node_name] then
        myprogress.add_xp(digger, "mining", myprogress_nodes.mining[node_name])
    elseif myprogress_nodes.lumbering[node_name] then
        myprogress.add_xp(digger, "lumbering", myprogress_nodes.lumbering[node_name])
    elseif myprogress_nodes.farming[node_name] then
        myprogress.add_xp(digger, "farming", myprogress_nodes.farming[node_name])
    end
end)

core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    if not placer or not placer:is_player() then return end
    myprogress.add_xp(placer, "building", 1)
end)

core.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    if hitter and hitter:is_player() and damage > 0 then
        myprogress.add_xp(hitter, "combat", 1)
    end
end)

core.register_on_dieplayer(function(player, reason)
    if reason.type == "punch" and reason.puncher then
        local killer = reason.puncher
        if killer:is_player() then
            myprogress.add_xp(killer, "combat", 10)
        end
    end
end)
