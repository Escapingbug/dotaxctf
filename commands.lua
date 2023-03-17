if Commands == nil then
    Commands = class({})
end

function Commands:Init()
    self.inited = true
    self.help = [[
=== xctf 7th dotaxctf ===
x rr - restart the round
=== xctf 7th dotaxctf ===
]]

    Convars:RegisterCommand("x", Commands_Main, Commands.help, FCVAR_SPONLY)
end

function Commands_Main(command, operation)
    if operation ~= "rr" then
        print(Commands.help)
        return
    end
    if operation == "rr" then
        Commands:RoundRestart()
    end
end

-- TODO: implement `x fr` command
-- function Commands:FullRestart()
--     Timers:RemoveTimer("round_periodic_timer")
--     Timers:RemoveTimer("round_limit_timer")
--     Rounds:CleanupLivingHeros()
--     Rounds.initialized = false
--     Rounds:InitFromServerAndBeginGame()
-- end

function Commands:RoundRestart()
    Timers:RemoveTimer("round_periodic_timer")
    Timers:RemoveTimer("round_limit_timer")
    Rounds:PrepareBeginRound()
end

if not Commands.inited then Commands:Init() end
GameRules.Commands = Commands
