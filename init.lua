myprogress = {}
myprogress.players = {}
myprogress_nodes = {}
local player_huds = {}

local path = core.get_modpath("myprogress")
dofile(path .. "/data.lua")

local xp_scaling = {mining = 15, lumbering = 20, digging = 10, farming = 5, building = 50}

function myprogress.get_bar(skill, xp, level)
	local base = xp_scaling[skill]
	local cur_xp = math.floor(base * (level ^ 1.5))
	local nxt_xp = math.floor(base * ((level + 1) ^ 1.5))
	local progress = math.max(0, math.min(1, (xp - cur_xp) / (nxt_xp - cur_xp)))
	local bar = "[" .. string.rep("|", math.floor(progress * 10)) .. string.rep(".", 10 - math.floor(progress * 10)) .. "]"
	return bar .. " " .. math.floor(progress * 100) .. "%"
end

function myprogress.update_hud(player)
	local name = player:get_player_name()
	local s = myprogress.players[name]
	if not s then return end

	local txt = 
		"⛏ Mining Lvl "..s.mlevel.." "..myprogress.get_bar("mining", s.mining, s.mlevel)..
		"\n Lumber Lvl "..s.llevel.." "..myprogress.get_bar("lumbering", s.lumbering, s.llevel)..
		"\n Build Lvl "..s.blevel.." "..myprogress.get_bar("building", s.building, s.blevel)..
		"\n Farm Lvl "..s.flevel.." "..myprogress.get_bar("farming", s.farming, s.flevel)..
		"\n Dig Lvl "..s.dlevel.." "..myprogress.get_bar("digging", s.digging, s.dlevel)

	if player_huds[name] then 
		player:hud_change(player_huds[name], "text", txt)
	else 
		player_huds[name] = player:hud_add({
			hud_elem_type="text", 
			position={x=0.02, y=0.95}, 
			alignment={x=1,y=-1}, 
			number=0xFFFFFF, 
			text=txt
		}) 
	end
end

function myprogress.add_xp(player, skill, amount)
	local name = player:get_player_name()
	local s = myprogress.players[name]
	s[skill] = s[skill] + amount
	local l_key = skill:sub(1,1).."level"
	local new_l = math.floor((s[skill] / xp_scaling[skill]) ^ (1/1.5))
	if new_l > s[l_key] then
		s[l_key] = new_l
		core.chat_send_player(name, "★ LEVEL UP: "..skill:upper().." IS NOW "..new_l.." ★")
	local rewards = {
    mining = "myprogress:master_smelter",
    lumbering = "myprogress:master_sawmill",
    digging = "myprogress:master_sifter",
    building = "myprogress:master_architect_table",
    farming = "myprogress:master_harvester"
}

	if new_l == 20 and rewards[skill] then
    	local inv = player:get_inventory()
    	inv:add_item("main", rewards[skill])
    	core.chat_send_player(name, "MASTERY REACHED! You have been awarded: " .. rewards[skill])
	end
	end
	myprogress.update_hud(player)
end

core.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	if not myprogress.players[name] then
		myprogress.players[name] = {mining=0,mlevel=0,lumbering=0,llevel=0,digging=0,dlevel=0,farming=0,flevel=0,building=0,blevel=0}
	end
	core.after(0.5, function() myprogress.update_hud(player) end)
end)

myprogress_nodes.mining = {"default:stone", "default:stone_with_coal", "default:stone_with_iron", "default:stone_with_copper", "default:stone_with_gold", "default:stone_with_mese", "default:stone_with_diamond", "default:obsidian"}
myprogress_nodes.lumber = {"default:tree", "default:pine_tree", "default:acacia_tree", "default:jungletree"}
myprogress_nodes.digging = {"default:dirt", "default:dirt_with_grass", "default:sand", "default:desert_sand", "default:gravel", "default:clay"}
myprogress_nodes.farming = {"farming:wheat_8", "farming:cotton_8", "farming:corn_8", "farming:coffee_5"}

core.register_on_dignode(function(pos, oldnode, digger)
	if not digger or not digger:is_player() then return end
	local node_name = oldnode.name
	
	local function check(list, skill)
		for _, n in pairs(list) do
			if node_name == n then
				myprogress.add_xp(digger, skill, 1)
				if myprogress.apply_rewards then
					myprogress.apply_rewards(pos, oldnode, digger, skill)
				end
				return true
			end
		end
		return false
	end

	if check(myprogress_nodes.mining, "mining") then return end
	if check(myprogress_nodes.lumber, "lumbering") then return end
	if check(myprogress_nodes.digging, "digging") then return end
	if check(myprogress_nodes.farming, "farming") then return end
end)

dofile(path .. "/nodes.lua")
myprogress.load_data()

