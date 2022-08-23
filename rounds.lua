require("config")
require("bot_script_env")
require("lib/timer")

if Rounds == nil then
    Rounds = class({})
end

function Rounds:Init()
    print("rounds constructor called")
    self.game_started = false

    self.round_count = 0
    -- team number => scores
    self.scores_this_round = {}
    -- team number => hero object
    self.heros = {}
end

function Rounds:InitGameMode()
    print("Rounds:InitGameMode...")

    -- for faster entering
	GameRules:SetPreGameTime(3.0)

    -- disable auto gold gain
    GameRules:SetStartingGold(0)
    GameRules:SetGoldPerTick(0)
end

function Rounds:CleanupLivingHeros()
    print("clean up heros..")
    -- TODO: delete play?
    for team_num, hero in pairs(self.heros) do
        if hero:IsAlive() then
            local team_score = self.scores_this_round[team_num]
            if team_score == nil then
                team_score = 0
            end
            self.scores_this_round[team_num] = team_score + Config.extra_score_for_winner
        end

        hero:ForceKill(true)
    end

    self.heros = {}
end

function Rounds:BeginGame()
    if not self.game_started then

        ListenToGameEvent("last_hit", function (event)
            local entity_killed = event["EntKilled"]
            local player_id = event["PlayerID"]
            print("got last hit! " .. entity_killed .. " " .. player_id)
        end, nil)

        ListenToGameEvent("entity_hurt", function (event)
            local killed = event["entindex_killed"]
            local attacker = event["entindex_attacker"]
            print("entity hurt " .. killed .. " " .. attacker)
        end, nil)

        ListenToGameEvent("dota_player_kill", function (event)
            local killer = event["killer1_userid"]
            local victim = event["victim_userid"]
            print("dota player kill " .. killer .. " " .. victim)
        end, nil)

        Rounds:PrepareBeginRound()
        self.game_started = true
        -- all next rounds should be called on timer set by next round
    end
end

function Rounds:NextRound(scripts)
    print("Next Round")

    Rounds:CleanupLivingHeros()
    Rounds:ChooseHeros(scripts["chooser_scripts"])
    Rounds:BeginRound(scripts["bot_scripts"])
end

function Rounds:InitTeamHero(hero)
    hero:SetRespawnsDisabled(true)
end

function Rounds:PrepareRoundPlayerScripts(on_done)
    -- TODO: real http access to the player scripts
    local sample_choose_hero_code = [[
    return function (round)
        return "npc_dota_hero_axe"
    end
]]
    
    local sample_bot_code = [[
    return function (entity)
    end
]]

    Timers:CreateTimer(3, function ()
        local chooser_scripts = {
            [19] = sample_choose_hero_code,
            [20] = sample_choose_hero_code
        }

        local bot_scripts = {
            [19] = sample_bot_code,
            [20] = sample_bot_code
        }

        local scripts = {
            chooser_scripts = chooser_scripts,
            bot_scripts = bot_scripts
        }

        on_done(scripts)
    end)
end

function Rounds:ChooseHeros(chooser_scripts)
    -- TODO: http fetch the real hero chooser code
    -- TODO: add hero chooser fetch flag so that game only starts
    -- when hero is added
    print("choosing heros")
    for team_num, team_name in pairs(Config.teams) do
        local chooser = load(chooser_scripts[team_num])()
        print("chooser " .. tostring(chooser))
        if chooser ~= nil then
            local hero_name = chooser(self.round_count)
            local team_hero = CreateUnitByName(
                hero_name,
                Config.hero_locations[team_num],
                true, -- findClearSpace
                nil, -- npcowner
                nil, -- entity owner
                DOTA_TEAM_NOTEAM
            )
            print("new hero for " .. team_name .. ": " .. tostring(team_hero) .. " id: " .. team_hero:GetHeroID())

            Rounds:InitTeamHero(team_hero)
            self.heros[team_num] = team_hero
        end
    end
end

function Rounds:PrepareBeginRound()
    Rounds:PrepareRoundPlayerScripts(function (scripts)
        Rounds:NextRound(scripts)
    end)
end

function Rounds:BeginRound(bot_scripts)

    Timers:CreateTimer(
        Config.round_time,
        function()
            Rounds:PrepareBeginRound()
        end
    )

    for team_num, team_name in pairs(Config.teams) do
        local hero = self.heros[team_num]
        if hero then
            local script = bot_scripts[team_num]
            BotScriptEnv:AttachScriptOnUnit(hero, script)   
        end
    end
end

if not Rounds.heros then Rounds:Init() end

GameRules.Rounds = Rounds