DeriveGamemode("base")

include("shared.lua")
include("cl_menu.lua")

CreateClientConVar("unity_playermodel", UNITY_DEFAULT_MODELS[math.random(#UNITY_DEFAULT_MODELS)], true, true, "The player's static model.")
CreateClientConVar("unity_playercolor", "0.24 0.34 0.41", true, true, "The colour used by the player's model.")

function GM:DrawDeathNotice( x, y )
	return
end

function GM:OnPlayerChat( client, strText, bTeamOnly, bPlayerIsDead )
	local tab = {}

	if ( bPlayerIsDead ) then
		table.insert( tab, Color( 255, 30, 40 ) )
		table.insert( tab, "*DEAD* " )
	end

	if ( bTeamOnly ) then
		table.insert( tab, Color( 30, 160, 40 ) )
		table.insert( tab, "(TEAM) " )
	end

	if ( IsValid( client ) ) then
		table.insert( tab, client )
	else
		table.insert( tab, Color( 125, 125, 125) )
		table.insert( tab, "[Console]" )
	end

	local filter_context = TEXT_FILTER_GAME_CONTENT
	if ( bit.band( GetConVarNumber( "cl_chatfilters" ), 64 ) != 0 ) then filter_context = TEXT_FILTER_CHAT end

	table.insert( tab, color_white )
	table.insert( tab, ": " .. util.FilterText( strText, filter_context, IsValid( client ) and client or nil ) )

	chat.AddText( unpack( tab ) )
	chat.PlaySound()

	return true

end
