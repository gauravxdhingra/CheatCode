from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import feed, progress, users, answers

app = FastAPI(
    title="cheatcode() API",
    description="Unfair advantage for technical interviews.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router)
app.include_router(feed.router)
app.include_router(progress.router)
app.include_router(answers.router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "cheatcode-api"}
