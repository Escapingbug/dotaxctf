if Config == nil then
    Config = class({})
end

function Config:Init()
    self.config_inited = true

    self.extra_score_for_winner = 1
    self.candidates_per_team = 1
    self.candidates = {
        [19] = "Eur3kA",
        [20] = "FlappyPig",
    }
    self.candidates_count = 0
    for _, _ in pairs(self.candidates) do
        self.candidates_count = self.candidates_count + 1
    end
    self.round_time = 5 * 60
    self.hero_locations = {
        [19] = Vector(-400, -400),
        [20] = Vector(400, 400)
    }
    -- how many seconds to wait after choosing hero
    -- and action
    self.round_begin_delay = 3

    self.shop = {
        location = Vector(0, 0),
        radius = 1e6,
    }

    local server_base = "http://127.0.0.1:8000"
    local server_token = "THISISDEMO"
    self.server = {
        url_get_scripts = string.format("%s/scripts?token=%s", server_base, server_token),
        url_post_scores = string.format("%s/scores?token=%s",  server_base, server_token),
    }
end

if not Config.config_inited then Config:Init() end

GameRules.Config = Config
