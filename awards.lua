-- ==========================================================
-- AWARDS, TROPHIES, AND MASTER MACHINES (awards.lua)
-- ==========================================================

myquests.trophy_tiers = {
    {name = "bronze",  min = 5},
    {name = "silver",  min = 10},
    {name = "gold",    min = 15},
    {name = "diamond", min = 20},
    {name = "master",  min = 25}
}

-- 1. Helper: Level to Tier Mapper
function myquests.get_trophy_tier(level)
    if level >= 25 then return "master"
    elseif level >= 20 then return "diamond"
    elseif level >= 15 then return "gold"
    elseif level >= 10 then return "silver"
    elseif level >= 5 then return "bronze"
    end
    return nil
end

-- 2. Trophy Registration (Nodes with Mesh)
local awards = {"Miner", "Digger", "Logger", "Builder", "Farmer", "Combat"}
local award_levels = {
    {"Bronze", "#cd7f32"},
    {"Silver", "#c0c0c0"},
    {"Gold",   "#ffd700"},
    {"Diamond","#00ffff"},
    {"Master", "#ff00ff"}
}

for _, a in pairs(awards) do
    local al = string.lower(a)
    for _, level_data in ipairs(award_levels) do
        local b = level_data[1]
        local c = level_data[2]
        local bl = string.lower(b)

        core.register_node("myprogress:award_"..al.."_"..bl, {
            description = b.." "..a.." Trophy",
            drawtype = "mesh",
            mesh = "myprogress_award_"..al..".obj", 
            tiles = {"default_silver_sand.png^[colorize:"..c..":160"}, 
            paramtype = "light",
            paramtype2 = "facedir",
            groups = {cracky = 3, trophy = 1, not_in_creative_inventory = 1},
            light_source = (bl == "diamond" or bl == "master") and 3 or 0,
            selection_box = {
                type = "fixed",
                fixed = {-0.3, -0.5, -0.3, 0.3, 0.3, 0.3}
            }
        })
    end
end

-- 3. Master Machine Registrations (Level 20 Required)

local function setup_inv(pos)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_size("src", 1)
    inv:set_size("dst", 2)
end

-- Shared right-click logic for Master Machines
local function machine_rightclick(pos, clicker, title, skill_key, req_lvl)
    local name = clicker:get_player_name()
    local stats = myprogress.players[name]
    
    if not stats or (stats[skill_key] or 0) < req_lvl then
        core.chat_send_player(name, core.colorize("#FF0000", "Access Denied: " .. title .. " Level " .. req_lvl .. " required."))
        return
    end
    
    local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
    local fs = "size[8,9]" ..
               "background[0,0;8,9;gui_formbg.png;true]" ..
               "label[3.2,0.5;" .. title .. "]" ..
               "list[nodemeta:" .. pos_str .. ";src;3.5,1.5;1,1;]" ..
               "list[nodemeta:" .. pos_str .. ";dst;3,3;2,1;]" ..
               "list[current_player;main;0,5;8,4;]" ..
               "listring[nodemeta:" .. pos_str .. ";src]" ..
               "listring[current_player;main]"
    
    core.show_formspec(name, "myprogress:machine_" .. pos_str, fs)
end

core.register_node("myprogress:master_smelter", {
    description = "Master Miner's Smelter (Level 20 Required)",
    tiles = {"myprogress_miners_smelter.png"},
    drawtype = "mesh",
    mesh = "myprogress_miners_smelter.obj",
    paramtype2 = "facedir",
    groups = {cracky = 2},
    on_construct = setup_inv,
    on_rightclick = function(pos, node, clicker)
        machine_rightclick(pos, clicker, "Master Smelter", "mlevel", 20)
    end,
})

core.register_node("myprogress:master_sawmill", {
    description = "Master Lumberer's Sawmill (Level 20 Required)",
    tiles = {"myprogress_loggers_mill.png"},
    drawtype = "mesh",
    mesh = "myprogress_loggers_mill.obj",
    paramtype2 = "facedir",
    groups = {choppy = 2},
    on_construct = setup_inv,
    on_rightclick = function(pos, node, clicker)
        machine_rightclick(pos, clicker, "Master Sawmill", "llevel", 20)
    end,
})

