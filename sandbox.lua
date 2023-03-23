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
    sandboxed.GetGold       = copy_method(hero, "GetGold")

    sandboxed.candidate_id  = hero.candidate_id

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

    local order_whitelist = {
        [DOTA_UNIT_ORDER_NONE]              = true,
        [DOTA_UNIT_ORDER_MOVE_TO_POSITION]  = true,
        [DOTA_UNIT_ORDER_MOVE_TO_TARGET]    = true,
        [DOTA_UNIT_ORDER_ATTACK_MOVE]       = true,
        [DOTA_UNIT_ORDER_ATTACK_TARGET]     = true,
        [DOTA_UNIT_ORDER_CAST_POSITION]     = true,
        [DOTA_UNIT_ORDER_CAST_TARGET]       = true,
        [DOTA_UNIT_ORDER_CAST_TARGET_TREE]  = true,
        [DOTA_UNIT_ORDER_CAST_NO_TARGET]    = true,
        [DOTA_UNIT_ORDER_CAST_TOGGLE]       = true,
        [DOTA_UNIT_ORDER_HOLD_POSITION]     = true,
        [DOTA_UNIT_ORDER_TRAIN_ABILITY]     = true,
        [DOTA_UNIT_ORDER_DROP_ITEM]         = true,
        [DOTA_UNIT_ORDER_GIVE_ITEM]         = true,
        [DOTA_UNIT_ORDER_PICKUP_ITEM]       = true,
        [DOTA_UNIT_ORDER_PURCHASE_ITEM]     = true,
        [DOTA_UNIT_ORDER_SELL_ITEM]         = true,
        [DOTA_UNIT_ORDER_MOVE_ITEM]         = true,
        [DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO]  = true,
        [DOTA_UNIT_ORDER_STOP]              = true,
        [DOTA_UNIT_ORDER_MOVE_TO_DIRECTION] = true,
        [DOTA_UNIT_ORDER_PATROL]            = true,
        [DOTA_UNIT_ORDER_CONTINUE]          = true,
        [DOTA_UNIT_ORDER_MOVE_RELATIVE]     = true,
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

    function sandboxed:GetItemInSlot(slot)
        local item = npc:GetItemInSlot(slot)
        return Sandbox:SandboxItem(item)
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
        if not order_whitelist[order_type] then
            return
        end
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
        if item == nil then
            return false
        end
        if not item:IsPurchasable() or not npc:IsAlive() then
            item:RemoveSelf()
            return false
        end

        local gold_own = npc:GetGold()
        local gold_cost = item:GetCost()
        local gold_left = gold_own - gold_cost
        if gold_left < 0 then
            item:RemoveSelf()
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

        GetEntityIndex            = copy_method(ability, "GetEntityIndex"),
    }

    return sandboxed
end

function Sandbox:SandboxItem(item)
    if item == nil then
        return nil
    end

    local sandboxed = {
        CanBeUsedOutOfInventory = copy_method(item, "CanBeUsedOutOfInventory"),
        CanOnlyPlayerHeroPickup = copy_method(item, "CanOnlyPlayerHeroPickup"),

        GetCost = copy_method(item, "GetCost"),
        GetCurrentCharges = copy_method(item, "GetCurrentCharges"),
        GetInitialCharges = copy_method(item, "GetInitialCharges"),
        GetItemSlot = copy_method(item, "GetItemSlot"),
        GetItemState = copy_method(item, "GetItemState"),
        GetPurchaseTime = copy_method(item, "GetPurchaseTime"),
        GetSecondaryCharges = copy_method(item, "GetSecondaryCharges"),
        GetValuelessCharges = copy_method(item, "GetValuelessCharges"),

        IsAlertableItem = copy_method(item, "IsAlertableItem"),
        IsCastOnPickup = copy_method(item, "IsCastOnPickup"),
        IsCombinable = copy_method(item, "IsCombinable"),
        IsCombineLocked = copy_method(item, "IsCombineLocked"),
        IsDisassemblable = copy_method(item, "IsDisassemblable"),
        IsDroppable = copy_method(item, "IsDroppable"),
        IsInBackpack = copy_method(item, "IsInBackpack"),
        IsItem = copy_method(item, "IsItem"),
        IsKillable = copy_method(item, "IsKillable"),
        IsMuted = copy_method(item, "IsMuted"),
        IsNeutralDrop = copy_method(item, "IsNeutralDrop"),
        IsPermanent = copy_method(item, "IsPermanent"),
        IsPurchasable = copy_method(item, "IsPurchasable"),
        IsRecipe = copy_method(item, "IsRecipe"),
        IsRecipeGenerated = copy_method(item, "IsRecipeGenerated"),
        IsSellable = copy_method(item, "IsSellable"),
        IsStackable = copy_method(item, "IsStackable"),

        GetName = copy_method(item, "GetAbilityName"), -- CDOTA_Item extends CDOTABaseAbility

        GetEntityIndex = copy_method(item, "GetEntityIndex"),
    }
    return sandboxed
end

if not Sandbox.init then Sandbox:Init() end

GameRules.Sandbox = Sandbox
