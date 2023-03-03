if Config == nil then
    Config = class({})
end

function Config:Init()
    self.config_inited = true

    local server_base = "http://127.0.0.1:8000"
    local server_token = "THISISDEMO"
    self.server = {
        url_get_scripts = string.format("%s/scripts?token=%s", server_base, server_token),
        url_post_scores = string.format("%s/scores?token=%s",  server_base, server_token),
    }

    self.extra_score_for_winner = 1
    self.candidates_per_team = 2
    
    self.candidates_count = 16
    
    self.round_time = 5 * 60
    self.hero_locations = {}
    
    for i = 0, 15 do
        self.hero_locations[i + 1] = Vector((i % 4) * 200 - 400, math.floor(i / 4) * 200 - 400)
    end

    -- how many seconds to wait after choosing hero
    -- and action
    self.round_begin_delay = 3

    self.shop = {
        location = Vector(0, 0),
        radius = 1e6,
    }

end

if not Config.config_inited then Config:Init() end

GameRules.Config = Config
