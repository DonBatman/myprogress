core.register_chatcommand("skills", {
    description = "Check your skill levels and progress",
    func = function(name)
        local stats = myprogress.players[name]
        if not stats then return false, "No data found." end

        local formspec = "size[8,7]background[-0.5,-0.5;9,8;myprogress_bg.png]" ..
            "label[3.2,0.5;--- SKILL MASTERY ---]" ..
            
            "image[1,1.2;1,1;default_tool_steelpick.png]" ..
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

		if not myquests.players[name] then
			myquests.players[name] = {}
		end
		if not myquests.players[name].awards then
			myquests.players[name].awards = {
				miner=0, miner_level=0, digger=0, digger_level=0,
				logger=0, logger_level=0, builder=0, builder_level=0,
				farmer=0, farmer_level=0
			}
		end

		local ptable = myquests.players[name]
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

