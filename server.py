from fastapi import FastAPI
import uvicorn
import os
import base64
import random
import string

curdir = os.path.abspath(os.path.dirname(__file__))


def read_file(path: str) -> str:
    with open(path) as f:
        return f.read()


ROUND = 1
DEFAULT_CHOOSER = read_file(os.path.join(curdir, "bot", "default_chooser.lua"))
DEFAULT_ACTION = read_file(os.path.join(curdir, "bot", "default_action.lua"))

app = FastAPI()

print("init success")


@app.get("/api/ct/admin/xgame/game/init/")
def init():
    req = {
        "code": "AD-000000",
        "data": {
            "teams": [{
                "team_id": str(i + 1),
                "team_name": f"r{i + 1}kapig",
                "score": 500,
                "rank": 1
            } for i in range(16)]
        }
    }
    return req


@app.get("/api/ct/admin/xgame/game/service/")
def service():
    global ROUND
    req = {
        "code": "AD-000000",
        "data": {
            "task_id": ''.join(random.sample(string.ascii_letters + string.digits, 32)),
            "turn": ROUND,
            "teams": [{
                "team_id": str(i + 1),
                "score": 500,
                "select": base64.b64encode(DEFAULT_CHOOSER.encode()).decode(),
                "act": base64.b64encode(DEFAULT_ACTION.encode()).decode(),
                "rank": 1
            } for i in range(16)]
        }
    }
    return req


@app.post("/api/ct/admin/xgame/game/service/")
def service():
    global ROUND
    ROUND += 1
    req = {
        "code": "AD-000000",
    }
    return req


if __name__ == "__main__":
    uvicorn.run("server:app")
