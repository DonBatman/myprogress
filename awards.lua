local function get_tier(level)
    if level >= 20 then return "diamond"
    elseif level >= 15 then return "mese"
    elseif level >= 10 then return "gold"
    elseif level >= 5 then return "silver"
    else return "bronze" end
end

local function inc_q(q, key)
    q.awards = q.awards or {}
    q.awards[key] = (q.awards[key] or 0) + 1
    return q.awards[key]
end

function award_for_digging(node_name, player_name)
    local player = core.get_player_by_name(player_name)
    local q = myquests.players[player_name]
    if not player or not q then return end

    for _, n in pairs(myprogress_nodes.mining) do
        if node_name == n then
            local count = inc_q(q, "miner")
            if count >= (myquests.settings.miner or 10) then
                q.awards.miner = 0 
                q.awards.miner_level = (q.awards.miner_level or 0) + 1
                local tier = get_tier(q.awards.miner_level)
                
                player:get_inventory():add_item("main", "myprogress:award_miner_" .. tier .. " 1")
                player:get_inventory():add_item("main", "default:diamond 1")
                
                core.chat_send_player(player_name, core.colorize("#FFFF00", 
                    "MINER QUEST LEVEL " .. q.awards.miner_level .. "! You earned a " .. tier:upper() .. " Trophy!"))
            end
            return
        end
    end

    for _, n in pairs(myprogress_nodes.digging) do
        if node_name == n then
            local count = inc_q(q, "digger")
            if count >= (myquests.settings.digger or 10) then
                q.awards.digger = 0
                q.awards.digger_level = (q.awards.digger_level or 0) + 1
                local tier = get_tier(q.awards.digger_level)
                
                player:get_inventory():add_item("main", "myprogress:award_digger_" .. tier .. " 1")
                player:get_inventory():add_item("main", "default:gold_ingot 2")
                
                core.chat_send_player(player_name, core.colorize("#FFD700", 
                    "DIGGER QUEST LEVEL " .. q.awards.digger_level .. "! You earned a " .. tier:upper() .. " Trophy!"))
            end
            return
        end
    end
end

function award_for_placing(node_name, player_name)
    local player = core.get_player_by_name(player_name)
    local q = myquests.players[player_name]
    if not player or not q then return end

    local count = inc_q(q, "builder")
    if count >= (myquests.settings.builder or 10) then
        q.awards.builder = 0
        q.awards.builder_level = (q.awards.builder_level or 0) + 1
        local tier = get_tier(q.awards.builder_level)
        
        player:get_inventory():add_item("main", "myprogress:award_builder_" .. tier .. " 1")
        
        core.chat_send_player(player_name, core.colorize("#AAAAAA", 
            "BUILDER QUEST LEVEL " .. q.awards.builder_level .. "! You earned a " .. tier:upper() .. " Trophy!"))
    end
end

function award_for_combat(player_name)
    local player = core.get_player_by_name(player_name)
    local q = myquests.players[player_name]
    if not player or not q then return end

    local count = inc_q(q, "slayer")
    if count >= (myquests.settings.slayer or 10) then
        q.awards.slayer = 0
        q.awards.slayer_level = (q.awards.slayer_level or 0) + 1
        local tier = get_tier(q.awards.slayer_level)
        
        player:get_inventory():add_item("main", "myprogress:award_combat_" .. tier .. " 1")
        
        core.chat_send_player(player_name, core.colorize("#FF5555", 
            "SLAYER QUEST LEVEL " .. q.awards.slayer_level .. "! You earned a " .. tier:upper() .. " Trophy!"))
    end
end

function award_for_lumbering(player_name)
    local player = core.get_player_by_name(player_name)
    local q = myquests.players[player_name]
    if not player or not q then return end

    local count = inc_q(q, "logger")
    if count >= (myquests.settings.logger or 10) then
        q.awards.logger = 0
        q.awards.logger_level = (q.awards.logger_level or 0) + 1
        local tier = get_tier(q.awards.logger_level)
        
        player:get_inventory():add_item("main", "myprogress:award_logger_" .. tier .. " 1")
        
        core.chat_send_player(player_name, core.colorize("#55FF55", 
            "LUMBER QUEST LEVEL " .. q.awards.logger_level .. "! You earned a " .. tier:upper() .. " Trophy!"))
    end
end

function award_for_farming(player_name)
    local player = core.get_player_by_name(player_name)
    local q = myquests.players[player_name]
    if not player or not q then return end

    local count = inc_q(q, "farmer")
    if count >= (myquests.settings.farmer or 10) then
        q.awards.farmer = 0
        q.awards.farmer_level = (q.awards.farmer_level or 0) + 1
        local tier = get_tier(q.awards.farmer_level)
        
        player:get_inventory():add_item("main", "myprogress:award_farming_" .. tier .. " 1")
        
        core.chat_send_player(player_name, core.colorize("#00FF00", 
            "FARMING QUEST LEVEL " .. q.awards.farmer_level .. "! You earned a " .. tier:upper() .. " Trophy!"))
    end
end
