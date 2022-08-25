require("config")
require("bot_script_env")
require("lib/timer")
require("lib/inspect")

AVAILABLE_TEAMS = {
    DOTA_TEAM_GOODGUYS,
    DOTA_TEAM_BADGUYS,
    DOTA_TEAM_NEUTRALS,
    DOTA_TEAM_CUSTOM_1,
    DOTA_TEAM_CUSTOM_2,
    DOTA_TEAM_CUSTOM_3,
    DOTA_TEAM_CUSTOM_4,
    DOTA_TEAM_CUSTOM_5,
    DOTA_TEAM_CUSTOM_6,
    DOTA_TEAM_CUSTOM_7,
    DOTA_TEAM_CUSTOM_8,
}

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

    self.available_players = {}

    -- player id to team number
    self.player_to_team = {}
    self.team_to_player = {}
end

function Rounds:InitGameMode()
    print("Rounds:InitGameMode...")
    GameRules:GetGameModeEntity():SetAlwaysShowPlayerNames(true)
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

        -- FIXME: why the body is not gone??
        hero:ForceKill(true)
    end

    self.heros = {}
end

--[[
    As we need bot player to know who is the killer,
    we setup the bot players with fake heros first.
]]
function Rounds:SetupBotPlayers()
    print(".. debug ? " .. tostring(debug.sethook))
    for team_id, team_name in pairs(Config.teams) do
        local ob_hero = GameRules:AddBotPlayerWithEntityScript(
            "npc_dota_hero_abaddon",
            team_name,
            DOTA_TEAM_GOODGUYS,
            "bot/ob_hero_act.lua",
            false
        )

        assert(ob_hero, "add bot player failed")

        ob_hero:SetRespawnsDisabled(true)
        ob_hero:ForceKill(false)
        local player_id = ob_hero:GetPlayerID()
        print("adding player id " .. tostring(player_id) .. " to team " .. tostring(team_id))
        self.player_to_team[player_id] = team_id
        self.team_to_player[team_id] = player_id
    end
end

function Rounds:SetupLastHitListener()
    ListenToGameEvent("last_hit", function(event)
        local entity_killed = event["EntKilled"]
        local player_id = event["PlayerID"]
        local team_name = self.player_to_team[player_id]
        -- TODO: add scores
        print("got last hit! " .. entity_killed .. " " .. player_id)
        print("last hit team name " .. tostring(team_name))
    end, nil)
end

function Rounds:BeginGame()
    if not self.game_started then
        -- TODO: use add bot player with entity script to add
        -- player so that we can listen to last hit to add
        -- the score.
        -- Explain: last_hit can only get you the player id instead
        -- of the entity id.

        Rounds:SetupBotPlayers()
        Rounds:SetupLastHitListener()

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
        if entity:IsAttacking() then
            return
        end
        local units = FindUnitsInRadius(
            entity:GetTeam(),
            Vector(200, 200),
            nil,
            300.0,
            DOTA_UNIT_TARGET_TEAM_ENEMY,
            DOTA_UNIT_TARGET_HERO,
            DOTA_UNIT_TARGET_FLAG_NONE,
            FIND_ANY_ORDER,
            false
        )
        if #units > 0 then
            entity:MoveToTargetToAttack(units[1])
        end
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

function table.shuffle(x)
	for i = #x, 2, -1 do
		local j = math.random(i)
		x[i], x[j] = x[j], x[i]
	end

    return x
end

function table.clone(list)
    return {table.unpack(list)}
end

function Rounds:ChooseHeros(chooser_scripts)
    -- TODO: http fetch the real hero chooser code
    -- TODO: add hero chooser fetch flag so that game only starts
    -- when hero is added
    print("choosing heros")

    -- split teams
    local team_count = Config.team_count / Config.team_player_count
    local team_config = {}

    for team_id, _ in pairs(Config.teams) do
        table.insert(team_config, team_id)
    end

    team_config = table.shuffle(team_config)
    print("team config " .. GameRules.inspect(team_config))

    for i = 1, team_count do
        -- cur_team: team_num (of ctf) for current team
        local cur_team = {}
        for _ = 1, Config.team_player_count do
            table.insert(cur_team, table.remove(team_config, 1))
        end

        local cur_team_id = AVAILABLE_TEAMS[i]

        for _, team_num in ipairs(cur_team) do
            print("chooser of " .. tostring(team_num) .. tostring(chooser_scripts[team_num]))
            local chooser = load(chooser_scripts[team_num])()
            if chooser ~= nil then
                local hero_name = chooser(self.round_count)
                local player_id = self.team_to_player[team_num]
                local player_owner = PlayerResource:GetPlayer(player_id)
                print("player owner: " .. tostring(player_owner) .. "team id " .. tostring(cur_team_id))
                local team_hero = CreateUnitByName(
                    hero_name,
                    Config.hero_locations[team_num],
                    true, -- findClearSpace
                    nil, -- npcowner
                    player_owner, -- entity owner
                    cur_team_id
                )

                print("check player and team .. " .. tostring(team_hero:GetPlayerID()) .. " " .. tostring(team_hero:GetTeam()))

                Rounds:InitTeamHero(team_hero)
                self.heros[team_num] = team_hero
            end
        end
    end
end

function Rounds:PrepareBeginRound()
    Rounds:PrepareRoundPlayerScripts(function (scripts)
        Rounds:NextRound(scripts)
    end)
end

function Rounds:BeginRound(bot_scripts)

    local round_hint = "Round #" .. self.round_count .. "begins!!"
    -- TODO: How to display the message??
    -- this is not working :(
    Msg(round_hint)

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