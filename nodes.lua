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
            tiles = {"default_silver_sand.png^[colorize:"..c}, 
            paramtype = "light",
            paramtype2 = "facedir",
            groups = {cracky = 3},
            light_source = 3,
        })
    end
end

local function spawn_particles(pos, texture)
	core.add_particlespawner({
		amount = 10, time = 0.5,
		minpos = pos, maxpos = pos,
		minvel = {x=-1, y=1, z=-1}, maxvel = {x=1, y=2, z=1},
		texture = texture, 
	})
end

local awards = {"Miner", "Digger", "Logger", "Builder", "Farmer"}
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
			tiles = {"default_silver_sand.png^[colorize:"..c}, 
			paramtype = "light",
			paramtype2 = "facedir",
			groups = {cracky = 3}
		})
	end
end

core.register_node("myprogress:master_smelter", {
	description = "Master Miner's Smelter (Level 20 Required)",
	tiles = {"myprogress_miners_smelter.png"},
	drawtype = "mesh",
	mesh = "myprogress_miners_smelter.obj",
	paramtype2 = "facedir",
	groups = {cracky = 2},
	on_rightclick = function(pos, node, clicker)
		local name = clicker:get_player_name()
		if (myprogress.players[name].mlevel or 0) < 20 then
			core.chat_send_player(name, "Access Denied: Mining Level 20 required.")
			return
		end
		local fs = "size[8,9]label[3.2,0.5;Master Smelter]list[context;src;3.5,1.5;1,1;]list[context;dst;3,3;2,1;]list[current_player;main;0,5;8,4;]"
		core.show_formspec(name, "myprogress:smelter_"..core.pos_to_string(pos), fs)
	end,
	on_construct = function(pos)
		local inv = core.get_meta(pos):get_inventory()
		inv:set_size("src", 1) inv:set_size("dst", 2)
	end,
})

core.register_node("myprogress:master_sawmill", {
	description = "Master Lumberer's Sawmill (Level 20 Required)",
	tiles = {"myprogress_loggers_mill.png"},
	drawtype = "mesh",
	mesh = "myprogress_loggers_mill.obj",
	groups = {choppy = 2},
	on_rightclick = function(pos, node, clicker)
		local name = clicker:get_player_name()
		if (myprogress.players[name].llevel or 0) < 20 then
			core.chat_send_player(name, "Access Denied: Lumbering Level 20 required.")
			return
		end
		local fs = "size[8,9]label[3.2,0.5;Master Sawmill]list[context;src;3.5,1.5;1,1;]list[context;dst;3,3;2,1;]list[current_player;main;0,5;8,4;]"
		core.show_formspec(name, "myprogress:sawmill_"..core.pos_to_string(pos), fs)
	end,
	on_construct = function(pos)
		local inv = core.get_meta(pos):get_inventory()
		inv:set_size("src", 1) inv:set_size("dst", 2)
	end,
})

core.register_node("myprogress:master_harvester", {
	description = "Master Farmer's Harvester (Level 20 Required)",
	tiles = {"default_steel_block.png^[colorize:#00FF00:100"},
	groups = {cracky = 2},
	on_rightclick = function(pos, node, clicker)
		local name = clicker:get_player_name()
		if (myprogress.players[name].flevel or 0) < 20 then
			core.chat_send_player(name, "Access Denied: Farming Level 20 required.")
			return
		end
		local fs = "size[8,9]label[3.2,0.5;Harvester]list[context;src;3.5,1.5;1,1;]list[context;dst;3,3;2,1;]list[current_player;main;0,5;8,4;]"
		core.show_formspec(name, "myprogress:harvester_"..core.pos_to_string(pos), fs)
	end,
	on_construct = function(pos)
		local inv = core.get_meta(pos):get_inventory()
		inv:set_size("src", 1) inv:set_size("dst", 2)
	end,
})

