#!/usr/bin/env python3
"""Build the unified SAES Python backend sidecar binary using PyInstaller.

Places the resulting executable in:
    src-tauri/binaries/saes-backend-<target-triple>[.exe]
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGING_DIR = ROOT / "packaging"
BINARIES_DIR = ROOT / "src-tauri" / "binaries"
VENV_DIR = PACKAGING_DIR / ".venv"


def detect_target_triple() -> str:
    """Detect the host Rust target triple via `rustc -vV`."""
    out = subprocess.check_output(["rustc", "-vV"], text=True)
    for line in out.splitlines():
        if line.startswith("host:"):
            return line.split(":", 1)[1].strip()
    raise RuntimeError("Could not detect Rust host target triple from `rustc -vV`.")


def venv_python() -> Path:
    if sys.platform == "win32":
        return VENV_DIR / "Scripts" / "python.exe"
    return VENV_DIR / "bin" / "python"


def ensure_build_venv() -> Path:
    """Create/update packaging/.venv with saesV2, saes-ai, and pyinstaller."""
    py = venv_python()
    if not py.exists():
        print(f"Creating build venv at {VENV_DIR}...")
        subprocess.run(["uv", "venv", str(VENV_DIR), "--python", "3.12"], check=True)

    print("Installing saesV2[viz,api], saes-ai[providers], and pyinstaller into build venv...")
    subprocess.run(
        [
            "uv",
            "pip",
            "install",
            "--python",
            str(py),
            "-e",
            f"{ROOT / 'saesV2'}[viz,api]",
            "-e",
            f"{ROOT / 'saes-ai'}[providers]",
            "pyinstaller>=6.10.0",
        ],
        check=True,
    )
    return py


def build_sidecar(target: str, skip_install: bool = False) -> Path:
    py = venv_python() if skip_install and venv_python().exists() else ensure_build_venv()

    is_windows = "windows" in target or sys.platform == "win32"
    ext = ".exe" if is_windows else ""
    binary_name = "saes-backend"
    dist_dir = PACKAGING_DIR / "dist"
    work_dir = PACKAGING_DIR / "build"

    cmd = [
        str(py),
        "-m",
        "PyInstaller",
        "--onedir",
        "--noconfirm",
        "--clean",
        "--name",
        binary_name,
        "--distpath",
        str(dist_dir),
        "--workpath",
        str(work_dir),
        "--specpath",
        str(work_dir),
        "--paths",
        str(ROOT / "saesV2" / "src"),
        "--paths",
        str(ROOT / "saes-ai" / "src"),
        "--collect-all",
        "saesV2",
        "--collect-all",
        "saes_ai",
        "--collect-all",
        "tabulate",
        "--hidden-import",
        "uvicorn.logging",
        "--hidden-import",
        "uvicorn.loops",
        "--hidden-import",
        "uvicorn.loops.auto",
        "--hidden-import",
        "uvicorn.protocols",
        "--hidden-import",
        "uvicorn.protocols.http",
        "--hidden-import",
        "uvicorn.protocols.http.auto",
        "--hidden-import",
        "uvicorn.protocols.websockets",
        "--hidden-import",
        "uvicorn.protocols.websockets.auto",
        "--hidden-import",
        "uvicorn.lifespan",
        "--hidden-import",
        "uvicorn.lifespan.on",
        "--hidden-import",
        "multipart",
        "--hidden-import",
        "python_multipart",
        "--hidden-import",
        "anthropic",
        "--hidden-import",
        "openai",
    ]

    if is_windows:
        cmd.append("--noconsole")

    # On macOS, pass --target-arch when cross-compiling (e.g., x86_64 on arm64 runner)
    if "apple-darwin" in target:
        arch = "arm64" if target.startswith("aarch64") else "x86_64"
        cmd.extend(["--target-arch", arch])

    cmd.append(str(PACKAGING_DIR / "backend_entry.py"))

    print(f"Running PyInstaller for target={target}...")
    env = os.environ.copy()
    env.setdefault("PYINSTALLER_CONFIG_DIR", str(work_dir / ".pyinstaller"))
    subprocess.run(cmd, cwd=str(ROOT), env=env, check=True)

    built_dir = dist_dir / binary_name
    built_bin = built_dir / f"{binary_name}{ext}"
    if not built_bin.exists():
        raise FileNotFoundError(f"Expected PyInstaller output not found: {built_bin}")

    dest_dir = BINARIES_DIR / binary_name
    if dest_dir.exists():
        shutil.rmtree(dest_dir)
    BINARIES_DIR.mkdir(parents=True, exist_ok=True)
    shutil.copytree(built_dir, dest_dir, symlinks=True)

    dest_bin = dest_dir / f"{binary_name}{ext}"
    if not is_windows:
        dest_bin.chmod(0o755)

    print(f"✅ Sidecar directory ready at: {dest_dir}")
    return dest_bin


def main() -> None:
    parser = argparse.ArgumentParser(description="Build SAES unified Python backend sidecar")
    parser.add_argument("--target", default=None, help="Rust target triple (defaults to host)")
    parser.add_argument("--skip-install", action="store_true", help="Skip uv pip install step")
    args = parser.parse_args()

    target = args.target or detect_target_triple()
    build_sidecar(target, skip_install=args.skip_install)


if __name__ == "__main__":
    main()
