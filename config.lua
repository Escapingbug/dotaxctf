if Config == nil then
    Config = class({})
end

function Config:Init()
    self.config_inited = true

    self.extra_score_for_winner = 1
    self.candidates_per_team = 1
    self.candidates = {
        [19] = "team1",
        [20] = "team2",
    }
    self.candidates_count = 0
    for _, _ in pairs(self.candidates) do
        self.candidates_count = self.candidates_count + 1
    end
    self.round_time = 60
    self.hero_locations = {
        [19] = Vector(100, 100),
        [20] = Vector(500, 500)
    }
    -- how many seconds to wait after choosing hero
    -- and action
    self.round_begin_delay = 3
end

if not Config.config_inited then Config:Init() end

GameRules.Config = Config
