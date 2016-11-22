function GM:GetMotionBlurValues(horizontal, vertical, forward, rotational)
	if self.DeadState == 3 then
		return horizontal, vertical, forward, rotational
	end
	
	return horizontal, vertical, self.AdrenalineData.currentVal * 0.02, rotational
end