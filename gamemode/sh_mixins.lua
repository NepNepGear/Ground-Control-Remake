AddCSLuaFile()

function table.clear(list)
	for key, value in pairs(list) do
		list[key] = nil
	end
	
	return list
end

function file.verifyDataFolder(path)
	if not file.IsDir(path, "DATA") then
		file.CreateDir(path)
	end
end

function table.Exclude(tbl, obj)
	for key, value in pairs(tbl) do
		if value == obj then
			table.remove(tbl, key)
		end
	end
	
	return tbl
end

function team.GetLivingPlayers(teamID)
	local total = 0
	
	for key, ply in ipairs(team.GetPlayers(teamID)) do
		if ply:Alive() then
			total = total + 1
		end
	end
	
	return total
end

if CLIENT then
	draw.VERTICAL = 1
	draw.HORIZONTAL = 2
	
	-- taken from somewhere, can't recall, whoever wrote this - please don't get mad at me!
	function draw.LinearGradient(x,y,w,h,from,to,dir)
		dir = dir or draw.HORIZONTAL
		local res = nil
		
		if dir == draw.HORIZONTAL then 
			res = w
		elseif dir == draw.VERTICAL then 
			res = h
		end
		
		for i=1,res do
			surface.SetDrawColor(
				Lerp(i/res,from.r,to.r),
				Lerp(i/res,from.g,to.g),
				Lerp(i/res,from.b,to.b),
				Lerp(i/res,from.a,to.a)
			)
			
			if dir == draw.HORIZONTAL then 
				surface.DrawRect(x + i, y, 1, h )
			elseif dir == draw.VERTICAL then 
				surface.DrawRect(x, y + i, w, 1 )
			end
		end
	end
end

function string.easyformatbykeys(target, ...)
	local cur = 1
	
	while true do
		local element = select(cur, ...)
		local replacement = select(cur + 1, ...)

		if not element or not replacement then
			break
		end
		
		target = string.gsub(target, element, replacement)
		cur = cur + 2
	end
	
	return target
end

function math.flash(value, flashSpeed)
	value = value * flashSpeed
	local flash = math.ceil(value) - value
	local dist = math.abs(0.5 - flash) * 2
	
	return dist
end

function math.signedmin(value, otherValue)
	local sign = value / math.abs(value)
	
	return math.max(math.min(value, otherValue), otherValue * sign)
end