if Rounds == nil then
    Rounds = class({
        constructor = function ()
            self.roundCount = 0
            -- team number => scores
            self.scoresThisRound = {}
            -- team number => hero object
            self.heros = {}
        end
    })
end