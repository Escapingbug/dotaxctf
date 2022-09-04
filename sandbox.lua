lua_sandbox = require("lib/lua-sandbox/sandbox")

if Sandbox == nil then
    Sandbox = class({})
end

local constants = {
    -- DOTA_UNIT_TARGET_TEAM
    DOTA_UNIT_TARGET_TEAM_NONE = 0,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY = 1,
    DOTA_UNIT_TARGET_TEAM_ENEMY = 2,
    DOTA_UNIT_TARGET_TEAM_BOTH = 3,
    DOTA_UNIT_TARGET_TEAM_CUSTOM = 4,

    -- DOTA_UNIT_TARGET_TYPE
    DOTA_UNIT_TARGET_NONE = 0,
    DOTA_UNIT_TARGET_HERO = 1,
    DOTA_UNIT_TARGET_CREEP = 2,
    DOTA_UNIT_TARGET_BUILDING = 4,
    DOTA_UNIT_TARGET_COURIER = 16,
    DOTA_UNIT_TARGET_BASIC = 18,
    DOTA_UNIT_TARGET_OTHER = 32,
    DOTA_UNIT_TARGET_ALL = 55,
    DOTA_UNIT_TARGET_TREE = 64,
    DOTA_UNIT_TARGET_CUSTOM = 128,

    -- DOTA_UNIT_TARGET_FLAGS
    DOTA_UNIT_TARGET_FLAG_NONE = 0,
    DOTA_UNIT_TARGET_FLAG_RANGED_ONLY = 2,
    DOTA_UNIT_TARGET_FLAG_MELEE_ONLY = 4,
    DOTA_UNIT_TARGET_FLAG_DEAD = 8,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES = 16,
    DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES = 32,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE = 64,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE = 128,
    DOTA_UNIT_TARGET_FLAG_NO_INVIS = 256,
    DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS = 512,
    DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED = 1024,
    DOTA_UNIT_TARGET_FLAG_NOT_DOMINATED = 2048,
    DOTA_UNIT_TARGET_FLAG_NOT_SUMMONED = 4096,
    DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS = 8192,
    DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE = 16384,
    DOTA_UNIT_TARGET_FLAG_MANA_ONLY = 32768,
    DOTA_UNIT_TARGET_FLAG_CHECK_DISABLE_HELP = 65536,
    DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO = 131072,
    DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD = 262144,
    DOTA_UNIT_TARGET_FLAG_NOT_NIGHTMARED = 524288,
    DOTA_UNIT_TARGET_FLAG_PREFER_ENEMIES = 1048576,
    DOTA_UNIT_TARGET_FLAG_RESPECT_OBSTRUCTIONS = 2097152,

    -- dotaunitorder_t
    DOTA_UNIT_ORDER_MOVE_TO_TARGET = 2,
    DOTA_UNIT_ORDER_ATTACK_TARGET = 4,
    DOTA_UNIT_ORDER_CAST_TARGET = 6,
    DOTA_UNIT_ORDER_CAST_TARGET_TREE = 7,
    DOTA_UNIT_ORDER_CAST_NO_TARGET = 8,
    DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION = 30,
    DOTA_UNIT_ORDER_VECTOR_TARGET_CANCELED = 34,

    -- FindOrder
    FIND_ANY_ORDER = 0,
    FIND_CLOSEST = 1,
    FIND_FARTHEST = 2,
}

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
    return self:LoadScript(user_script, 100000, {
        game_info = self.game_info
    })
end

function Sandbox:LoadActionScript(user_script)
    env = {
        game_info = self.game_info
    }
    for k, v in pairs(self.public_api) do
        env[k] = v
    end
    return self:LoadScript(user_script, 500000, env)
end

function Sandbox:RunChooseHero(choose_func, round_count)
    local hero_name = self:RunFunctionWrap(choose_func, round_count)
    if type(hero_name) ~= "string" then
        hero_name = self.default_hero
    end
    return hero_name
end

function Sandbox:RunAction(act_func, entity, ctx)
    local sandboxed_entity = self:SandboxHero(entity)
    local new_ctx = self:RunFunctionWrap(act_func, sandboxed_entity, ctx)
    return new_ctx
end

function Sandbox:SandboxPublicAPI()
    -- TODO
    return {
        Vector = Vector,
    }
end

function Sandbox:SandboxHero(hero)

    local get_entity_index = function ()
        return hero:GetEntityIndex()
    end

    local get_position = function ()
        return hero:GetAbsOrigin()
    end

    local get_team = function ()
        return hero:GetTeam()
    end

    local is_attacking = function ()
        return hero:IsAttacking()
    end

    local find_units_in_radius = function (
        location,
        radius,
        team_filter,
        type_filter,
        flag_filter,
        find_order
    )
        local units = FindUnitsInRadius(
            hero:GetTeam(),
            location,
            nil,
            radius,
            team_filter,
            type_filter,
            flag_filter,
            find_order,
            false
        )
        local sandboxed_units = {}

        for _, unit in ipairs(units) do
            table.insert(sandboxed_units, Sandbox:SandboxHero(unit))
        end
        return sandboxed_units
    end

    local execute_order = function (
        order_type,
        target_index,
        ability_index,
        position,
        queue
    )
        local unit_index = hero:GetEntityIndex()
        local order = {
            UnitIndex = unit_index,
            OrderType = order_type,
            TargetIndex = target_index,
            AbilityIndex = ability_index,
            Position = position,
            Queue = queue
        }

        ExecuteOrderFromTable(order)
    end

    
    local sandboxed = {
        constants = constants,
        get_entity_index = get_entity_index,
        get_position = get_position,
        get_team = get_team,
        is_attacking = is_attacking,
        find_units_in_radius = find_units_in_radius,
        execute_order = execute_order
    }
    -- TODO
    return sandboxed
end

if not Sandbox.init then Sandbox:Init() end

GameRules.Sandbox = Sandbox
