if Scores == nil then
    Scores = class({})
    Scores:Init()
end

function Scores:Init()
    -- team number => scores
    self.teamScores = {}
end