local timer = 0
core.register_globalstep(function(dtime)
	timer = timer + dtime
	if timer > 10 then myprogress.save_data() timer = 0 end
end)
core.register_chatcommand("skills", {
    description = "Check your skill levels and progress",
    func = function(name)
        local stats = myprogress.players[name]
        if not stats then return false, "No data found." end

        local formspec = "size[8,7]background[-0.5,-0.5;9,8;myprogress_bg.png]" ..
            "label[3.2,0.5;--- SKILL MASTERY ---]" ..
            
            "image[1,1.2;1,1;default_tool_pittock.png]" ..
            "label[2,1.2;Mining Lvl " .. stats.mlevel .. "]" ..
            "label[2,1.6;XP: " .. stats.mining .. "]" ..
            
            "image[1,2.2;1,1;default_tool_steelaxe.png]" ..
            "label[2,2.2;Lumber Lvl " .. stats.llevel .. "]" ..
            "label[2,2.6;XP: " .. stats.lumbering .. "]" ..
            
            "image[1,3.2;1,1;default_tool_steelshovel.png]" ..
            "label[2,3.2;Digging Lvl " .. stats.dlevel .. "]" ..
            "label[2,3.6;XP: " .. stats.digging .. "]" ..
            
            "image[1,4.2;1,1;default_brick.png]" ..
            "label[2,4.2;Building Lvl " .. stats.blevel .. "]" ..
            "label[2,4.6;XP: " .. stats.building .. "]" ..
            
            "button_exit[3,6;2,1;close;Close Menu]"

        core.show_formspec(name, "myprogress:skills_menu", formspec)
        return true
    end,
})
quests = {}
quests.players = {}
quests.settings = { miner = 10, digger = 10, logger = 10, farmer = 10, builder = 10 }

dofile(path .. "/leaderboard.lua")
dofile(path .. "/hud.lua")

local awards = {"Miner", "Logger", "Digger", "Builder", "Farmer"}
local award_levels = {
	{"Wood", "brown:150"},
	{"Stone", "gray:150"},
	{"Bronze", "red:100"},
	{"Silver", "white:75"},
	{"Gold", "yellow:120"},
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
			tiles = {"default_silver_sand.png^[colorize:"..c}, 
			paramtype = "light",
			paramtype2 = "facedir",
			groups = {cracky = 3}
		})
	end
end

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    if not quests.players[name] then
        quests.players[name] = {
            awards = {
                miner=0, miner_level=0, digger=0, digger_level=0,
                logger=0, logger_level=0, builder=0, builder_level=0,
                farmer=0, farmer_level=0
            }
        }
    end
end)

function award_for_digging(nname, playername)
	local ptable = quests.players[playername]
	if not ptable or not ptable.awards then return end
	
	local atable = ptable.awards
	local player = core.get_player_by_name(playername)
	if not player then return end
	local inv = player:get_inventory()

	local function check_level(val, set_val, skill_name, machine_name)
		local levels = {1, 5, 15, 50, 100}
		local tier_names = {"wood", "stone", "bronze", "silver", "gold"}
		
		for i, mult in ipairs(levels) do
			if val == set_val * mult then
				local tier = tier_names[i]
				core.chat_send_player(playername, "Level "..i.." "..skill_name:upper().."!")
				
				inv:add_item("main", "myprogress:award_"..skill_name.."_"..tier)

local pos = player:get_pos()
pos.y = pos.y + 1.5

core.sound_play("default_cool_item", {
    pos = pos,
    gain = 1.0,
    max_hear_distance = 10,
})

core.add_particlespawner({
    amount = 40,
    time = 0.1,
    minpos = {x=pos.x-0.2, y=pos.y, z=pos.z-0.2},
    maxpos = {x=pos.x+0.2, y=pos.y+0.5, z=pos.z+0.2},
    minvel = {x=-3, y=1, z=-3},
    maxvel = {x=3, y=5, z=3},
    minacc = {x=0, y=-9.8, z=0},
    maxacc = {x=0, y=-9.8, z=0},
    minexptime = 1,
    maxexptime = 2,
    minsize = 1,
    maxsize = 3,
    texture = "default_item_smoke.png^[colorize:yellow:200",
})
				if i == 5 and machine_name then
					inv:add_item("main", machine_name)
					core.chat_send_player(playername, "MASTERY: You've earned a machine!")
				end
				return i
			end
		end
		return nil
	end

	if string.find(nname, "stone") then
		atable.miner = atable.miner + 1
		local lvl = check_level(atable.miner, quests.settings.miner, "miner", "myprogress:master_smelter")
		if lvl then atable.miner_level = lvl end
	
	elseif string.find(nname, "sand") or string.find(nname, "dirt") then
		atable.digger = atable.digger + 1
		local lvl = check_level(atable.digger, quests.settings.digger, "digger", "myprogress:master_sifter")
		if lvl then atable.digger_level = lvl end

	elseif string.find(nname, "tree") then
		atable.logger = atable.logger + 1
		local lvl = check_level(atable.logger, quests.settings.logger, "logger", "myprogress:master_sawmill")
		if lvl then atable.logger_level = lvl end

	elseif string.find(nname, "farming:wheat") then
		atable.farmer = atable.farmer + 1
		local lvl = check_level(atable.farmer, quests.settings.farmer, "farmer", "myprogress:master_harvester")
		if lvl then atable.farmer_level = lvl end
	end
