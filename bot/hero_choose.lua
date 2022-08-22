if HeroChoose == nil then
    HeroChoose = class({})
    HeroChoose:Init()
end

function HeroChoose:Init()
    self.a = 1
end

function HeroChoose:InitTeamScript()
    -- TODO: ask the server to give us the script of hero choose
end