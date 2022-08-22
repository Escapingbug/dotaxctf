PlayerHeroOperation = nil
LoggedAlready = false

function HeroThink()
    if PlayerHeroOperation ~= nil then
        PlayerHeroOperation()
    end

    if GameRule ~= nil and not LoggedAlready then
        print("game rule accessible (player 1)")
        LoggedAlready = true
    end

    return 0.1
end

if thisEntity then
    thisEntity:SetThink(HeroThink)
end

return {
    HeroReady = true
}