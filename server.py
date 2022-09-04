import sqlite3
from fastapi import FastAPI, Body, Request, Query
from fastapi.responses import JSONResponse
from typing import Optional
from fastapi.exceptions import RequestValidationError

DEFAULT_CHOOSER = """
local round = GetRoundCount()
return "npc_dota_hero_bloodseeker"
"""

DEFAULT_ACTION = """
local hero, ctx = ...
local round = GetRoundCount()
ability_count = hero:GetAbilityCount()
for i = 0, ability_count-1 do
    local ability = hero:GetAbilityByIndex(i)
    if ability then
        -- print("ability name", ability:GetAbilityName())
        -- print("level", ability:GetLevel())
        -- print("Behavior", ability:GetBehavior())
        -- print("AOE Radius", ability:GetAOERadius())
        -- print("channel cost", ability:GetChannelledManaCostPerSecond(ability:GetLevel()))
        -- print("channel time", ability:GetChannelTime())
        -- print("cast range", ability:GetEffectiveCastRange(hero:GetAbsOrigin(), nil))
        -- print("cool down", ability:GetEffectiveCooldown(ability:GetLevel()))
        -- print("mana cost", ability:GetManaCost(ability:GetLevel()))
        -- print("toggle", ability:GetToggleState())
        -- print("is item", ability:IsItem())
        -- print("duration", ability:GetDuration())
    end
end

if hero:IsAttacking() then
    return ctx
end


DOTA_UNIT_TARGET_TEAM_ENEMY = 2
DOTA_UNIT_TARGET_HERO = 1
DOTA_UNIT_TARGET_FLAG_NONE = 0
FIND_ANY_ORDER = 0
DOTA_UNIT_ORDER_ATTACK_TARGET = 4

local units = hero:FindUnitsInRadius(
    hero:GetAbsOrigin(),
    3000,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER
)
if #units > 0 then
    hero:ExecuteOrder(
        DOTA_UNIT_ORDER_ATTACK_TARGET,
        units[1].GetEntityIndex(),
        nil,
        nil,
        false
    )
end

return ctx
"""

app = FastAPI()  

team_nums = [19, 20]
conn = sqlite3.connect(":memory:")
c = conn.cursor()
try:
    c.execute('''CREATE TABLE SCORE
    (team_num int PRIMARY KEY NOT NULL,
    scores int not null);
    ''')
    
    for i in team_nums:
        try:
            c.execute('''INSERT INTO SCORE (team_num, scores) VALUES('%d', 0)''' % (i))
        except:
            print("[-] Init insert error")
except:
    print("[-] Init create database error")

conn.commit()
print("init success")

@app.exception_handler(RequestValidationError)
async def post_validation_exception_handler(request: Request, exc: RequestValidationError):

    print(f'参数不对{request.method},{request.url}')
    return JSONResponse({'code': 400, 'msg': exc.errors()})


@app.post('/scores')
async def test_post(
        token: Optional[str] = Query(None, title='token', max_length=20),
        team_num: Optional[str] = Body(None, title='team_num', max_length=20),
        scores_this_round: Optional[int] = Body(None, title='scores_this_round'),
):
    global conn
    if token != "THISISDEMO":
        return None
    c = conn.cursor()

    cursor = conn.execute("SELECT team_num, scores from SCORE;")
    scores = cursor.fetchall()

    cur_score = 0
    for line in scores:
        if line[0] == int(team_num):
            cur_score = line[1]
            score = cur_score + scores_this_round
            c.execute("update SCORE set scores=%d where team_num='%d';" % (score, int(team_num)))
            break
    
    conn.commit()

@app.get("/scripts")
def req_script(token: str):
    if token != "THISISDEMO":
        return None
    req = {}

    for team_num in team_nums:
        req[team_num] = {
            "choose_hero": DEFAULT_CHOOSER,
            "action": DEFAULT_ACTION,
            "attribute": {
                "strength": 20,
                "intelligence": 20,
                "agility": 20
            }
        }
    
    print(req)
    return req

# @app.get("/")
# def req_script(token: str):
#     choose_hero_script = token + "_choose_hero.lua"
#     bot_script = token + "_action.lua"
    
#     b64_choose_code = None 
#     b64_bot_code = None
#     if os.access(choose_hero_script, os.F_OK):    
#         with open(choose_hero_script, "rb") as fd:
#             choose_hero_code = fd.read(-1)
#         b64_choose_code = base64.b64encode(choose_hero_code)

#     if os.access(bot_script, os.F_OK):
#         with open(bot_script, "rb") as fd:
#             bot_code = fd.read(-1)
#         b64_bot_code = base64.b64encode(bot_code)
    
    
#     req = {"choose_hero": b64_choose_code, "action": b64_bot_code, "attribute": {"strength": 20, "intelligence": 20, "agility": 20}}
#     return req