core.register_node("myprogress:master_harvester", {
    description = "Master Farmer's Harvester (Level 20 Required)",
    tiles = {"default_steel_block.png^[colorize:#00FF00:100"},
    groups = {cracky = 2},
    on_construct = setup_inv,
    on_rightclick = function(pos, node, clicker)
        machine_rightclick(pos, clicker, "Master Harvester", "flevel", 20)
    end,
})

core.register_node("myprogress:master_sifter", {
    description = "Master Digger's Sifter (Level 20 Required)",
    tiles = {"default_steel_block.png^[colorize:#FFD700:100"},
    groups = {cracky = 2},
    on_construct = setup_inv,
    on_rightclick = function(pos, node, clicker)
        machine_rightclick(pos, clicker, "Master Sifter", "dlevel", 20)
    end,
})

-- 4. Reward Granting Logic (With Duplicate Prevention)
function myquests.give_milestone_rewards(player, skill, level, tier)
    if not player then return end
    local name = player:get_player_name()
    local pos = player:get_pos()
    
    -- Safety check for quest data tables (FIX FOR NIL PLAYER TABLE)
    if not myquests.players then 
        myquests.players = {} 
    end
    
    if not myquests.players[name] then 
        myquests.players[name] = {awards = {}, given_awards = {}} 
    end
    
    local q = myquests.players[name]
    if not q.given_awards then 
        q.given_awards = {} 
    end

    -- Normalize Skill IDs for Item Names
    local skill_id = skill
    if skill == "digging" then skill_id = "digger"
    elseif skill == "lumbering" then skill_id = "logger"
    elseif skill == "mining" then skill_id = "miner"
    elseif skill == "farming" then skill_id = "farmer"
    elseif skill == "building" then skill_id = "builder"
    elseif skill == "combat" then skill_id = "combat"
    end

    -- UNIQUE CHECK: Prevent getting 2 of the same trophy
    local award_key = skill_id .. "_" .. tier
    if q.given_awards[award_key] then
        return 
    end

    local inv = player:get_inventory()
    local trophy = "myprogress:award_" .. skill_id .. "_" .. tier

    -- Grant Trophy
    if inv:room_for_item("main", trophy) then
        inv:add_item("main", trophy)
        core.chat_send_player(name, core.colorize("#FFD700", "CONGRATULATIONS! You received the " .. tier:upper() .. " " .. skill:upper() .. " Trophy!"))
    else
        -- If inventory is full, drop it on the ground
        core.add_item(pos, trophy)
        core.chat_send_player(name, core.colorize("#FFA500", "Inventory full! Your " .. tier:upper() .. " " .. skill:upper() .. " Trophy was dropped at your feet."))
    end
    -- Mark as awarded regardless of how it was delivered
    q.given_awards[award_key] = true

    -- Grant Master Machine at Level 20
    if level == 20 then
        local machine = nil
        if skill == "mining" then machine = "myprogress:master_smelter"
        elseif skill == "lumbering" then machine = "myprogress:master_sawmill"
        elseif skill == "farming" then machine = "myprogress:master_harvester"
        elseif skill == "digging" then machine = "myprogress:master_sifter" end
        
        if machine then
            if inv:room_for_item("main", machine) then
                inv:add_item("main", machine)
                core.chat_send_player(name, core.colorize("#FFD700", "LEGENDARY: You unlocked a Master Machine for your skill!"))
            else
                core.add_item(pos, machine)
                core.chat_send_player(name, core.colorize("#FFA500", "Inventory full! Your Master Machine was dropped at your feet."))
            end
        end
    end
    
    -- Broadcast Milestone to Server
    core.chat_send_all(core.colorize("#ffd700", "[Milestone] " .. name .. " reached " .. skill:upper() .. " level " .. level .. "!"))
    core.sound_play("default_message", {to_player = name, gain = 1.0})
end
