myprogress = {}
myprogress.players = {}
myprogress_nodes = {}
myprogress.player_huds = {} 

myquests = {}
myquests.players = {}
myquests.settings = { miner = 10, digger = 10, logger = 10, farmer = 10, builder = 10, slayer = 10 }

myprogress.xp_scaling = {
    mining = 50,
    lumbering = 40,
    digging = 30,
    farming = 25,
    building = 100,
    combat = 60
}

local path = core.get_modpath("myprogress")
local last_puncher = {}

dofile(path .. "/data.lua")
dofile(path .. "/nodes.lua")
dofile(path .. "/functions.lua")
dofile(path .. "/awards.lua")
dofile(path .. "/hud.lua")
dofile(path .. "/leaderboard.lua")
dofile(path .. "/chat_commands.lua")

myquests.settings = { 
    miner = 10, digger = 10, logger = 10, 
    farmer = 10, builder = 10, slayer = 10,
    difficulty = "hard"}

core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if not myprogress.players[name] then
        myprogress.players[name] = {}
    end

    local p = myprogress.players[name]
    p.mining = p.mining or 0; p.mlevel = p.mlevel or 0
    p.digging = p.digging or 0; p.dlevel = p.dlevel or 0
    p.lumbering = p.lumbering or 0; p.llevel = p.llevel or 0
    p.farming = p.farming or 0; p.flevel = p.flevel or 0
    p.building = p.building or 0; p.blevel = p.blevel or 0
    p.combat = p.combat or 0; p.clevel = p.clevel or 0
    p.total_xp = p.total_xp or 0

    myprogress.update_hud(player)
end)

local scan_timer = 0
core.register_globalstep(function(dtime)
    scan_timer = scan_timer + dtime
    if scan_timer < 0.5 then return end
    scan_timer = 0

    for obj, data in pairs(last_puncher) do
        local is_dead = false
        if not obj:is_valid() then is_dead = true
        elseif obj:get_hp() <= 0 then is_dead = true end

        if is_dead then
            local player = core.get_player_by_name(data.name)
            if player then
                local xp_amount = 5
                local m_name = data.mob_name or ""
                if m_name:find("chicken") then xp_amount = 2
                elseif m_name:find("rat") then xp_amount = 10
                elseif m_name:find("monster") then xp_amount = 15 end
                
                myprogress.add_xp(player, "combat", xp_amount)
                award_for_combat(data.name)
            end
            last_puncher[obj] = nil
        end
    end
end)

core.register_on_mods_loaded(function()
    for name, entity in pairs(core.registered_entities) do
        if name:find("mobs") then
            local old_punch = entity.on_punch
            entity.on_punch = function(self, hitter, ...)
                if hitter and hitter:is_player() then
                    last_puncher[self.object] = {
                        name = hitter:get_player_name(),
                        mob_name = name,
                        time = core.get_gametime()
                    }
                end
                if old_punch then return old_punch(self, hitter, ...) end
            end
        end
    end
end)

myprogress_nodes.mining = {"default:stone", 
							"default:stone_with_coal", 
							"default:stone_with_iron", 
							"default:stone_with_copper", 
							"default:stone_with_tin",
							"default:stone_with_gold", 
							"default:stone_with_mese", 
							"default:stone_with_diamond", 
							"default:obsidian"}


