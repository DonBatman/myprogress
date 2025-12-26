myprogress.player_huds = myprogress.player_huds or {}

local function format_num(n)
    if not n then return "0" end
    if n >= 1000 then return (math.floor(n/100)/10 .. "k") end
    return tostring(n)
end

function myprogress.update_hud(player)
    if not player then return end
    local name = player:get_player_name()
    
    if not myprogress.players or not myprogress.players[name] then return end
    local stats = myprogress.players[name]

    myprogress.player_huds[name] = myprogress.player_huds[name] or {}
    local huds = myprogress.player_huds[name]

    local ui_pos = {x = 0, y = 1}
    local ui_align = {x = 1, y = -1}

    local function set_hud_element(id_key, text, color, offset_y)
        if huds[id_key] then
            player:hud_change(huds[id_key], "text", text)
        else
            huds[id_key] = player:hud_add({
                hud_elem_type = "text",
                position = ui_pos,
                offset = {x = 20, y = offset_y},
                text = text,
                number = color,
                alignment = ui_align,
            })
        end
    end

    local overall = (stats.mlevel or 0) + (stats.llevel or 0) + (stats.dlevel or 0) + 
                    (stats.flevel or 0) + (stats.blevel or 0) + (stats.clevel or 0)
    
    local main_text = "YOUR MAIN LEVEL: " .. overall .. "   |   TOTAL XP: " .. stats.total_xp or 0
    set_hud_element("main", main_text, 0x00FFFF, -20)

    local skills = {
        {k="mining",    l="Mining",  	c=0xffffff, o=-40},
        {k="lumbering", l="Logging",  c=0x55ff55, o=-60},
        {k="digging",   l="Digging", 	c=0xffd700, o=-80},
        {k="farming",   l="Farming",    c=0x00ff00, o=-100},
        {k="building",  l="Building",   c=0xaaaaaa, o=-120},
        {k="combat",    l="Fighting",   c=0xff5555, o=-140}
    }

    for _, s in ipairs(skills) do
        local l_key = "mlevel"
        if s.k == "lumbering" then l_key = "llevel"
        elseif s.k == "digging"   then l_key = "dlevel"
        elseif s.k == "farming"   then l_key = "flevel"
        elseif s.k == "building"  then l_key = "blevel"
        elseif s.k == "combat"    then l_key = "clevel" end
        
        local cur_xp = stats[s.k] or 0
        local cur_lvl = stats[l_key] or 0
        
        local scale = (myprogress.xp_scaling and myprogress.xp_scaling[s.k]) or 100
        local goal = math.pow(cur_lvl + 1, 2) * scale
        
        if myquests.settings and myquests.settings.difficulty == "easy" then
            goal = math.ceil(goal * 0.5)
        end
        
        local bar = ""
        local percent = math.min(cur_xp / math.max(goal, 1), 1)
        local portion = math.floor(percent * 10)
        for i=1,10 do bar = bar .. (i <= portion and "|" or ".") end
        
        local display_text = string.format("%s Level %d [%s] %s/%s", s.l, cur_lvl, bar, format_num(cur_xp), format_num(goal))
        set_hud_element(s.k, display_text, s.c, s.o)
    end
end

core.register_on_joinplayer(function(player)
    core.after(2, function()
        if player:is_player() then
            myprogress.update_hud(player)
        end
    end)
end)