end

function award_for_placing(nname, playername)
	if not quests.players[playername] then return end
	local atable = quests.players[playername].awards
	local player = core.get_player_by_name(playername)
	local inv = player:get_inventory()

	atable.builder = atable.builder + 1
	
	local levels = {1, 5, 15, 50, 100}
	local tiers = {"wood", "stone", "bronze", "silver", "gold"}
	local set = quests.settings.builder

	for i, mult in ipairs(levels) do
		if atable.builder == set * mult then
			atable.builder_level = i
			core.chat_send_player(playername, "Builder Level "..i.."!")

local pos = player:get_pos()
pos.y = pos.y + 1.5

core.sound_play("default_cool_item", {
    pos = pos,
    gain = 1.0,
    max_hear_distance = 10,
})

core.add_particlespawner({
    amount = 40,
    time = 0.1,
    minpos = {x=pos.x-0.2, y=pos.y, z=pos.z-0.2},
    maxpos = {x=pos.x+0.2, y=pos.y+0.5, z=pos.z+0.2},
    minvel = {x=-3, y=1, z=-3},
    maxvel = {x=3, y=5, z=3},
    minacc = {x=0, y=-9.8, z=0},
    maxacc = {x=0, y=-9.8, z=0},
    minexptime = 1,
    maxexptime = 2,
    minsize = 1,
    maxsize = 3,
    texture = "default_item_smoke.png^[colorize:yellow:200",
})
			inv:add_item("main", "myprogress:award_builder_"..tiers[i])
			if i == 5 then inv:add_item("main", "myprogress:master_architect_table") end
		end
	end
end

core.register_on_dignode(function(pos, oldnode, digger)
	if digger and digger:is_player() then
		award_for_digging(oldnode.name, digger:get_player_name())
	end
end)

core.register_on_placenode(function(pos, newnode, placer)
	if placer and placer:is_player() then
		award_for_placing(newnode.name, placer:get_player_name())
	end
end)
local world_path = core.get_worldpath()
local file_path = world_path .. "/quests_data.txt"

function quests.save_data()
    local file = io.open(file_path, "w")
    if file then
        file:write(core.serialize(quests.players))
        file:close()
    else
        core.log("error", "[Quests] Failed to save player data!")
    end
end

function quests.load_data()
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = core.deserialize(content)
        if type(data) == "table" then
            quests.players = data
            core.log("action", "[Quests] Data loaded successfully.")
        end
    end
end
core.register_on_leaveplayer(function(player)
    quests.save_data()
end)

local timer = 0
core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 300 then
        quests.save_data()
        timer = 0
        core.log("action", "[Quests] Global autosave complete.")
    end
end)

core.register_on_shutdown(function()
    quests.save_data()
end)
quests.load_data()
core.register_chatcommand("setlevel", {
	params = "<skill> <amount>",
	description = "Set your own skill count safely",
	privs = {server = true},
	func = function(name, param)
		local skill, amount = param:match("^(%S+)%s+(%d+)$")
		
		if not skill or not amount then 
			return false, "Usage: /setlevel <miner|digger|logger|builder|farmer> <number>" 
		end
		
		local amount_num = tonumber(amount)

		if not quests.players[name] then
			quests.players[name] = {}
		end
		if not quests.players[name].awards then
			quests.players[name].awards = {
				miner=0, miner_level=0, digger=0, digger_level=0,
				logger=0, logger_level=0, builder=0, builder_level=0,
				farmer=0, farmer_level=0
			}
		end

		local ptable = quests.players[name]
		local atable = ptable.awards

		if atable[skill] == nil then
			return false, "Error: Skill '"..skill.."' not found. Valid: miner, digger, logger, builder, farmer."
		end

		atable[skill] = amount_num
		
		local fake_nodes = {
			miner = "default:stone",
			digger = "default:dirt",
			logger = "default:tree",
			farmer = "farming:wheat_8",
			builder = "default:stone"
		}

		if skill == "builder" then
			award_for_placing(fake_nodes[skill], name)
		else
			award_for_digging(fake_nodes[skill], name)
		end

		return true, "Success! " .. skill .. " set to " .. amount_num
	end,
})