if core.get_modpath("myores") then
    local extra_ores = {"myores:basalt",
    					"myores:stone_with_gneiss",
    					"myores:granite",
    					"myores:marble",
    					"myores:stone_with_redsandstone",
    					"myores:schist",
    					"myores:shale",
    					"myores:stone_with_slate",
    					"myores:chalk",
    					"myores:stone_with_calcium",
    					"myores:stone_with_sodium",
    					"myores:stone_with_silver",
    					"myores:stone_with_redsandstone",
    					"myores:stone_with_chromium",
    					"myores:stone_with_manganese",
    					"myores:stone_with_quartz",
    					"myores:stone_with_chalcopyrite",
    					"myores:stone_with_cobalt",
    					"myores:stone_with_uvarovite",
    					"myores:stone_with_selenite",
    					"myores:stone_with_miserite",
    					"myores:stone_with_limonite",
    					"myores:stone_with_sulfur",
    					"myores:stone_with_lapis_lazuli",
    					"myores:stone_with_emerald",
    					"myores:stone_with_amethyst",
    					"myores:nether",
    					"myores:glowstone_blue",
    					"myores:glowstone_orange",
    					"myores:glowstone_green",
    					"myores:mithril",
    					"myores:nyancat",
    					"myores:nyancat_rainbow",
    					"myores:cronk",
    					"myores:bloodstone",
    					"myores:mithril",
    					"myores:nyancat",
    					"myores:nyancat_rainbow",
    					"myores:cronk",
    	}

	for _, ore in ipairs(extra_ores) do
        table.insert(myprogress_nodes.mining, ore)
    end
end

myprogress_nodes.lumber = {"default:tree", 
							"default:pine_tree", 
							"default:acacia_tree", 
							"default:jungletree", 
							"default:aspen_tree"}

if core.get_modpath("moretrees") then
    local extra_lumber = {"moretrees:beech_trunk",
    						"moretrees:apple_tree_trunk",
    						"moretrees:oak_trunk",
    						"moretrees:birch_trunk",
    						"moretrees:palm_trunk",
    						"moretrees:date_palm_trunk",
    						"moretrees:spruce_trunk",
    						"moretrees:cedar_trunk",
    						"moretrees:poplar_trunk",
    						"moretrees:poplar_small_trunk",
    						"moretrees:willow_trunk",
    						"moretrees:rubber_tree_trunk",
    						"moretrees:fir_trunk",
    						"moretrees:jungletree_trunk"}

	for _, logs in ipairs(extra_lumber) do
		table.insert(myprogress_nodes.lumber, logs)
	end
end

if core.get_modpath("ethereal") then
    local extra_lumber2 = {"ethereal:sakura_trunk",
    						"ethereal:mangrove_tree",
    						"ethereal:willow_trunk",
    						"ethereal:redwood_trunk",
    						"ethereal:frost_tree",
    						"ethereal:yellow_trunk",
    						"ethereal:palm_trunk",
    						"ethereal:banana_trunk",
    						"ethereal:scorched_tree",
    						"ethereal:mushroom_trunk",
    						"ethereal:birch_trunk",
    						"ethereal:bamboo",
    						"ethereal:olive_trunk",
    						}

	for _, logs2 in ipairs(extra_lumber2) do
		table.insert(myprogress_nodes.lumber, logs2)
	end
end

myprogress_nodes.digging = {"default:dirt", 
							"default:dirt_with_grass", 
							"default:dirt_with_grass_footsteps", 
							"default:dirt_with_dry_grass", 
							"default:dirt_with_snow", 
							"default:dirt_with_rainforest_litter", 
							"default:dirt_with_coniferous_litter", 
							"default:dry_dirt", 
							"default:dry_dirt_with_dry_grass", 
							"default:sand", 
							"default:desert_sand", 
							"default:gravel", 
							"default:clay"}

if core.get_modpath("ethereal") then
    local extra_dirt = {"ethereal:green_dirt",
    					"ethereal:dry_dirt",
    					"ethereal:bamboo_dirt",
    					"ethereal:jungle_dirt",
    					"ethereal:grove_dirt",
    					"ethereal:prairie_dirt",
    					"ethereal:cold_dirt",
    					"ethereal:crystal_dirt",
    					"ethereal:mushroom_dirt",
    					"ethereal:fiery_dirt",
    					"ethereal:gray_dirt",
    					"ethereal:mud",
    					}

    for _, soil in ipairs(extra_dirt) do
        table.insert(myprogress_nodes.digging, soil)
    end
end

myprogress_nodes.farming = {"farming:wheat_8", 
							"farming:cotton_8"}

