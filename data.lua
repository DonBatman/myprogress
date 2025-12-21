local worldpath = core.get_worldpath()

function myprogress.save_data()
	local f = io.open(worldpath.."/myprogress_data", "w")
	if f then
		f:write(core.serialize(myprogress.players))
		f:close()
	end
end

function myprogress.load_data()
	local f = io.open(worldpath.."/myprogress_data", "r")
	if f then
		local content = f:read("*a")
		f:close()
		local data = core.deserialize(content)
		if type(data) == "table" then
			for name, stats in pairs(data) do
				stats.hud_id = nil
			end
			myprogress.players = data
		end
	end
end
