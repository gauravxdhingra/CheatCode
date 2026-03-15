import logging
import time
import uuid
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from routers import feed, progress, users, answers

# ── Logging setup ─────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("cheatcode")

# ── App ───────────────────────────────────────────────────────────────────────

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

# ── Request logging middleware ────────────────────────────────────────────────

@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = str(uuid.uuid4())[:8]
    start = time.time()

    logger.info(
        f"→ [{request_id}] {request.method} {request.url.path}"
        + (f"?{request.url.query}" if request.url.query else "")
    )

    try:
        response = await call_next(request)
        duration_ms = round((time.time() - start) * 1000)
        level = logging.WARNING if response.status_code >= 400 else logging.INFO
        logger.log(
            level,
            f"← [{request_id}] {response.status_code} ({duration_ms}ms)"
        )
        return response
    except Exception as exc:
        duration_ms = round((time.time() - start) * 1000)
        logger.error(
            f"✗ [{request_id}] UNHANDLED ERROR ({duration_ms}ms): {exc}",
            exc_info=True,
        )
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error", "request_id": request_id},
        )

# ── Routers ───────────────────────────────────────────────────────────────────

app.include_router(users.router)
app.include_router(feed.router)
app.include_router(progress.router)
app.include_router(answers.router)

# ── Health ────────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    logger.info("Health check OK")
    return {"status": "ok", "service": "cheatcode-api", "version": "1.0.0"}

# ── Startup ───────────────────────────────────────────────────────────────────

@app.on_event("startup")
async def startup():
    logger.info("🚀 cheatcode-api starting up")
    logger.info("Routers: /users /feed /progress /answers /health")
