if BotScriptEnv == nil then
    BotScriptEnv = class({})
    BotScript = class({})
end

function BotScript:Init(script_content)
    print("bot script: " .. script_content)
    self.run_bot = Sandbox:LoadActionScript(script_content)
    self.ctx = {}
end

function BotScript:OnThink(entity)
    self.ctx = Sandbox:RunAction(self.run_bot, entity, self.ctx)
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