core.register_node("myprogress:master_sifter", {
	description = "Master Digger's Sifter (Level 20 Required)",
	tiles = {"default_steel_block.png^[colorize:#FFD700:100"},
	groups = {cracky = 2},
	on_rightclick = function(pos, node, clicker)
		local name = clicker:get_player_name()
		if (myprogress.players[name].dlevel or 0) < 20 then
			core.chat_send_player(name, "Access Denied: Digging Level 20 required.")
			return
		end
		local fs = "size[8,9]label[3.2,0.5;Sifter]list[context;src;3.5,1.5;1,1;]list[context;dst;3,3;2,1;]list[current_player;main;0,5;8,4;]"
		core.show_formspec(name, "myprogress:sifter_"..core.pos_to_string(pos), fs)
	end,
	on_construct = function(pos)
		local inv = core.get_meta(pos):get_inventory()
		inv:set_size("src", 1) inv:set_size("dst", 2)
	end,
})

core.register_abm({
	nodenames = {"myprogress:master_harvester"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node)
		local inv = core.get_meta(pos):get_inventory()
		local stack = inv:get_stack("src", 1)
		if stack:is_empty() then return end

		local recipes = {
			["farming:wheat"]  = "farming:bread 3",
			["farming:cotton"] = "farming:string 6",
			["farming:corn"]   = "farming:corn_cob 3",
		}

		local out = recipes[stack:get_name()]
		if out and inv:room_for_item("dst", out) then
			stack:take_item(1)
			inv:set_stack("src", 1, stack)
			inv:add_item("dst", out)
			spawn_particles(pos, "farming_wheat_8.png")
		end
	end,
})

core.register_abm({
	nodenames = {"myprogress:master_sifter"},
	interval = 1.5,
	chance = 1,
	action = function(pos, node)
		local inv = core.get_meta(pos):get_inventory()
		local stack = inv:get_stack("src", 1)
		if stack:is_empty() then return end

		local input = stack:get_name()
		local output = nil
		local roll = math.random(1, 100)

		if input == "default:gravel" then
			if roll <= 5 then output = "default:diamond" 
			elseif roll <= 20 then output = "default:iron_lump" 
			else output = "default:flint" end
		elseif input == "default:sand" then
			if roll <= 15 then output = "default:tin_lump"
			else output = "default:clay_lump" end
		end

		if output and inv:room_for_item("dst", output) then
			stack:take_item(1)
			inv:set_stack("src", 1, stack)
			inv:add_item("dst", output)
		end
	end,
})

local trophies = {
    {name = "miner",     desc = "Mining"},
    {name = "digger",    desc = "Digging"},
    {name = "combat",    desc = "Slayer"},
    {name = "builder",   desc = "Builder"},
    {name = "logger", 	desc = "Logger"},
    {name = "farmer",   desc = "Farmer"}
}

local tiers = {
    {id = "bronze",  label = "Bronze",  color = "#CD7F32"},
    {id = "silver",  label = "Silver",  color = "#C0C0C0"},
    {id = "gold",    label = "Gold",    color = "#FFD700"},
    {id = "mese",    label = "Mese",    color = "#E2E200"},
    {id = "diamond", label = "Diamond", color = "#00FFFF"}
}

for _, t in ipairs(trophies) do
    local mesh_file = "myprogress_award_" .. t.name .. ".obj"
    
    for _, tier in ipairs(tiers) do
        local node_name = "myprogress:award_" .. t.name .. "_" .. tier.id
        
        core.register_node(node_name, {
            description = tier.label .. " " .. t.desc .. " Trophy",
            drawtype = "mesh",
            mesh = mesh_file, 
            
            tiles = {"default_stone.png^[colorize:" .. tier.color .. ":160"},
            
            paramtype = "light",
            paramtype2 = "facedir",
            groups = {choppy = 2, oddly_breakable_by_hand = 3},
            selection_box = {
                type = "fixed",
                fixed = {-0.3, -0.5, -0.3, 0.3, 0.8, 0.3}
            },
            light_source = (tier.id == "mese" or tier.id == "diamond") and 5 or 0,
            on_place = core.rotate_node
        })
    end
end
