-- ==========================================================
-- MYPROGRESS MOD - FUNCTIONS & LOGIC (functions.lua)
-- ==========================================================

-- Core function to add XP to a player for a specific skill
function myprogress.add_xp(player, skill, amount)
    if not player or not player:is_player() then return end
    local name = player:get_player_name()
    local stats = myprogress.players[name]
    
    if not stats then return end

    -- Update raw XP and total XP
    stats[skill] = (stats[skill] or 0) + amount
    stats.total_xp = (stats.total_xp or 0) + amount

    -- Determine corresponding level key (e.g., mining -> mlevel)
    local l_key = (myprogress.skill_map and myprogress.skill_map[skill]) or (skill .. "_level")

    local cur_lvl = stats[l_key] or 0
    local scale = (myprogress.xp_scaling and myprogress.xp_scaling[skill]) or 100
    
    -- Level Calculation (Quadratic scaling)
    local next_level = cur_lvl + 1
    local goal = math.pow(next_level, 2) * scale
    
    -- Difficulty Modifier
    if myquests.settings and myquests.settings.difficulty == "easy" then
        goal = math.ceil(goal * 0.5)
    end

    -- Check for Level Up
    if stats[skill] >= goal then
        stats[l_key] = next_level
        
        core.chat_send_player(name, core.colorize("#00FF00", 
            "*** LEVEL UP! *** Your " .. skill:upper() .. " reached level " .. stats[l_key]))
        
        -- Visual/Sound Feedback
        myprogress.level_up_effect(player)
        core.sound_play("player_level_up", {to_player = name, gain = 1.0})

        -- Milestone/Trophy handling
        if myquests.get_trophy_tier then
            local tier = myquests.get_trophy_tier(stats[l_key])
            if tier then
                myquests.give_milestone_rewards(player, skill, stats[l_key], tier)
            end
        end
    end

    -- Update HUD if applicable
    if myprogress.update_hud then
        myprogress.update_hud(player)
    end
end

-- Visual effect spawned on level up
function myprogress.level_up_effect(player)
    if not player then return end
    local pos = player:get_pos()
    if not pos then return end
    pos.y = pos.y + 1.5
    
    core.add_particlespawner({
        amount = 50,
        time = 0.5,
        minpos = {x=pos.x-0.5, y=pos.y, z=pos.z-0.5},
        maxpos = {x=pos.x+0.5, y=pos.y+1, z=pos.z+0.5},
        minvel = {x=-1, y=2, z=-1},
        maxvel = {x=1, y=4, z=1},
        minacc = {x=0, y=-2, z=0},
        maxacc = {x=0, y=-4, z=0},
        minexptime = 1,
        maxexptime = 2,
        minsize = 1,
        maxsize = 3,
        texture = "heart.png^[colorize:#00FF00:180",
    })
end

-- Formspec UI for statistics and trophies
function myprogress.show_stats_formspec(name, tab)
    if not myprogress.players then return end
    local p = myprogress.players[name]
    if not p then return end

    -- Ensure quest table exists
    if not myquests.players then myquests.players = {} end
    if not myquests.players[name] then
        myquests.players[name] = {awards = {}}
    end
    local q = myquests.players[name]

    tab = tab or 0
    local formspec = "size[10,10.2]" ..
        "background[0,0;10,10.2;gui_formbg.png;true]" ..
        "tabheader[0,0;stats_tabs;Stats,Trophy Gallery;" .. (tab + 1) .. ";true;false]"

    if tab == 0 then
        -- PAGE 1: STATISTICS
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
        -- PAGE 2: TROPHY GALLERY
        formspec = formspec .. "label[3.8,0.5;== TROPHY GALLERY ==]"
        local trophies = {
            {id="miner",    key="mlevel",  n="Mining"},
            {id="digger",   key="dlevel",  n="Digging"},
            {id="logger",   key="llevel",  n="Lumbering"},
            {id="farmer",   key="flevel",  n="Farming"},
            {id="builder",  key="blevel",  n="Builder"},
            {id="combat",   key="clevel",  n="Slayer"}
        }
        local tiers = {
            {id="bronze", req=5}, {id="silver", req=10}, {id="gold", req=15}, 
            {id="diamond", req=20}, {id="master", req=25}
        }

        local total_unlocked = 0
        local total_possible = #trophies * #tiers

        for row, t in ipairs(trophies) do
            local y_pos = 1 + row
            formspec = formspec .. "label[0.5," .. (y_pos + 0.3) .. ";" .. t.n .. "]"
            
            local p_lvl = p[t.key] or 0 
            
            for col, tier in ipairs(tiers) do
                local item = "myprogress:award_" .. t.id .. "_" .. tier.id
                local x_pos = col + 2
                if p_lvl < tier.req then
                    -- Locked icon (Greyed out)
                    formspec = formspec .. "item_image[" .. x_pos .. "," .. y_pos .. ";0.8,0.8;" .. item .. "]" ..
                               "image[" .. x_pos .. "," .. y_pos .. ";0.8,0.8;default_stone.png^[opacity:200]"
                else
                    -- Unlocked icon
                    formspec = formspec .. "item_image[" .. x_pos .. "," .. y_pos .. ";1,1;" .. item .. "]"
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

-- Handling Formspec interactions
core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "myprogress:stats" then return end
    if fields.stats_tabs then
        local name = player:get_player_name()
        local tab = tonumber(fields.stats_tabs) - 1
        core.sound_play("gui_click", {to_player = name, gain = 0.5})
        myprogress.show_stats_formspec(name, tab)
    end
end)

-- ==========================================================
-- WORLD EVENT HANDLERS (XP Sourcing)
-- ==========================================================

-- 1. Digging / Mining / Farming / Lumbering
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

-- 2. Building
core.register_on_placenode(function(pos, newnode, placer)
    if not placer or not placer:is_player() then return end
    myprogress.add_xp(placer, "building", 1)
end)

-- 3. Combat Logic
local function combat_callback(hitter, victim)
    if not hitter or not hitter:is_player() then return end
    if not victim or hitter == victim then return end

    -- Flat XP for a hit
    myprogress.add_xp(hitter, "combat", 1)
    
    -- Check for Kill XP (delayed check for HP update)
    core.after(0.1, function()
        if victim and victim:get_hp() <= 0 then
            myprogress.add_xp(hitter, "combat", 15)
        end
    end)
end

core.register_on_punchplayer(function(player, hitter)
    combat_callback(hitter, player)
end)

-- Global entity hook for mob combat
core.register_on_mods_loaded(function()
    for name, proto in pairs(core.registered_entities) do
        local old_punch = proto.on_punch
        proto.on_punch = function(self, hitter, ...)
            combat_callback(hitter, self.object)
            if old_punch then return old_punch(self, hitter, ...) end
        end
    end
end)

-- External Mod Support (mobs_redo)
if core.get_modpath("mobs") then
    core.after(2, function()
        if mobs and mobs.register_on_kill then
            mobs.register_on_kill(function(hitter, victim)
                if hitter and hitter:is_player() then
                    myprogress.add_xp(hitter, "combat", 15)
                end
            end)
        end
    end)
end
