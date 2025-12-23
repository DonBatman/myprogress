myprogress = {}
myprogress.players = {}
myprogress_nodes = {}
myprogress.player_huds = {}

myquests = {}
myquests.players = {}
myquests.settings = { miner = 10, digger = 10, logger = 10, farmer = 10, builder = 10 }
local path = core.get_modpath("myprogress")
dofile(path .. "/data.lua")
dofile(path .. "/functions.lua")
dofile(path .. "/leaderboard.lua")
dofile(path .. "/hud.lua")
dofile(path .. "/awards.lua")
dofile(path .. "/chat_commands.lua")

myprogress.xp_scaling = {mining = 15, lumbering = 20, digging = 10, farming = 5, building = 50}

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

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    if not myquests.players[name] then
        myquests.players[name] = {
            awards = {
                miner=0, miner_level=0, digger=0, digger_level=0,
                logger=0, logger_level=0, builder=0, builder_level=0,
                farmer=0, farmer_level=0
            }
        }
    end
end)



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
local file_path = world_path .. "/myquests_data.txt"

function myquests.save_data()
    local file = io.open(file_path, "w")
    if file then
        file:write(core.serialize(myquests.players))
        file:close()
    else
        core.log("error", "[Quests] Failed to save player data!")
    end
end

function myquests.load_data()
    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local data = core.deserialize(content)
        if type(data) == "table" then
            myquests.players = data
            core.log("action", "[Quests] Data loaded successfully.")
        end
    end
end
core.register_on_leaveplayer(function(player)
    myquests.save_data()
end)

local timer = 0
core.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer >= 300 then
        myquests.save_data()
        timer = 0
        core.log("action", "[Quests] Global autosave complete.")
    end
end)

core.register_on_shutdown(function()
    myquests.save_data()
end)
myquests.load_data()
