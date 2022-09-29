
-- So you don't have to suicide for model updates. 
concommand.Add("unity_updatemodel", function( client, cmd, args, argStr )
		if IsValid(client) then
		client:SetModel( client:GetInfo("unity_playermodel") )
		client:SetPlayerColor( Vector(client:GetInfo("unity_playercolor")) )
		client:SetupHands()
	end
end)

concommand.Add("unity_bring", function( client, cmd, args )
	if !client:IsAdmin() then return end

	for _, target in ipairs(player.GetAll()) do
		if target:IsPlayer() and target:Alive() and target:GetName() == args[1] then
			target:SetPos(client:GetPos())

			for k, v in ipairs(player.GetAll()) do
				v:ChatPrint( string.format("[UNITY] %s has brought %s to their location.", client:GetName(), target:GetName()) )
			end

			return
		end
	end

	client:ChatPrint( "Player not found!" )
end)

concommand.Add("unity_bringall", function( client, cmd, args )
	if !client:IsAdmin() then return end

	for k, v in ipairs(player.GetAll()) do
		if (client != v and v:IsPlayer() and v:Alive()) then
			v:SetPos(client:GetPos())
		end
	end

	for k, v in ipairs(player.GetAll()) do
		v:ChatPrint( string.format("[UNITY] %s has brought all players to their location.", client:GetName()) )
	end
end)
