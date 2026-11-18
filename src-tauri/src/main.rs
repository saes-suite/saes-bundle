// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::net::{SocketAddr, TcpStream};
use std::process::{Child, Command, Stdio};
use std::sync::Mutex;
use std::time::Duration;
use tauri::{Manager, RunEvent};

#[cfg(windows)]
use std::os::windows::process::CommandExt;

struct BackendProcess(Mutex<Option<Child>>);

fn is_port_listening(port: u16) -> bool {
    let addr = SocketAddr::from(([127, 0, 0, 1], port));
    TcpStream::connect_timeout(&addr, Duration::from_millis(150)).is_ok()
}

fn spawn_backend(app: &tauri::App) -> Result<Child, Box<dyn std::error::Error>> {
    let exe_name = if cfg!(windows) {
        "saes-backend.exe"
    } else {
        "saes-backend"
    };

    let resource_bin = app
        .path()
        .resource_dir()
        .map(|d| d.join("binaries").join("saes-backend").join(exe_name))
        .ok();

    let dev_bin = std::env::current_dir()
        .map(|d| d.join("binaries").join("saes-backend").join(exe_name))
        .ok();

    let bin_path = [resource_bin, dev_bin]
        .into_iter()
        .flatten()
        .find(|p| p.exists())
        .ok_or("saes-backend executable not found in resource_dir or binaries/")?;

    let datasets_dir = app
        .path()
        .app_data_dir()
        .map(|p| p.join("datasets"))
        .unwrap_or_else(|_| std::env::temp_dir().join("saes-datasets"));
    let _ = std::fs::create_dir_all(&datasets_dir);

    let mut cmd = Command::new(&bin_path);
    cmd.env("SAES_DATASETS_DIR", datasets_dir.to_string_lossy().as_ref())
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null());

    #[cfg(windows)]
    {
        const CREATE_NO_WINDOW: u32 = 0x08000000;
        cmd.creation_flags(CREATE_NO_WINDOW);
    }

    Ok(cmd.spawn()?)
}

fn main() {
    let app = tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_shell::init())
        .manage(BackendProcess(Mutex::new(None)))
        .setup(|app| {
            let skip_sidecar = std::env::var("SAES_NO_SIDECAR").as_deref() == Ok("1")
                || is_port_listening(8060);

            if !skip_sidecar {
                match spawn_backend(app) {
                    Ok(child) => {
                        if let Some(state) = app.try_state::<BackendProcess>() {
                            if let Ok(mut guard) = state.0.lock() {
                                *guard = Some(child);
                            }
                        }
                    }
                    Err(err) => {
                        eprintln!("[saes-desktop] failed to spawn saes-backend: {err}");
                    }
                }
            }

            Ok(())
        })
        .build(tauri::generate_context!())
        .expect("error while building saes desktop application");

    app.run(|app_handle, event| {
        if let RunEvent::Exit = event {
            if let Some(state) = app_handle.try_state::<BackendProcess>() {
                if let Ok(mut guard) = state.0.lock() {
                    if let Some(mut child) = guard.take() {
                        let _ = child.kill();
                        let _ = child.wait();
                    }
                }
            }
        }
    });
}
