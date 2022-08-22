if Config == nil then
    Config = class({})
end

function Config:Init()
    self.config_inited = true

    self.extra_score_for_winner = 1
    self.teams = {
        [1] = "team1",
        [2] = "team2",
    }
    self.round_time = 10
end

if not Config.config_inited then Config:Init() end

GameRules.Config = Config
