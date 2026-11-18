"""Unified sidecar entrypoint for SAES Desktop.

Runs both the SAES statistical REST API (:8060, with mounted AI routes)
and the standalone SAES-AI REST API (:8070) inside a single process so
Tauri can manage the entire Python backend as one sidecar binary.
"""

from __future__ import annotations

import asyncio
import os
import signal
import sys
from pathlib import Path


def _ensure_safe_stdio() -> None:
    """Ensure sys.stdout and sys.stderr are valid streams (e.g. Windows --noconsole)."""
    if sys.stdout is None:
        sys.stdout = open(os.devnull, "w", encoding="utf-8")
    if sys.stderr is None:
        sys.stderr = open(os.devnull, "w", encoding="utf-8")


def _ensure_datasets_dir() -> None:
    """Default SAES_DATASETS_DIR and MPLCONFIGDIR to writable user directories."""
    if not os.getenv("SAES_DATASETS_DIR"):
        default_dir = Path.home() / ".saes" / "datasets"
        default_dir.mkdir(parents=True, exist_ok=True)
        os.environ["SAES_DATASETS_DIR"] = str(default_dir)
    if not os.getenv("MPLCONFIGDIR"):
        mpl_dir = Path(os.environ["SAES_DATASETS_DIR"]).parent / ".mplconfig"
        mpl_dir.mkdir(parents=True, exist_ok=True)
        os.environ["MPLCONFIGDIR"] = str(mpl_dir)


async def _serve_all(host: str, api_port: int, ai_port: int) -> None:
    import uvicorn

    from saes_ai.server.app import app as ai_app
    from saes_ai.server.routes import router as ai_router
    from saesV2.server.app import app as api_app

    # Ensure SAES-AI routes are mounted on :8060 even when frozen with PyInstaller
    if "/api/v1/chat/probe" not in api_app.openapi().get("paths", {}):
        api_app.include_router(ai_router)

    api_config = uvicorn.Config(
        api_app,
        host=host,
        port=api_port,
        log_level="info",
        access_log=False,
    )
    ai_config = uvicorn.Config(
        ai_app,
        host=host,
        port=ai_port,
        log_level="info",
        access_log=False,
    )

    api_server = uvicorn.Server(api_config)
    ai_server = uvicorn.Server(ai_config)

    # Disable uvicorn's own signal handlers so we coordinate shutdown of both servers
    api_server.install_signal_handlers = lambda: None  # type: ignore[method-assign]
    ai_server.install_signal_handlers = lambda: None  # type: ignore[method-assign]

    def _shutdown(*_args: object) -> None:
        api_server.should_exit = True
        ai_server.should_exit = True

    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            signal.signal(sig, _shutdown)
        except (ValueError, OSError):
            pass

    await asyncio.gather(api_server.serve(), ai_server.serve())


def main() -> None:
    _ensure_safe_stdio()
    _ensure_datasets_dir()
    os.environ.setdefault("MPLBACKEND", "Agg")

    host = os.getenv("SAES_HOST", "127.0.0.1")
    api_port = int(os.getenv("SAES_API_PORT", "8060"))
    ai_port = int(os.getenv("SAES_AI_PORT", "8070"))

    asyncio.run(_serve_all(host, api_port, ai_port))


if __name__ == "__main__":
    main()
