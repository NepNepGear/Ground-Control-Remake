AddCSLuaFile("cl_voting.lua")

GM.VoteOptions = {}
GM.VotedPlayers = {}
GM.PossibleVoteOptions = {}
GM.VoteCallback = nil
GM.VoteActive = false
GM.VoteStartTime = nil
GM.VoteTitle = nil
GM.VoteTeamTargets = nil -- team ID that we may send the vote results to
GM.VoteQueue = {}

util.AddNetworkString("GC_VOTE")

function GM:pickVoteOptions(allOptions, maxPicks, randomize)
	if randomize then
		maxPicks = maxPicks or 9
		
		for key, option in ipairs(allOptions) do -- clone the table
			self.PossibleVoteOptions[key] = option
		end
		
		local curOptions = self.PossibleVoteOptions
		
		for i = 1, math.Clamp(#curOptions, 1, maxPicks) do -- iterate over the table
			local curChoice = math.random(1, #curOptions) -- get a choice, add it to the vote option table, remove it from the cloned table
			self.VoteOptions[#self.VoteOptions + 1] = {votes = 0, option = curOptions[curChoice]}
			table.remove(curOptions, curChoice)
		end
	else
		for key, optionName in ipairs(allOptions) do
			self.VoteOptions[#self.VoteOptions + 1] = {votes = 0, option = optionName}
		end
	end
end

function GM:canStartVote()
	return not self.VoteActive
end

function GM:popVoteQueue()
	if #self.VoteQueue > 0 then
		local data = self.VoteQueue[1]
		table.remove(self.VoteQueue, 1)
		self:setupCurrentVote(data.title, data.options, data.targets, data.picks, data.randomize, data.teamTargets, data.finishCallback)
	end
end

-- title - the title of the current vote to display
-- options - the options of the current vote
-- finishCallback - the function to call when the vote time runs out (or everyone has voted)
function GM:setupCurrentVote(title, options, targets, picks, randomize, teamTargets, finishCallback)
	if self.VoteActive then
		table.insert(self.VoteQueue, {title = title, options = options, targets = targets, picks = picks, randomize = randomize, teamTargets = teamTargets, finishCallback = finishCallback}) -- queue a vote in case we have one currently
		return false
	end
	
	picks = picks or 9
	self:resetVoteData()
	self:pickVoteOptions(options, picks, randomize)
	
	self.VoteTitle = title
	self.VoteCallback = finishCallback
	self.VoteStartTime = CurTime()
	self.VoteTeamTargets = teamTargets
	self.VoteActive = true
	
	timer.Simple(self.VoteTime, function()
		self:finishCurrentVote()
	end)
	
	self:sendVoteToTargets(targets)
	return true
end

function GM:pickSendTargets(targets)
	if not targets then
		if self.VoteTeamTargets then
			targets = team.GetPlayers(self.VoteTeamTargets)
		else
			targets = player.GetAll()
		end
	end
	
	return targets
end

function GM:sendVoteToTargets(targets)
	targets = self:pickSendTargets(targets)
	self.CurrentVoteTargets = targets
	
	for key, target in ipairs(targets) do
		if IsValid(target) then -- the target might be invalid in case we had a vote queued and some players left during that time
			self:sendVoteData(target)
		end
	end
end

function GM:sendVoteUpdate(target, index)
	self:sendVoteDataUpdate(target)
end

function GM:checkVoteStatus(ply)
	if self.VoteActive then
		self:sendVoteData(ply)
	end
end

function GM:sendVoteData(target)
	net.Start("GC_VOTE")
		net.WriteString(self.VoteTitle)
		net.WriteFloat(self.VoteStartTime)
		net.WriteFloat(self.VoteTime)
		net.WriteTable(self.VoteOptions)
	net.Send(target) -- send to each individually instead of player.GetAll(), etc. in case I want to expand on this system later on
end

function GM:sendVoteDataUpdateToTargets(targets, index)
	targets = self:pickSendTargets(targets)
	
	for key, target in ipairs(targets) do
		if IsValid(target) then
			self:sendVoteDataUpdate(target, index)
		end
	end
end

function GM:sendVoteDataUpdate(target, index)
	local votes = self.VoteOptions[index].votes
	
	umsg.Start("GC_VOTE_UPDATE", target)
		umsg.Char(index)
		umsg.Char(votes)
	umsg.End()
end

function GM:finishCurrentVote()
	self.VoteCallback()
	self:resetVoteData() 
	self:popVoteQueue()
end

function GM:resetVoteData()
	table.clear(self.VoteOptions)
	table.clear(self.VotedPlayers)
	table.clear(self.PossibleVoteOptions)
	self.VoteActive = false
	self.VoteStartTime = nil
	self.VoteTitle = nil
	self.VoteTeamTargets = nil
	self.CurrentVoteTargets = nil
end

function GM:getHighestVote()
	local cur = 0
	local totalVotes = 0
	local highestData = nil
	
	for key, data in ipairs(self.VoteOptions) do
		if data.votes > cur then
			highestData = data
			cur = data.votes
		end
		
		totalVotes = totalVotes + data.votes
	end
	
	if not highestData then -- if we didn't pick anything, pick a random option
		highestData, cur = table.Random(self.VoteOptions)
	end
	
	return highestData, cur, totalVotes
end

function GM:attemptVote(ply, voteOption)
	if not self.VoteOptions[voteOption] then
		return
	end
	
	if self.VotedPlayers[ply:SteamID64()] then
		return
	end
	
	self:assignVote(ply, voteOption)
end

function GM:assignVote(ply, voteOption)
	local voteData = self.VoteOptions[voteOption]
	voteData.votes = voteData.votes + 1
	self.VotedPlayers[ply:SteamID64()] = true
	self:sendVoteDataUpdateToTargets(self.CurrentVoteTargets, voteOption)
end

concommand.Add("gc_vote", function(ply, com, args)
	if not GAMEMODE.VoteActive then -- nigger, what are you doing
		return
	end
	
	local vote = args[1]
	
	if not vote then
		return
	end
	
	vote = tonumber(vote)
	GAMEMODE:attemptVote(ply, vote)
end)