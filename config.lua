if Config == nil then
    Config = class({})
end

function Config:Init()
    self.config_inited = true

    local server_base = "http://xgame.challenge.xctf.org.cn/api/ct/admin/xgame/game"
    self.server_token = "redacted"
    self.server_url = {
        init = string.format("%s/init/", server_base),
        service = string.format("%s/service/", server_base), -- GET for round init, POST for round end
    }

    self.extra_score_for_winner = 1
    
    -- the 3 vars below will be set in Rounds:InitFromServerAndBeginGame()
    self.candidate_count = 0
    self.team_count = 0
    self.candidates_per_team = 0
    
    self.round_time = 5 * 60
    self.hero_locations = {}

    self.total_rounds_count = 60 -- 5 hours in total, 5 minutes per round
    
    for i = 0, 15 do
        self.hero_locations[i + 1] = Vector((i % 4) * 200 - 400, math.floor(i / 4) * 200 - 400)
    end

    -- how many seconds to wait after choosing hero
    -- and action
    self.round_begin_delay = 3

end

if not Config.config_inited then Config:Init() end

GameRules.Config = Config
