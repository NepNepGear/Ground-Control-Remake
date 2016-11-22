net.Receive("GC_GADGETS", function(a, b)
	local ply = LocalPlayer()
	
	table.clear(ply.gadgets)
	
	for key, value in pairs(net.ReadTable()) do
		ply:addGadget(value)
	end
end)