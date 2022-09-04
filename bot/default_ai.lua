local AI = {}

AI.chooser = [[
local round = GetRoundCount()
-- print("chooser round", round)
-- if round > 1 then
--     local scores = GetHistoryScores(round - 1)
--     local choices = GetHistoryChoices(round - 1)
--     for candidate_num, candidate_name in pairs(GetCandidates()) do
--         print("candidate", candidate_num, candidate_name)
--         print("score", scores[candidate_num])
--         print("choice", choices[candidate_num])
--     end
-- end
return "npc_dota_hero_bloodseeker"
]]

AI.action = [[
local hero, ctx = ...
local round = GetRoundCount()

--  print("team", hero:GetTeam())
--  print("name", hero:GetUnitName())
--  print("agility", hero:GetAgility())
--  print("intellect", hero:GetIntellect())
--  print("strength", hero:GetStrength())
--  print("health", hero:GetHealth(), hero:GetMaxHealth(), hero:GetHealthRegen())
--  print("mana", hero:GetMana(), hero:GetMaxMana(), hero:GetManaRegen())
--  print("level", hero:GetLevel())
--  print("attack speed", hero:GetAttackSpeed())
--  print("attack range", hero:GetAttackRange())
--  print("is hero", hero:IsConsideredHero())

ability_count = hero:GetAbilityCount()
for i = 0, ability_count-1 do
    local ability = hero:GetAbilityByIndex(i)
    if ability then
        -- print("ability name", ability:GetAbilityName())
        -- print("level", ability:GetLevel())
        -- print("Behavior", ability:GetBehavior())
        -- print("AOE Radius", ability:GetAOERadius())
        -- print("channel cost", ability:GetChannelledManaCostPerSecond(ability:GetLevel()))
        -- print("channel time", ability:GetChannelTime())
        -- print("cast range", ability:GetEffectiveCastRange(hero:GetAbsOrigin(), nil))
        -- print("cool down", ability:GetEffectiveCooldown(ability:GetLevel()))
        -- print("mana cost", ability:GetManaCost(ability:GetLevel()))
        -- print("toggle", ability:GetToggleState())
        -- print("is item", ability:IsItem())
        -- print("duration", ability:GetDuration())
    end
end

if hero:IsAttacking() then
    return ctx
end


DOTA_UNIT_TARGET_TEAM_ENEMY = 2
DOTA_UNIT_TARGET_HERO = 1
DOTA_UNIT_TARGET_FLAG_NONE = 0
FIND_ANY_ORDER = 0
DOTA_UNIT_ORDER_ATTACK_TARGET = 4

local units = hero:FindUnitsInRadius(
    hero:GetAbsOrigin(),
    3000,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER
)
if #units > 0 then
    hero:ExecuteOrder(
        DOTA_UNIT_ORDER_ATTACK_TARGET,
        units[1].GetEntityIndex(),
        nil,
        nil,
        false
    )
end

if type(ctx) == "table" then
    ctx = 1
else
    ctx = ctx + 1
end
return ctx
]]

return AI
