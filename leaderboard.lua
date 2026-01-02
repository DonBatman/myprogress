function myprogress.get_leaderboard()
    local board = {}

    for name, stats in pairs(myprogress.players) do
        if type(stats) == "table" then
            local total_lvl = (stats.mlevel or 0) + (stats.llevel or 0) + 
                              (stats.dlevel or 0) + (stats.flevel or 0) + 
                              (stats.blevel or 0) + (stats.clevel or 0)
            
            table.insert(board, {name = name, level = total_lvl})
        end
    end

    table.sort(board, function(a, b)
        return a.level > b.level
    end)

    return board
end

core.register_chatcommand("top", {
    description = "View the top 5 players on the server and your rank",
    func = function(name)
        local board = myprogress.get_leaderboard()
        
        if #board == 0 then
            return true, "No players found in the records."
        end

        local msg = core.colorize("#00FFFF", "=== SERVER TOP PLAYERS ===\n")
        local player_rank = 0
        
        for i = 1, math.min(5, #board) do
            local color = "#FFFFFF"
            if i == 1 then color = "#FFD700"
            elseif i == 2 then color = "#C0C0C0"
            elseif i == 3 then color = "#CD7F32"
            end
            
            msg = msg .. core.colorize(color, i .. ". " .. board[i].name .. " - Level " .. board[i].level) .. "\n"
            
            if board[i].name == name then player_rank = i end
        end

        if player_rank == 0 then
            for i, entry in ipairs(board) do
                if entry.name == name then
                    msg = msg .. "...\n"
                    msg = msg .. i .. ". " .. entry.name .. " - Level " .. entry.level .. " (You)\n"
                    break
                end
            end
        end
        
        return true, msg
    end,
})
