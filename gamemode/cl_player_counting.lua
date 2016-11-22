-- player.GetAll returns a new table every time, so what this does is it will call player.GetAll once per second max

GM.ActivePlayerAmount = 0
GM.PreviousPlayerRetrieve = 0

function GM:getActivePlayerAmount()
	if CurTime() > self.PreviousPlayerRetrieve then
		self.PreviousPlayerRetrieve = CurTime() + 1
		self.ActivePlayerAmount = #player.GetAll()
	end
	
	return self.ActivePlayerAmount
end