lua_sandbox = require("lib/lua-sandbox/sandbox")

if Sandbox == nil then
    Sandbox = class({})
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

function Sandbox:SandboxPublicAPI(entity)
    -- TODO
    return {
        Vector = Vector,
    }
end

function Sandbox:SandboxHero(hero)
    -- TODO
    return hero
end

if not Sandbox.init then Sandbox:Init() end

GameRules.Sandbox = Sandbox
