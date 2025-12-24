function myprogress.update_hud(player)
    if not player then return end
    local name = player:get_player_name()
    local stats = myprogress.players[name]
    if not stats then return end

    if myprogress.player_huds[name] then
        for _, id in pairs(myprogress.player_huds[name]) do
            player:hud_remove(id)
        end
    end
    myprogress.player_huds[name] = {}

    local function format_num(n)
        if not n then return "0" end
        return n >= 1000 and (math.floor(n/100)/10 .. "k") or n
    end

    local overall = (stats.mlevel or 0) + (stats.llevel or 0) + (stats.dlevel or 0) + 
                    (stats.flevel or 0) + (stats.blevel or 0) + (stats.clevel or 0)
    
    table.insert(myprogress.player_huds[name], player:hud_add({
        hud_elem_type = "text", position = {x=0, y=0}, offset = {x=20, y=20},
        text = "YOU ARE LEVEL: " .. overall, number = 0x00FFFF, alignment = {x=1, y=1}
    }))

    table.insert(myprogress.player_huds[name], player:hud_add({
        hud_elem_type = "text", position = {x=0, y=1}, offset = {x=20, y=-240},
        text = "TOTAL EXPERIENCE: " .. format_num(stats.total_xp or 0), number = 0xFFFF00, alignment = {x=1, y=0}
    }))

    local skills = {
        {k="mining",    l="MINING  ", c=0xffffff, o=0},
        {k="lumbering", l="LUMBER  ", c=0x55ff55, o=20},
        {k="digging",   l="DIGGING ", c=0xffd700, o=40},
        {k="farming",   l="FARMING ", c=0x00ff00, o=60},
        {k="building",  l="BUILDING", c=0xaaaaaa, o=80},
        {k="combat",    l="COMBAT  ", c=0xff5555, o=100}
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
        
        local scale = myprogress.xp_scaling[s.k] or 50
        local goal = math.pow(cur_lvl + 1, 2) * scale
        
        if myquests.settings.difficulty == "easy" then
            goal = math.ceil(goal * 0.5)
        end
        
        local bar = ""
        local percent = (goal > 0) and (cur_xp / goal) or 0
        local portion = math.floor(percent * 10)
        portion = math.min(math.max(portion, 0), 10)
        
        for i=1,10 do bar = bar .. (i <= portion and "|" or ".") end

        local display_text = s.l .. " Lv." .. cur_lvl .. " [" .. bar .. "] " .. format_num(cur_xp) .. "/" .. format_num(goal)

        table.insert(myprogress.player_huds[name], player:hud_add({
            hud_elem_type = "text", 
            position = {x=0, y=1}, 
            offset = {x=20, y=-210 + s.o},
            text = display_text,
            number = s.c, 
            alignment = {x=1, y=0}
        }))
    end
end
