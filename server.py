from typing import List
from fastapi import FastAPI, Query
from pydantic import BaseModel
import uvicorn
import os

curdir = os.path.abspath(os.path.dirname(__file__))

def read_file(path: str) -> str:
    with open(path) as f:
        return f.read()

DEFAULT_CHOOSER = read_file(os.path.join(curdir, "bot", "default_chooser.lua"))
DEFAULT_ACTION = read_file(os.path.join(curdir, "bot", "default_action.lua"))

app = FastAPI()  

team_nums = [i for i in range(1, 17)]
print("init success")


class ScoreThisRound(BaseModel):
    scores: List[int]
    round_count: int


@app.post('/scores')
async def test_post(
    scores_this_round: ScoreThisRound,
    token: str = Query(None, title='token', max_length=20),
):
    if token != "THISISDEMO":
        return None
    print(f"got score: {scores_this_round}")


@app.get("/scripts")
def req_script(token: str):
    if token != "THISISDEMO":
        return None
    req = {}

    for team_num in team_nums:
        req[team_num] = {
            "team_name": f"r{team_num}kapig",
            "choose_hero": DEFAULT_CHOOSER,
            "action": DEFAULT_ACTION,
            "attribute": {
                "strength": 20,
                "intelligence": 20,
                "agility": 20,
                "gold": 3000,
                "experience": 1000,
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


if __name__ == "__main__":
    uvicorn.run("server:app")
