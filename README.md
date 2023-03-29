# Dota X CTF Game

## Note

The restricted API set **is expected**.
The game bots are not expected to be fully controllable like a normal Dota game.
It's better focusing on using the existing features.
Most of the lacking APIs are design choices intended.
Feel free to report missing features, but we are not trying to guarantee a complete control environment.
One may see that as part of the game rule itself.

## Rules

Rules you should follow:

This is **not a hacking challenge** but a programming challenge.
(Or, you might think that this should be to exploit the knowledge of the Dota game?)
So, **DO NOT HACK THE INFRASTRUCTURE**.
You will lose points or even get banned because of that.
The infrastructure hacking include: try leverage the infra to get more running time (or any other case of sandbox escaping, the sandbox **is not your target**).

If you find any bug, you could send up a Pull Request to explain and fix that.
You may get extra points because of that.

Have fun, instead of hacking everything, bro!

## How to Play

Read the source code!

This is a Dota2 custom map, the contents here are the `vscripts` directory of the custom map.
To setup and run the map:

1. download the game (dota2), and when downloading on Steam, right click on the Dota2 -> property -> DLC -> check `Dota 2 Workshop Tools DLC`.
2. start the game and choose `Launch Dota 2 - Tools`.
3. create a new custom map
4. copy this repo to `dota2/game/dota_addons/[your map name]/script/vscripts`, note that this repo **is** the vscripts itself.
5. copy [dotaxctf-contents repo](https://github.com/escapingbug/dotaxctf-contents) to `dota2/content/dota_addons/[your map name]`
6. after launching the tools, choose hammer.
7. open `template_map` dotaxctf-contents repo (which is copied to `dota2/content/dota_addons/[your map name]/maps`)
8. `F9` to build with default settings.

When our game runs, we will be using this setting.
The `server.py` is the example server serving example code.
When running the game, the server will accept your scripts.
Each round you will be able to send up the script, and it will be sent back to the client (game) the next round.
All other information should be explored by reading the source code!

## Hints

- [API](https://moddota.com/api/#!/vscripts)

## Devs

- [anciety](https://github.com/escapingbug)
- [liangjs](https://github.com/liangjs)
- [kdxcxs](https://github.com/kdxcxs)
- [xljkqq](https://github.com/xljkqq)

## Changelog

- [2023/3/21 21:13] fix: remove shop and spawn heros as a circle.([#20](https://github.com/Escapingbug/dotaxctf/pull/20))
- [2023/3/21 22:00] feat: support getting hero's candidate id.([#21](https://github.com/Escapingbug/dotaxctf/pull/21))
- [2023/3/23 13:30] fix: remove non-hero units after round ends.([#23](https://github.com/Escapingbug/dotaxctf/pull/23), reporter: AAA剑圣)
- [2023/3/24 00:22] feat: support `GetItemInSlot(slot)` to return a sandboxed item.([#24](https://github.com/Escapingbug/dotaxctf/pull/24), reporter: AAA剑圣)
- [2023/3/27 00:22] feat: support getting game time by `GetGameTime()`.([#28](https://github.com/Escapingbug/dotaxctf/pull/28), reporter: Syclover)
- [2023/3/27 23:53] fix: use `npc:GetEntityIndex()` and `npc:GetTeam()` to avoid unexpect behaviors.([#27](https://github.com/Escapingbug/dotaxctf/pull/27), reporter: 114@x1ct34m)
- [2023/3/28 09:11] fix: ban nonhero units for hero choosing.([#31](https://github.com/Escapingbug/dotaxctf/pull/31),reporter: 114@x1ct34m)
- [2023/3/28 09:16] feat: clean up items when round ends.([#30](https://github.com/Escapingbug/dotaxctf/pull/30))
- [2023/3/29 08:46] fix: place history.scores updates to correct loc.([#32](https://github.com/Escapingbug/dotaxctf/pull/32), reporter: AAA剑圣)
- [2023/3/29 11:18] feat: print with `[Sandbox.candidate_name]` banner to support checking specified hero's log.([#33](https://github.com/Escapingbug/dotaxctf/pull/33))
- [2023/3/29 15:26] feat: print with `[Sandbox.candidate_name.script]` banner when script got an error.([#35](https://github.com/Escapingbug/dotaxctf/pull/35))
- [2023/3/29 21:44] feat: remove all nonempty entities after round ends.([#36](https://github.com/Escapingbug/dotaxctf/pull/36))
