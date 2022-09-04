
import sqlite3
from tokenize import String
from fastapi import FastAPI, Body, Query, Request
from fastapi.responses import JSONResponse
from typing import Optional
from fastapi.exceptions import RequestValidationError
from numpy import choose
from sqlalchemy import null
import uvicorn
import json
import os
import base64
from sqlite3 import *

app = FastAPI()  

team_nums = [19, 20]
conn = sqlite3.connect("/tmp/scores.db")
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
c.close()
conn.close()
print("init success")

@app.exception_handler(RequestValidationError)
async def post_validation_exception_handler(request: Request, exc: RequestValidationError):

    print(f'argument error{request.method},{request.url}')
    return JSONResponse({'code': 400, 'msg': exc.errors()})


@app.post('/submit_scores')
async def test_post(
        token: Optional[str] = Body(None, title='token', max_length=20),
        team_num: Optional[str] = Body(None, title='team_num', max_length=20),
        scores_this_round: Optional[int] = Body(None, title='scores_this_round'),
):
    if token != "THISISDEMO":
        return null
    conn = sqlite3.connect("/tmp/scores.db")
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
    
    c.close()
    conn.close()

@app.get("/get_script")
def req_script(token: str):
    if token != "THISISDEMO":
        return null
    req = {}

    for team_num in team_nums:
        choose_hero_script = str(team_num) + "_choose_hero.lua"
        bot_script = str(team_num) + "_action.lua"
        
        b64_choose_code = null
        b64_bot_code = null
        if os.access(choose_hero_script, os.F_OK):    
            with open(choose_hero_script, "rb") as fd:
                choose_hero_code = fd.read(-1)
            b64_choose_code = base64.b64encode(choose_hero_code)

        if os.access(bot_script, os.F_OK):
            with open(bot_script, "rb") as fd:
                bot_code = fd.read(-1)
            b64_bot_code = base64.b64encode(bot_code)

        req[team_num] = {"choose_hero": b64_choose_code, "action": b64_bot_code, "attribute": {"strength": 20, "intelligence": 20, "agility": 20}}
    
    print(req)
    return req

# @app.get("/")
# def req_script(token: str):
#     choose_hero_script = token + "_choose_hero.lua"
#     bot_script = token + "_action.lua"
    
#     b64_choose_code = null
#     b64_bot_code = null
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