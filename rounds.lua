require("config")
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
    -- TODO: delete player?
    for team_num, hero in ipairs(self.heros) do
        if hero:IsAlive() then
            local team_score = self.score_this_round[team_num]
            self.scores_this_round[team_num] = team_score + Config.extra_score_for_winner
        end
    end

    self.heros = {}
end

function Rounds:BeginGame()
    if not self.game_started then
        Rounds:NextRound()
        -- all next rounds should be called on timer set by next round
    end
end

function Rounds:NextRound()
    self.game_started = true
    Rounds:CleanupLivingHeros()
    Rounds:ChooseHeros()
    Rounds:PrepareBeginRound()
end

function Rounds:InitTeamHero(hero)
    -- TODO: anything to set?
end

function Rounds:ChooseHeros()
    -- TODO: http fetch the real hero chooser code
    -- TODO: add hero chooser fetch flag so that game only starts
    -- when hero is added
    local sample_choose_hero_code = [[
    function choose_hero(round)
        return "npc_dota_hero_abaddon"
    end
]]

    for team_num, team_name in ipairs(Config.teams) do
        local chooser = load(sample_choose_hero_code)
        local hero_name = chooser(self.round_count)

        local team_hero = GameRules:AddBotPlayerWithEntityScript(
            hero_name,
            team_name,
            DOTA_TEAM_CUSTOM_1,
            "bot/hero_act_" .. tostring(team_num) .. ".lua",
            true
        )

        Rounds:InitTeamHero(team_hero)
        self.heros[team_num] = team_hero

    end
end

function Rounds:PrepareBeginRound()
    -- TODO
    local player1 = require("bot/hero_act_1")
    local player2 = require("bot/hero_act_2")
    -- 1. set timer on waiting for fetching act scripts
    Timers:CreateTimer(function()
        if player1.HeroReady == true and player2.HeroReady == true then
            print("all ready! game start!")
            -- TODO: start game
        else
            return 1.0
        end
    end)
    
    -- 2. TODO: set timer on round ends (next round)
    local round_time = Config.round_time
    Timers:CreateTimer(round_time, function() Rounds:NextRound() end)
end

if not Rounds.heros then Rounds:Init() end

GameRules.Rounds = Rounds