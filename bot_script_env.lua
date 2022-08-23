if BotScriptEnv == nil then
    BotScriptEnv = class({})
    BotScript = class({})
end

function BotScript:Init(script_content)
    local run_bot_func = load(script_content)
    if run_bot_func then
        print("got run bot")
        self.run_bot = run_bot_func()
    else
        print("run bot func is nil!!")
        self.run_bot = nil
    end
end

function BotScript:Sandbox(entity)
    -- TODO: liangjs will sandbox you!
    return entity
end

function BotScript:OnThink(entity)
    if not self.run_bot then
        return
    end

    local sandboxed_entity = self:Sandbox(entity)
    self.run_bot(sandboxed_entity)
    return 0.1
end

function BotScriptEnv:AttachScriptOnUnit(unit, script_string)
    print("attaching to unit " .. tostring(unit))
    if not unit then
        print("no unit")
        return
    end

    local bot_script = BotScript()
    bot_script:Init(script_string)
    unit:SetThink("OnThink", bot_script)
end

GameRules.BotScriptEnv = BotScriptEnv