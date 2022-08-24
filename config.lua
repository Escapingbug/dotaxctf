if Config == nil then
    Config = class({})
end

function Config:Init()
    self.config_inited = true

    self.extra_score_for_winner = 1
    self.team_player_count = 1
    self.teams = {
        [19] = "team1",
        [20] = "team2",
    }
    self.team_count = 0
    for _, _ in pairs(self.teams) do
        self.team_count = self.team_count + 1
    end
    self.round_time = 60
    self.hero_locations = {
        [19] = Vector(100, 100),
        [20] = Vector(200, 100)
    }
end

if not Config.config_inited then Config:Init() end

GameRules.Config = Config
