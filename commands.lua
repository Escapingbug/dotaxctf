if Commands == nil then
    Commands = class({})
end

function Commands:Init()
    self.inited = true
    self.help = [[
=== xctf 7th dotaxctf ===
x rr - restart the round
x fr - full restart
=== xctf 7th dotaxctf ===
]]

    Convars:RegisterCommand("x", Commands_Main, Commands.help, FCVAR_SPONLY)
end

function Commands_Main(command, operation)
    if operation ~= "rr" and operation ~= "fr" then
        print(Commands.help)
        return
    end
    if operation == "rr" then
        Commands:RoundRestart()
    elseif operation == "fr" then
        Commands:FullRestart()
    end
end

function Commands:FullRestart()
    Timers:RemoveTimer("round_periodic_timer")
    Timers:RemoveTimer("round_limit_timer")
    Sandbox:CleanUpItems()
    Rounds.restarting = true
    Rounds:InitFromServerAndBeginGame()
end

function Commands:RoundRestart()
    Timers:RemoveTimer("round_periodic_timer")
    Timers:RemoveTimer("round_limit_timer")
    Sandbox:CleanUpItems()
    Rounds:PrepareBeginRound()
end

if not Commands.inited then Commands:Init() end
GameRules.Commands = Commands
