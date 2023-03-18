# Dota X CTF Game

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
To setup the map:

1. download the game (dota2), and when download on Steam, right click on the Dota2 -> property there's a option called "DLC", check the `workshop tools DLC`.
2. when start the game, choose workshop tools.
3. create a new custom map, copy this repo to `game/dota_addons/[your map name]/script/vscripts`, not that this repo **is** the vscripts itself.
4. when testing, after launching the tools, choose hammer.
5. open `template_map` (under `content/dota_addons/`, there's a map called `template_map`)
6. `F9` to build.

Also, the content we are using is under [dotaxctf-content repo](https://github.com/escapingbug/dotaxctf-content), you might find that useful to stay consistent with us.

When our game runes, we will be using this setting.
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