-- Generated from template
require("config")
require("sandbox")
require("rounds")
require("commands")

if CAddonTemplateGameMode == nil then
	CAddonTemplateGameMode = class({})
end

function Precache(context)
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = CAddonTemplateGameMode()
	GameRules.AddonTemplate:InitGameMode()

	print("Game Activate")
end

function CAddonTemplateGameMode:InitGameMode()
	print( "Template addon is loaded." )
	Rounds:InitGameMode()
	local game_mode = GameRules:GetGameModeEntity()
	game_mode:SetThink( "OnThink", self, "GlobalThink", 2 )
	game_mode:SetFogOfWarDisabled(true)
end

-- Evaluate the state of the game
function CAddonTemplateGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		Rounds:InitFromServerAndBeginGame()
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end
