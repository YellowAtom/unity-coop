GM.Name = "Unity Coop"
GM.Author = "Yell0wAt0m"

UNITY_DEFAULT_MODELS = {
	"models/player/group03/male_01.mdl",
	"models/player/group03/male_02.mdl",
	"models/player/group03/male_03.mdl",
	"models/player/group03/male_04.mdl",
	"models/player/group03/male_05.mdl",
	"models/player/group03/male_05.mdl",
	"models/player/group03/male_06.mdl",
	"models/player/group03/male_07.mdl",
	"models/player/group03/male_08.mdl",
	"models/player/group03/male_09.mdl",
	"models/player/group03/female_01.mdl",
	"models/player/group03/female_02.mdl",
	"models/player/group03/female_03.mdl",
	"models/player/group03/female_04.mdl",
	"models/player/group03/female_05.mdl",
	"models/player/group03/female_06.mdl",

	"models/player/group03m/male_01.mdl",
	"models/player/group03m/male_02.mdl",
	"models/player/group03m/male_03.mdl",
	"models/player/group03m/male_04.mdl",
	"models/player/group03m/male_05.mdl",
	"models/player/group03m/male_05.mdl",
	"models/player/group03m/male_06.mdl",
	"models/player/group03m/male_07.mdl",
	"models/player/group03m/male_08.mdl",
	"models/player/group03m/male_09.mdl",
	"models/player/group03m/female_01.mdl",
	"models/player/group03m/female_02.mdl",
	"models/player/group03m/female_03.mdl",
	"models/player/group03m/female_04.mdl",
	"models/player/group03m/female_05.mdl",
	"models/player/group03m/female_06.mdl"
}

function GM:Initialize()
	if SERVER then
		local difficulty = cvars.Number("unity_difficulty", 2)

		math.Clamp( difficulty, 1, 3 )

		RunConsoleCommand("skill", difficulty)
		game.SetSkillLevel( difficulty )
	end
end

function GM:PlayerInitialSpawn( client, transition )
	if !transition then
		client:ChatPrint( "[UNITY] Press F1 for gamemode menu!" )
	end
end

function GM:PlayerSpawn( client, transition )
	player_manager.OnPlayerSpawn( client, transiton )
	player_manager.RunClass( client, "Spawn" )

	if client:IsBot() then
		client:SetModel(UNITY_DEFAULT_MODELSs[math.random(#UNITY_DEFAULT_MODELS)])
	else
		client:SetModel( client:GetInfo( "unity_playermodel" ) )
		client:SetPlayerColor( Vector( client:GetInfo( "unity_playercolor" )))
		client:SetupHands()
	end

	client:UnSpectate()

	// Sets all the HL2 movement values.
	client:SetSlowWalkSpeed( 150 ) // Walk Speed
	client:SetWalkSpeed( 190 ) // Norm Speed
	client:SetRunSpeed( 320 ) // Sprint Speed
	client:SetCrouchedWalkSpeed( 0.33333333 ) // Crouch Modifier from Norm Speed

	// Have to enable flashlight in base gamemode.
	client:AllowFlashlight( true )

	// This makes players non-solid only to each other, this feels like it could have unforeseen consequences though.
	client:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

	if cvars.Bool("unity_givegravitygun", false) and !transiton then
		client:Give("weapon_physcannon")
	end
end

// Gamemode Controls

function GM:ShowHelp( client )
	client:ConCommand("unity_menu")
end

function GM:ShowTeam( client )
end

function GM:ShowSpare1( client )
	client:ConCommand("unity_dropweapon")
end

function GM:ShowSpare2( client )
	client:ConCommand("unity_dropammo")
end
