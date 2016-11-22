net.Receive("GC_VOTE", function(a, b)
	local title = net.ReadString()
	local voteStartTime = net.ReadFloat()
	local voteTime = net.ReadFloat()
	local data = net.ReadTable()
	GAMEMODE:setVotes(title, voteStartTime, voteTime, data)
end)

local function GC_Vote_Update(data)
	local index = data:ReadChar()
	local value = data:ReadChar()
	
	GAMEMODE:updateVote(index, value)
end

usermessage.Hook("GC_VOTE_UPDATE", GC_Vote_Update)

function GM:updateVote(index, value)
	self.VoteOptions[index].votes = value
end

GM.VoteFont = "CW_HUD16"
GM.VoteOptionSpacing = 20
GM.VoteStartTime = 0
GM.VoteDuration = 0
GM.VoteTitle = nil
GM.VoteTextWidth = nil -- the widest vote text
GM.BaseVotePanelWidth = 250

function GM:setVotes(title, startTime, voteDuration, data)
	self.VoteStartTime = startTime + self.VotePrepTime
	self.VoteDuration = startTime + voteDuration
	self.VoteTitle = title
	self.VoteOptions = data
	self.VoteTextWidth = math.max(self:getWidestVoteText() + 10, self.BaseVotePanelWidth)
	
	self:hideWeaponSelection()
	self:hideRadio()
end

function GM:drawVotePanel()
	local curTime = CurTime()

	if curTime > self.VoteStartTime then
		if curTime < self.VoteDuration then
			local totalOptions = #self.VoteOptions
			local halfOptions = totalOptions * 0.5 * self.VoteOptionSpacing
			local halfSpace = self.VoteOptionSpacing * 0.5
			local scrH = ScrH()
			local midY = scrH * 0.5
			local curY = midY - halfOptions + 10 - 20
			
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(50, midY - halfOptions - 20, self.VoteTextWidth, totalOptions * self.VoteOptionSpacing + 20)
			
			self.HUDColors.white.a, self.HUDColors.black.a = 255, 255
			
			draw.ShadowText(self:getVoteTitle(), self.VoteFont, 55, curY, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			curY = curY + self.VoteOptionSpacing
			
			for key, data in ipairs(self.VoteOptions) do
				draw.ShadowText(self:getVoteText(key, data), self.VoteFont, 55, curY, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				curY = curY + self.VoteOptionSpacing
			end
			
			return true
		end
	else
		local midY = ScrH() * 0.5
		
		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawRect(50, midY - 12, 250, 24)
		
		self.HUDColors.white.a, self.HUDColors.black.a = 255, 255
		
		draw.ShadowText("A vote will begin soon.", "CW_HUD24", 55, midY, self.HUDColors.white, self.HUDColors.black, 1, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	
	return false
end

function GM:getVoteTitle()
	return self.VoteTitle .. " - " .. math.ceil(self.VoteDuration - CurTime()) .. " second(s) left"
end

function GM:getVoteText(key, data)
	return key .. ". " .. data.option .. " - " .. data.votes .. " votes"
end

function GM:getTextSize(font, text)
	surface.SetFont(font)
	return surface.GetTextSize(text)
end

function GM:getWidestVoteText()
	local titleW = self:getTextSize(self.VoteFont, self:getVoteTitle())
	local optionW = -math.huge
	
	for key, data in ipairs(self.VoteOptions) do
		local w = self:getTextSize(self.VoteFont, self:getVoteText(key, data))
		
		if w > optionW then
			optionW = w
		end
	end
	
	return math.max(titleW, optionW)
end

function GM:isVoteActive()
	return CurTime() < self.VoteDuration
end

function GM:canVote()
	local curTime = CurTime()
	return curTime > self.VoteStartTime and curTime < self.VoteDuration
end

function GM:attemptVote(selection)
	if self:canVote() and self.VoteOptions[selection] then
		RunConsoleCommand("gc_vote", selection)
		return true
	end
	
	return false
end