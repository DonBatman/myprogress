local function spawn_particles(pos, texture)
	minetest.add_particlespawner({
		amount = 10, time = 0.5,
		minpos = pos, maxpos = pos,
		minvel = {x=-1, y=1, z=-1}, maxvel = {x=1, y=2, z=1},
		texture = texture, 
	})
end

minetest.register_node("myprogress:master_smelter", {
	description = "Master Miner's Smelter (Level 20 Required)",
	tiles = {"myprogress_miners_smelter.png"},
	drawtype = "mesh",
	mesh = "myprogress_miners_smelter.obj",
	paramtype2 = "facedir",
	groups = {cracky = 2},
	on_rightclick = function(pos, node, clicker)
		local name = clicker:get_player_name()
		if (myprogress.players[name].mlevel or 0) < 20 then
			minetest.chat_send_player(name, "⛔ Access Denied: Mining Level 20 required.")
			return
		end
		local fs = "size[8,9]label[3.2,0.5;Master Smelter]list[context;src;3.5,1.5;1,1;]list[context;dst;3,3;2,1;]list[current_player;main;0,5;8,4;]"
		minetest.show_formspec(name, "myprogress:smelter_"..minetest.pos_to_string(pos), fs)
	end,
	on_construct = function(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		inv:set_size("src", 1) inv:set_size("dst", 2)
	end,
})

-- MASTER SAWMILL (Lumbering 20)
minetest.register_node("myprogress:master_sawmill", {
	description = "Master Lumberer's Sawmill (Level 20 Required)",
	tiles = {"myprogress_loggers_mill.png"},
	drawtype = "mesh",
	mesh = "myprogress_loggers_mill.obj",
	groups = {choppy = 2},
	on_rightclick = function(pos, node, clicker)
		local name = clicker:get_player_name()
		if (myprogress.players[name].llevel or 0) < 20 then
			minetest.chat_send_player(name, "⛔ Access Denied: Lumbering Level 20 required.")
			return
		end
		local fs = "size[8,9]label[3.2,0.5;Master Sawmill]list[context;src;3.5,1.5;1,1;]list[context;dst;3,3;2,1;]list[current_player;main;0,5;8,4;]"
		minetest.show_formspec(name, "myprogress:sawmill_"..minetest.pos_to_string(pos), fs)
	end,
	on_construct = function(pos)
		local inv = minetest.get_meta(pos):get_inventory()
		inv:set_size("src", 1) inv:set_size("dst", 2)
	end,
})

-- THE HARVESTING ENGINE
minetest.register_abm({
	nodenames = {"myprogress:master_harvester"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node)
		local inv = minetest.get_meta(pos):get_inventory()
		local stack = inv:get_stack("src", 1)
		if stack:is_empty() then return end

		-- 1 Wheat = 3 Bread (Normally takes 3 wheat for 1 bread)
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
			
			-- Green growth particles
			minetest.add_particlespawner({
				amount = 8, time = 0.5,
				minpos = pos, maxpos = pos,
				minvel = {x=-1, y=1, z=-1}, maxvel = {x=1, y=2, z=1},
				texture = "farming_wheat_8.png", 
			})
		end
	end,
})

-- In nodes.lua, add the Sifter ABM if you haven't yet
minetest.register_abm({
	nodenames = {"myprogress:master_sifter"},
	interval = 1.5,
	chance = 1,
	action = function(pos, node)
		local inv = minetest.get_meta(pos):get_inventory()
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
--[[
local awards = {"Miner", "Logger", "Digger", "Builder", "Farmer"}
local award_levels = {
	{"Wood", "brown:150"},
	{"Stone", "gray:150"},
	{"Bronze", "red:100"},
	{"Silver", "white:75"},
	{"Gold", "yellow:120"},
}

-- This loop creates all 25 trophies automatically
for _, a in pairs(awards) do
	local al = string.lower(a)
	for _, level_data in ipairs(award_levels) do
		local b = level_data[1]
		local c = level_data[2]
		local bl = string.lower(b)

		minetest.register_node("myprogress:award_"..al.."_"..bl, {
			description = b.." "..a.." Trophy",
			drawtype = "mesh",
			mesh = "myprogress_award_"..al..".obj",
			tiles = {"myprogress_award.png^[colorize:"..c},
			paramtype = "light",
			paramtype2 = "facedir",
			groups = {cracky = 3},
			-- This defines the "Pedestal" shape
			node_box = {
				type = "fixed",
				fixed = {
					{-0.3, -0.5, -0.3, 0.3, -0.3, 0.3}, -- Base
					{-0.1, -0.3, -0.1, 0.1, 0.2, 0.1},  -- Stem
					{-0.2, 0.2, -0.2, 0.2, 0.4, 0.2},   -- Top platform
				}
			}
		})
	end
end
--]]