if core.get_modpath("farming") then
    local extra_crops = {
        "farming:artichoke_5", 
        "farming:asparagus_5", 
        "farming:barley_8", 
        "farming:beanpole_5",
        "farming:beetroot_5", 
        "farming:blackberry_4", 
        "farming:blueberry_4", 
        "farming:cabbage_6",
        "farming:carrot_8", 
        "farming:chilli_8", 
        "farming:cocoa_4", 
        "farming:coffee_5",
        "farming:corn_8", 
        "farming:cucumber_4", 
        "farming:eggplant_4", 
        "farming:garlic_5",
        "farming:ginger_4", 
        "farming:grapes_8", 
        "farming:hemp_8", 
        "farming:lettuce_5",
        "farming:melon_8", 
        "farming:mint_4", 
        "farming:onion_5", 
        "farming:parsley_3",
        "farming:pea_4", 
        "farming:pepper_7", 
        "farming:pineapple_8", 
        "farming:potato_4",
        "farming:pumpkin_8",
        "farming:raspberry_4", 
        "farming:rhubarb_4", 
        "farming:rice_8", 
        "farming:rye_5",
        "farming:oat_5", 
        "farming:soy_7", 
        "farming:spinach_4", 
        "farming:strawberry_8",
        "farming:sunflower_8", 
        "farming:tomato_8", 
        "farming:vanilla_8", 
        "farming:wheat_8",
    }
    
    for _, crop in ipairs(extra_crops) do
        table.insert(myprogress_nodes.farming, crop)
    end
end

core.register_on_dignode(function(pos, oldnode, digger)
    if not digger or not digger:is_player() then return end
    local player_name = digger:get_player_name()
    local node_name = oldnode.name
    
    local function check_xp(list, skill)
        for _, n in pairs(list) do
            if node_name == n then
                myprogress.add_xp(digger, skill, 1)
                return true
            end
        end
        return false
    end

    check_xp(myprogress_nodes.mining, "mining")
    check_xp(myprogress_nodes.lumber, "lumbering")
    check_xp(myprogress_nodes.digging, "digging")
    check_xp(myprogress_nodes.farming, "farming")

    award_for_digging(node_name, player_name)
    
    for _, n in pairs(myprogress_nodes.lumber) do
        if node_name == n then award_for_lumbering(player_name) break end
    end
    
    for _, n in pairs(myprogress_nodes.farming) do
        if node_name == n then award_for_farming(player_name) break end
    end
end)

core.register_on_placenode(function(pos, newnode, placer)
    if placer and placer:is_player() then
        myprogress.add_xp(placer, "building", 1)
        award_for_placing(newnode.name, placer:get_player_name())
    end
end)

local q_file = core.get_worldpath() .. "/myquests_data.txt"

function myquests.save_data()
    local f = io.open(q_file, "w")
    if f then f:write(core.serialize(myquests.players)) f:close() end
end

function myquests.load_data()
    local f = io.open(q_file, "r")
    if f then
        local content = f:read("*all")
        f:close()
        local data = core.deserialize(content)
        if type(data) == "table" then myquests.players = data end
    end
end

myprogress.load_data()
myquests.load_data()

core.register_on_dieplayer(function(player)
    local name = player:get_player_name()
    local p = myprogress.players[name]
    
    if not p then return end

    local penalty = 0.10
    
    local skills = {"mining", "digging", "lumbering", "farming", "building", "combat"}
    
    for _, skill in ipairs(skills) do
        if p[skill] and p[skill] > 0 then
            local lost_amount = math.floor(p[skill] * penalty)
            p[skill] = p[skill] - lost_amount
        end
    end

    if p.total_xp and p.total_xp > 0 then
        p.total_xp = math.floor(p.total_xp * (1 - penalty))
    end

    myprogress.save_data()
    myprogress.update_hud(player)
    
    core.chat_send_player(name, core.colorize("#FF5555", 
        "You died! You lost 10% of your experience in all skills."))
end)

core.register_on_leaveplayer(function(player)
    myprogress.save_data(); myquests.save_data()
end)

core.register_on_shutdown(function()
    myprogress.save_data(); myquests.save_data()
end)
