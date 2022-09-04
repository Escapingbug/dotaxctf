require("config")
require("bot_script_env")
require("lib/timer")
require("lib/inspect")
require("lib/table")
require("lib/base64")
require("lib/json")

AVAILABLE_TEAMS = {
    DOTA_TEAM_GOODGUYS,
    DOTA_TEAM_BADGUYS,
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

function Rounds:UpdateRoundTimerPanel(cur_time)
    local event = {
        round_count = self.round_count,
        cur_time = cur_time
    }
    CustomGameEventManager:Send_ServerToAllClients(
        "updateRoundTimer",
        event
    )
end

function Rounds:UpdateScoresPanel()
    local scores_to_display = {
        round_count = self.round_count,
        scores = {}
    }
    for candidate_num, score in pairs(self.scores_this_round) do
        local name = Config.candidates[candidate_num]
        scores_to_display.scores[name] = score
    end
    CustomGameEventManager:Send_ServerToAllClients(
        "updateScores",
        scores_to_display
    )
end

function Rounds:CleanRoundScores()
    local req = CreateHTTPRequest("POST", "http://127.0.0.1:8000/scores?token=THISISDEMO")
    if req ~= nil then
        req:SetHTTPRequestRawPostBody("application/json", json.encode({
            scores = self.scores_this_round,
            round_count = self.round_count
        }))
        req:Send(function() end)
    end
    self.scores_this_round = {}
    for candidate_num, _ in pairs(Config.candidates) do
        self.scores_this_round[candidate_num] = 0
    end
    Rounds:UpdateScoresPanel()
end

function Rounds:AdjustScore(candidate, score_delta)
    if self.scores_this_round[candidate] == nil then
        self.scores_this_round[candidate] = 0
    end

    self.scores_this_round[candidate] = self.scores_this_round[candidate] + score_delta
    Rounds:UpdateScoresPanel()
end

function Rounds:Init()
    print("rounds constructor called")
    self.game_started = false

    self.round_count = 0
    -- team number => scores
    self.scores_this_round = {}
    Rounds:CleanRoundScores()

    -- team number => hero object
    self.heros = {}

    self.available_players = {}

    -- player id to candidate number
    self.player_to_candidate = {}
    self.candidate_to_player = {}

    self.history = {
        scores = {},
        choices = {},
    }
end

function Rounds:InitGameMode()
    print("Rounds:InitGameMode...")
    GameRules:SetUseUniversalShopMode(true)
    -- for faster entering
    GameRules:SetPreGameTime(3.0)

    -- disable auto gold gain
    GameRules:SetStartingGold(0)
    GameRules:SetGoldPerTick(0)

    local game_mode = GameRules:GetGameModeEntity()
    game_mode:SetAlwaysShowPlayerNames(true)
    game_mode:SetBuybackEnabled(false)
    game_mode:SetAllowNeutralItemDrops(false)

end

function Rounds:CleanupLivingHeros()
    for _, hero in pairs(self.heros) do
        hero:RemoveSelf()
    end

    self.heros = {}
end

--[[
    As we need bot player to know who is the killer,
    we setup the bot players with fake heros first.
]]
function Rounds:SetupBotPlayers()
    print(".. debug ? " .. tostring(debug.sethook))
    for team_id, team_name in pairs(Config.candidates) do
        local ob_hero = GameRules:AddBotPlayerWithEntityScript(
            "npc_dota_hero_abaddon",
            team_name,
            DOTA_TEAM_GOODGUYS,
            "bot/ob_hero_act.lua",
            false
        )

        assert(ob_hero, "add bot player failed")

        ob_hero:SetRespawnsDisabled(true)
        local player_id = ob_hero:GetPlayerID()
        ob_hero:RemoveSelf()
        print("adding player id " .. tostring(player_id) .. " to team " .. tostring(team_id))
        self.player_to_candidate[player_id] = team_id
        self.candidate_to_player[team_id] = player_id
    end
end

function Rounds:SetupLastHitListener()
    ListenToGameEvent("last_hit", function(event)
        local _entity_killed = event["EntKilled"]
        local player_id = event["PlayerID"]
        local candidate = self.player_to_candidate[player_id]
        Rounds:AdjustScore(candidate, 1)
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

    if self.round_count > 0 then
        local last_scores = deepcopy(self.scores_this_round)
        table.insert(self.history.scores, last_scores)
    end

    self.round_count = self.round_count + 1

    Rounds:CleanupLivingHeros()
    Rounds:ChooseHeros(scripts["chooser_scripts"])
    Timers:CreateTimer(
        Config.round_begin_delay,
        function ()
            Rounds:BeginRound(scripts["bot_scripts"])
        end
    )
end

function Rounds:InitCandidateHero(hero)
    hero:SetRespawnsDisabled(true)
end

function Rounds:PrepareRoundPlayerScripts(on_done)
    CreateHTTPRequest("GET", "http://127.0.0.1:8000/scripts?token=THISISDEMO"):Send(function(result)
        local body = result["Body"]
        print("got body: " .. body)
        json_code = json.decode(body) -- {"team_num": ,"script": }
        local chooser_scripts = {}
        local bot_scripts = {}
        if json_code ~= nil then
            for team_num, scripts in pairs(json_code) do
                chooser_scripts[tonumber(team_num)] = scripts["choose_hero"]
                bot_scripts[tonumber(team_num)] = scripts["action"]
            end
        else
            for candidate_num, _ in pairs(Config.candidates) do
                chooser_scripts[candidate_num] = "return {}"
                bot_scripts[candidate_num] = "return {}"
            end
        end

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

    local choices = {}

    -- split teams
    local team_count = Config.candidates_count / Config.candidates_per_team
    local team_config = {}

    for candidate_num, _ in pairs(Config.candidates) do
        table.insert(team_config, candidate_num)
    end

    team_config = table.shuffle(team_config)
    print("team config " .. GameRules.inspect(team_config))

    for i = 1, team_count do
        local cur_candidate = {}
        for _ = 1, Config.candidates_per_team do
            table.insert(cur_candidate, table.remove(team_config, 1))
        end

        local cur_team_id = AVAILABLE_TEAMS[i]

        for _, candidate_num in ipairs(cur_candidate) do
            -- print("chooser of " .. tostring(candidate_num), tostring(chooser_scripts[candidate_num]))
            local chooser = Sandbox:LoadChooseHeroScript(chooser_scripts[candidate_num])
            local hero_name = Sandbox:RunChooseHero(chooser)
            local player_id = self.candidate_to_player[candidate_num]
            local player_owner = PlayerResource:GetPlayer(player_id)
            print("player owner: " .. tostring(player_owner) .. "team id " .. tostring(cur_team_id))
            local candidate_hero = CreateUnitByName(
                hero_name,
                Config.hero_locations[candidate_num],
                true, -- findClearSpace
                nil, -- npcowner
                player_owner, -- entity owner
                cur_team_id
            )

            print("check player and team .. " .. tostring(candidate_hero:GetPlayerID()) .. " " .. tostring(candidate_hero:GetTeam()))

            Rounds:InitCandidateHero(candidate_hero)
            self.heros[candidate_num] = candidate_hero
            choices[candidate_num] = hero_name
        end
    end

    table.insert(self.history.choices, choices)
end

function Rounds:PrepareBeginRound()
    Rounds:PrepareRoundPlayerScripts(function (scripts)
        Rounds:NextRound(scripts)
    end)
end

--[[
    Returns living teams in an array.
]]
function Rounds:GetLivingTeams()
    -- count team alive heros
    local team_alive_counts = {}
    for team_id, _ in ipairs(AVAILABLE_TEAMS) do
        team_alive_counts[team_id] = 0
    end
    for candidate_num, _ in pairs(Config.candidates) do
        local hero = self.heros[candidate_num]
        if hero:IsAlive() then
            local team = hero:GetTeam()
            team_alive_counts[team] = team_alive_counts[team] + 1
        end
    end

    -- when less than one team got alive heros, round should be over
    local alive_teams = {}
    for team_num, alives in pairs(team_alive_counts) do
        if alives > 0 then
            table.insert(alive_teams, team_num)
        end
    end

    return alive_teams
end

--[[
    Scoring when time limit is reached
]]
function Rounds:RoundLimitedScoring()
    local living_teams = Rounds:GetLivingTeams()
    if #living_teams == 1 then
        -- we got an winning team!
        local winning_team = living_teams[1]
        for candidate_num, _ in pairs(Config.candidates) do
            local hero = self.heros[candidate_num]
            local team = hero:GetTeam()
            if team == winning_team then
                Rounds:AdjustScore(candidate_num, 1)
            end
        end
    else
        -- Multiple team is winning..
        -- we add scores to the living heros.

        for candidate_num, _ in pairs(Config.candidates) do
            local hero = self.heros[candidate_num]
            if hero:IsAlive() then
                Rounds:AdjustScore(candidate_num, 1)
            end
        end
    end
end

function Rounds:BeginRound(bot_scripts)

    CustomGameEventManager:Send_ServerToAllClients("updateScores", self.scores_this_round)
    -- TODO: push the scores

    Rounds:CleanRoundScores()

    Rounds:UpdateRoundTimerPanel(GameRules:GetDOTATime(false, false))
    Timers:CreateTimer(
        "round_limit_timer",
        {
            endTime = Config.round_time,
            callback = function ()
                Timers:RemoveTimer("round_periodic_timer")
                -- Round limit is reached, we should count the living teams
                Rounds:RoundLimitedScoring()
                Rounds:PrepareBeginRound()
            end
        }
    )

    Timers:CreateTimer(
        "round_periodic_timer",
        {
            endTime = 1,
            callback = function()
                local living_teams = Rounds:GetLivingTeams()
                if #living_teams <= 1 then
                    Timers:RemoveTimer("round_limit_timer")
                    Rounds:PrepareBeginRound()
                    return
                else
                    return 1
                end
            end
        }
    )

    for candidate_num, _ in pairs(Config.candidates) do
        local hero = self.heros[candidate_num]
        if hero then
            local script = bot_scripts[candidate_num]
            BotScriptEnv:AttachScriptOnUnit(hero, script)
        end
    end
end

if not Rounds.heros then Rounds:Init() end

Sandbox:SetupGameInfo{
    GetRoundCount     = function()
        return Rounds.round_count
    end,
    GetHistoryScores  = function(round)
        local scores = Rounds.history.scores[round]
        return deepcopy(scores)
    end,
    GetHistoryChoices = function(round)
        local choices = Rounds.history.choices[round]
        return deepcopy(choices)
    end,
    GetCandidates = function()
        return deepcopy(Config.candidates)
    end
}

GameRules.Rounds = Rounds
