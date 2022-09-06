lua_sandbox = require("lib/lua-sandbox/sandbox")

if Sandbox == nil then
    Sandbox = class({})
end

local function copy_method(obj, method)
    return function(self, ...)
        return obj[method](obj, ...)
    end
end

function Sandbox:Init()
    self.game_info = {}
    self.public_api = self:SandboxPublicAPI()
    self.default_hero = "npc_dota_hero_axe"
    self.init = true
end

function Sandbox:SetupGameInfo(game_info)
    self.game_info = game_info
end

function Sandbox:LoadScript(user_script, quota, env)
    for k, v in pairs(self.public_api) do
        env[k] = v
    end
    for k, v in pairs(self.game_info) do
        env[k] = v
    end
    local options = {
        quota = quota,
        env = env,
    }
    local results = {pcall(lua_sandbox.protect, user_script, options)}
    if not results[1] then
        print("load script error: " .. results[2])
        return nil
    end
    return results[2]
end

function Sandbox:RunFunctionWrap(func, ...)
    if not func then
        return nil
    end
    local results = {pcall(func, ...)}
    if not results[1] then
        print("run script error: " .. results[2])
        return nil
    end
    return results[2]
end

function Sandbox:LoadChooseHeroScript(user_script)
    return self:LoadScript(user_script, 100000, {})
end

function Sandbox:LoadActionScript(user_script)
    return self:LoadScript(user_script, 500000, {})
end

function Sandbox:RunChooseHero(choose_func)
    local hero_name = self:RunFunctionWrap(choose_func)
    if type(hero_name) ~= "string" then
        hero_name = self.default_hero
    end
    return hero_name
end

function Sandbox:RunAction(act_func, entity, ctx)
    local sandboxed_entity = self:SandboxHero(entity, false)
    local new_ctx = self:RunFunctionWrap(act_func, sandboxed_entity, ctx)
    return new_ctx
end

function Sandbox:SandboxPublicAPI()
    local api = {
        Vector = Vector,
        QAngle = QAngle,
        print = print, -- TODO: remove this
    }
    return api
end

function Sandbox:SandboxHero(hero, readonly)
    if hero == nil then
        return nil
    end

    local sandboxed = self:SandboxBaseNPC(hero, readonly)

    sandboxed.GetAgility    = copy_method(hero, "GetAgility")
    sandboxed.GetIntellect  = copy_method(hero, "GetIntellect")
    sandboxed.GetStrength   = copy_method(hero, "GetStrength")

    -- TODO: level up

    return sandboxed
end

function Sandbox:SandboxBaseNPC(npc, readonly)
    if npc == nil then
        return nil
    end

    local sandboxed = {
        GetEntityIndex    = copy_method(npc, "GetEntityIndex"),
        GetAbsOrigin      = copy_method(npc, "GetAbsOrigin"),
        GetTeam           = copy_method(npc, "GetTeam"),
        GetAttackSpeed    = copy_method(npc, "GetAttackSpeed"),
        GetHealth         = copy_method(npc, "GetHealth"),
        GetHealthRegen    = copy_method(npc, "GetHealthRegen"),
        GetMaxHealth      = copy_method(npc, "GetMaxHealth"),
        GetLevel          = copy_method(npc, "GetLevel"),
        GetMana           = copy_method(npc, "GetMana"),
        GetMaxMana        = copy_method(npc, "GetMaxMana"),
        GetManaRegen      = copy_method(npc, "GetManaRegen"),
        GetUnitName       = copy_method(npc, "GetUnitName"),
        GetAttackRange    = copy_method(npc, "Script_GetAttackRange"),
        GetAbilityCount   = copy_method(npc, "GetAbilityCount"),
        IsAttacking       = copy_method(npc, "IsAttacking"),
        IsConsideredHero  = copy_method(npc, "IsConsideredHero"),
    }

    function sandboxed:FindUnitsInRadius(
        location,
        radius,
        team_filter,
        type_filter,
        flag_filter,
        find_order
    )
        local units = FindUnitsInRadius(
            self:GetTeam(),
            location,
            nil, -- cacheUnit
            radius,
            team_filter,
            type_filter,
            flag_filter,
            find_order,
            false -- canGrowCache
        )
        local sandboxed_units = {}
        for _, unit in ipairs(units) do
            local sandboxed_unit = Sandbox:SandboxUnit(unit, true)
            table.insert(sandboxed_units, sandboxed_unit)
        end
        return sandboxed_units
    end

    function sandboxed:GetAbilityByIndex(index)
        local ability = npc:GetAbilityByIndex(index)
        return Sandbox:SandboxAbility(ability)
    end

    if readonly then
        return sandboxed
    end

    function sandboxed:ExecuteOrder(
        order_type,
        target_index,
        ability_index,
        position,
        queue
    )
        ExecuteOrderFromTable{
            UnitIndex = self:GetEntityIndex(),
            OrderType = order_type,
            TargetIndex = target_index,
            AbilityIndex = ability_index,
            Position = position,
            Queue = queue
        }
    end

    function sandboxed:PurchaseItem(item_name)
        local item = CreateItem(item_name, npc, npc)
        if item == nil or not item:IsPurchasable() then
            return false
        end

        local gold_own = npc:GetGold()
        local gold_cost = item:GetCost()
        local gold_left = gold_own - gold_cost
        if gold_left < 0 then
            return false
        end

        -- we only use unreliable gold
        npc:SetGold(gold_left, false)
        npc:AddItem(item)
        return true
    end

    return sandboxed
end

function Sandbox:SandboxUnit(unit, readonly)
    if unit == nil then
        return nil
    elseif unit:IsConsideredHero() then
        return self:SandboxHero(unit, readonly)
    else -- TODO: support more NPC types
        return nil
    end
end

function Sandbox:SandboxAbility(ability)
    if ability == nil then
        return nil
    end

    local sandboxed = {
        GetAbilityName            = copy_method(ability, "GetAbilityName"),
        GetAOERadius              = copy_method(ability, "GetAOERadius"),
        GetBehavior               = copy_method(ability, "GetBehavior"),
        GetChannelledManaCostPerSecond
                                  = copy_method(ability, "GetChannelledManaCostPerSecond"),
        GetChannelTime            = copy_method(ability, "GetChannelTime"),
        GetCooldownTimeRemaining  = copy_method(ability, "GetCooldownTimeRemaining"),
        GetCurrentAbilityCharges  = copy_method(ability, "GetCurrentAbilityCharges"),
        GetEffectiveCastRange     = copy_method(ability, "GetEffectiveCastRange"), -- TODO: fix args
        GetEffectiveCooldown      = copy_method(ability, "GetEffectiveCooldown"),
        GetLevel                  = copy_method(ability, "GetLevel"),
        GetLevelSpecialValueNoOverride
                                  = copy_method(ability, "GetLevelSpecialValueNoOverride"),
        GetManaCost               = copy_method(ability, "GetManaCost"),
        GetSpecialValueFor        = copy_method(ability, "GetSpecialValueFor"),
        GetToggleState            = copy_method(ability, "GetToggleState"),
        GetDuration               = copy_method(ability, "GetDuration"),
        IsItem                    = copy_method(ability, "IsItem"),
    }

    return sandboxed
end

if not Sandbox.init then Sandbox:Init() end

GameRules.Sandbox = Sandbox
