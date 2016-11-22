net.Receive("GC_TRAITS", function(len, ply)
	if IsValid(GAMEMODE.traitDescBox) then
		GAMEMODE.traitDescBox:Remove()
		GAMEMODE.traitDescBox = nil
	end
	
	LocalPlayer().traits = net.ReadTable()
end)