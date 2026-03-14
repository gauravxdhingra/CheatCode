# !/usr/bin/zsh
python -m venv .venv && source cheatcode-api/.venv/bin/activate
pip install -r cheatcode-api/requirements.txt
uvicorn main:app --reload
