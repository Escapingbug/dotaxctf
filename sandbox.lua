if Sandbox == nil then
    Sandbox = class({})
end

function Sandbox:LoadChooseHeroScript(user_script)
    -- TODO: real sandbox
    return load(user_script)
end

function Sandbox:LoadActionScript(user_script)
    -- TODO: real sandbox
    return load(user_script)
end

function Sandbox:SandboxEntity(entity)
    -- TODO: real sandbox
    return entity
end

function Sandbox:RunChooseHero(choose_func, round_count)
    -- TODO: real sandbox
    return choose_func(round_count)
end

function Sandbox:RunAction(act_func, entity, ctx)
    -- TODO: real sandbox
    local sandboxed_entity = Sandbox:SandboxEntity(entity)
    return act_func(sandboxed_entity, ctx)
end

GameRules.Sandbox = Sandbox
