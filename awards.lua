-- ==========================================================
-- AWARDS, MACHINES & DATA PERSISTENCE (awards.lua)
-- ==========================================================

-- Initialize global table if not already done in main.lua
myprogress = myprogress or {}
myprogress.players = myprogress.players or {}
myprogress.xp_scaling = {
    mining = 100,
    lumbering = 100,
    farming = 100,
    digging = 100,
    building = 100,
    combat = 100
}

-- Mapping helper: Maps the Skill ID used in code to the Level Key in player data
local skill_map = {
    mining = "mlevel",
    lumbering = "llevel",
    farming = "flevel",
    digging = "dlevel",
    building = "blevel",
    combat = "clevel"
}

-- Trophy Registration Logic
local awards_categories = {"Miner", "Digger", "Logger", "Builder", "Farmer", "Combat"}
local award_levels = {
    {"Bronze", "#cd7f32", 5},
    {"Silver", "#c0c0c0", 10},
    {"Gold",   "#ffd700", 20},
    {"Diamond","#00ffff", 40},
    {"Master", "#333333", 60}
}

for _, a in pairs(awards_categories) do
    local al = string.lower(a)
    for _, level_data in ipairs(award_levels) do
        local b = level_data[1]
        local c = level_data[2]
        local bl = string.lower(b)

        core.register_node("myprogress:award_"..al.."_"..bl, {
            description = b.." "..a.." Trophy",
            drawtype = "mesh",
            mesh = "myprogress_award_" .. al .. ".obj", 
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

-- Award Definitions
local awards_list = {
    -- Functional Items
    {skill="mining", level=5, item="default:pick_steel", msg="Apprentice Miner: Steel Pickaxe Unlocked!"},
    {skill="mining", level=20, item="myprogress:master_smelter", msg="Master Miner: You can now place and use the Master Smelter!"},
}

-- Automatically populate awards_list with Trophies based on the registration loops
for _, category in pairs(awards_categories) do
    local skill_id = category == "Logger" and "lumbering" or string.lower(category)
    for _, level_data in ipairs(award_levels) do
        local tier_name = level_data[1]
        local tier_lvl = level_data[3]
        table.insert(awards_list, {
            skill = skill_id,
            level = tier_lvl,
            item = "myprogress:award_" .. string.lower(category) .. "_" .. string.lower(tier_name),
            msg = tier_name .. " " .. category .. " Trophy Awarded!"
        })
    end
end

-- Function to check and give awards
function myprogress.check_awards(player, skill, level)
    local name = player:get_player_name()
    local stats = myprogress.players[name]
    if not stats then return end
    
    stats.awards = stats.awards or {}

    for _, award in ipairs(awards_list) do
        if award.skill == skill and level >= award.level then
            local award_id = award.skill .. "_" .. award.level .. "_" .. award.item
            if not stats.awards[award_id] then
                -- Give item
                local inv = player:get_inventory()
                local stack = ItemStack(award.item)
                if inv:room_for_item("main", stack) then
                    inv:add_item("main", stack)
                else
                    core.add_item(player:get_pos(), stack)
                end
                
                -- Notify player
                core.chat_send_player(name, core.colorize("#FFFF00", "[AWARD] " .. award.msg))
                
                -- Mark as claimed
                stats.awards[award_id] = true
                myprogress.save_data()
            end
        end
    end
end

-- Force a re-check of all awards when a player joins
core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    core.after(2, function()
        local stats = myprogress.players[name]
        if stats then
            for skill, level_key in pairs(skill_map) do
                local current_lvl = stats[level_key] or 0
                if current_lvl > 0 then
                    myprogress.check_awards(player, skill, current_lvl)
                end
            end
        end
    end)
end)

-- Data Loading Logic
local function load_data()
    local filepath = core.get_worldpath() .. "/myprogress_data.json"
    local file = io.open(filepath, "r")
    if not file then
        filepath = core.get_worldpath() .. "/myprogress_data.txt"
        file = io.open(filepath, "r")
    end

    if file then
        local content = file:read("*all")
        file:close()
        local data = core.parse_json(content) or core.deserialize(content)
        if type(data) == "table" then
            myprogress.players = data
            core.log("action", "[MyProgress] Data loaded successfully from " .. filepath)
        end
    end
end

-- Force Save Function
function myprogress.save_data()
    local filepath = core.get_worldpath() .. "/myprogress_data.json"
    local file = io.open(filepath, "w")
    if file then
        local data = core.write_json(myprogress.players)
        file:write(data)
        file:close()
    end
end

-- Improved Machine Right-Click
local function machine_rightclick(pos, clicker, title, skill_id)
    local name = clicker:get_player_name()
    local stats = myprogress.players[name]
    if not stats then return end

    local req_lvl = 20
    local level_key = skill_map[skill_id]
    local current_level = stats[level_key] or 0
    
    if current_level < req_lvl then
        core.chat_send_player(name, core.colorize("#FF0000", 
            "Access Denied: Master " .. title .. " requires " .. skill_id:upper() .. " Level " .. req_lvl))
        return
    end
    
    local pos_str = pos.x .. "," .. pos.y .. "," .. pos.z
    local fs = "size[8,9]background[-0.2,-0.2;8.4,9.4;gui_formbg.png;true]" ..
               "label[3,0.5;Master " .. title .. " Interface]" ..
               "list[nodemeta:" .. pos_str .. ";src;3.5,1.5;1,1;]" ..
               "list[nodemeta:" .. pos_str .. ";dst;3,3;2,1;]" ..
               "list[current_player;main;0,5;8,4;]" ..
               "listring[nodemeta:" .. pos_str .. ";src]listring[current_player;main]" ..
               "listring[nodemeta:" .. pos_str .. ";dst]listring[current_player;main]"
    core.show_formspec(name, "myprogress:machine_" .. pos_str, fs)
end

-- Master Smelter
core.register_node("myprogress:master_smelter", {
    description = "Master Miner's Smelter (Level 20 Mining Required)",
    tiles = {"myprogress_miners_smelter.png"},
    drawtype = "mesh",
    mesh = "myprogress_miners_smelter.obj",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {cracky = 2, stone = 1},
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("src", 1)
        inv:set_size("dst", 2)
        core.get_node_timer(pos):start(1.5)
    end,
    on_rightclick = function(pos, node, clicker)
        machine_rightclick(pos, clicker, "Smelter", "mining")
    end,
    on_timer = function(pos)
        local inv = core.get_meta(pos):get_inventory()
        local input = inv:get_stack("src", 1)
        if not input:is_empty() then
            local res, after = core.get_craft_result({method="cooking", width=1, items={input}})
            if res and not res.item:is_empty() then
                if inv:room_for_item("dst", res.item) then
                    inv:set_stack("src", 1, after.items[1])
                    inv:add_item("dst", res.item)
                end
            end
        end
        return true
    end,
})

-- Emergency sync command
core.register_chatcommand("sync_levels", {
    description = "Force syncs XP data to levels",
    privs = {interact = true},
    func = function(name)
        local stats = myprogress.players[name]
        if not stats then return false, "No data found." end
        for skill, level_key in pairs(skill_map) do
            local xp = stats[skill] or 0
            local scale = myprogress.xp_scaling[skill] or 100
            local calculated_lvl = math.floor(math.sqrt(xp / scale))
            stats[level_key] = math.max(stats[level_key] or 0, calculated_lvl)
        end
        myprogress.save_data()
        return true, "Levels re-synced."
    end
})

load_data()
