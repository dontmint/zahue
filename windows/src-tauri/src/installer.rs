use crate::asar;
use crate::css::{self, ASSET_DIR_NAME, STATE_FILE};
use crate::theme::{InstallerStatus, Theme};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum InstallerError {
    #[error("{0}")]
    Failed(String),
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error(transparent)]
    Asar(#[from] asar::AsarError),
    #[error(transparent)]
    Css(#[from] css::CssError),
    #[error(transparent)]
    Json(#[from] serde_json::Error),
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct InstalledState {
    theme_id: Option<String>,
    theme_name: Option<String>,
    mode: Option<String>,
    font_family: Option<String>,
    font_weight: Option<i32>,
    font_size_percent: Option<i32>,
}

pub fn status(zalo_path: &str, themes: &[Theme], log: &mut String) -> InstallerStatus {
    log_line(log, &format!("[native] status {zalo_path}"));
    let mut status = InstallerStatus {
        zalo_path: zalo_path.to_string(),
        theme_count: themes.len(),
        ..InstallerStatus::default()
    };
    status.zalo_path = zalo_path.to_string();
    status.zalo_exists = is_dir(zalo_path);
    status.theme_count = themes.len();

    if !status.zalo_exists {
        return status;
    }

    let resources = resources_dir(Path::new(zalo_path));
    let app_asar = resources.join("app.asar");
    let bak = resources.join("app.asar.bak");
    status.app_asar_is_directory = is_dir(app_asar.to_str().unwrap_or(""));
    status.has_backup = is_file(bak.to_str().unwrap_or(""));

    if let Some(state) = read_installed_state(&app_asar) {
        status.theme_id = state.theme_id;
        status.theme_name = state.theme_name;
        status.font_family = state.font_family;
        status.font_weight = state.font_weight;
        status.font_size_percent = state.font_size_percent;
        status.themed = true;
    }
    status
}

pub fn apply(
    theme: &Theme,
    zalo_path: &str,
    font_family: &str,
    font_weight: i32,
    font_size_percent: i32,
    log: &mut String,
) -> Result<(), InstallerError> {
    let resources = resources_dir(Path::new(zalo_path));
    let app_asar = resources.join("app.asar");
    let bak = resources.join("app.asar.bak");
    let tmp_root = tmp_root();
    let extract = tmp_root.join("app");

    if !(is_file_path(&app_asar) || is_dir_path(&app_asar) || is_file_path(&bak)) {
        return Err(InstallerError::Failed(format!(
            "Neither app.asar nor app.asar.bak found in {}",
            resources.display()
        )));
    }

    quit_zalo(log);

    // Fast path: already unpacked + themed (or backup exists)
    if is_dir_path(&app_asar)
        && (read_installed_state(&app_asar).is_some() || is_file_path(&bak))
    {
        log_line(
            log,
            "[info] Updating theme assets in existing unpacked app.asar",
        );
        write_theme_assets(
            &app_asar,
            theme,
            font_family,
            font_weight,
            font_size_percent,
            log,
        )?;
        css::patch_index_html(&app_asar, &theme.id)?;
        log_line(
            log,
            &format!(
                "[info] Patched {}",
                app_asar.join("pc-dist/index.html").display()
            ),
        );
        log_line(
            log,
            &format!(
                "{{\"ok\":true,\"action\":\"switch\",\"themeId\":\"{}\"}}",
                theme.id
            ),
        );
        log_line(
            log,
            &format!("\nDone. Applied {}. Open Zalo PC.", theme.name),
        );
        return Ok(());
    }

    if is_dir_path(&tmp_root) {
        let _ = fs::remove_dir_all(&tmp_root);
    }
    if is_dir_path(&app_asar) {
        log_line(
            log,
            &format!(
                "[info] Removing previous unpacked install: {}",
                app_asar.display()
            ),
        );
        fs::remove_dir_all(&app_asar)?;
    }
    if is_file_path(&bak) {
        if is_file_path(&app_asar) {
            fs::remove_file(&app_asar)?;
        }
        log_line(log, "[info] Restoring original app.asar from app.asar.bak");
        fs::rename(&bak, &app_asar)?;
    }
    if !is_file_path(&app_asar) {
        return Err(InstallerError::Failed(format!(
            "app.asar missing at {}",
            app_asar.display()
        )));
    }

    fs::create_dir_all(&tmp_root)?;
    log_line(log, &format!("[info] Extracting {}", app_asar.display()));
    asar::extract_all(&app_asar, &extract)?;
    write_theme_assets(
        &extract,
        theme,
        font_family,
        font_weight,
        font_size_percent,
        log,
    )?;
    css::patch_index_html(&extract, &theme.id)?;
    log_line(
        log,
        &format!(
            "[info] Patched {}",
            extract.join("pc-dist/index.html").display()
        ),
    );

    if !is_file_path(&bak) {
        fs::rename(&app_asar, &bak)?;
        log_line(log, &format!("[info] Backup created: {}", bak.display()));
    } else if is_file_path(&app_asar) {
        fs::remove_file(&app_asar)?;
    }

    fs::rename(&extract, &app_asar)?;
    let _ = fs::remove_dir_all(&tmp_root);
    log_line(
        log,
        &format!(
            "{{\"ok\":true,\"action\":\"install\",\"themeId\":\"{}\"}}",
            theme.id
        ),
    );
    log_line(
        log,
        &format!("\nDone. Applied {}. Open Zalo PC.", theme.name),
    );
    if theme.is_light() {
        log_line(
            log,
            "Tip: set Zalo appearance to Light for light themes.",
        );
    }
    Ok(())
}

pub fn restore(zalo_path: &str, log: &mut String) -> Result<(), InstallerError> {
    let resources = resources_dir(Path::new(zalo_path));
    let app_asar = resources.join("app.asar");
    let bak = resources.join("app.asar.bak");
    if !is_file_path(&bak) {
        return Err(InstallerError::Failed(
            "No app.asar.bak found. Reinstall Zalo PC to restore.".into(),
        ));
    }
    quit_zalo(log);
    if app_asar.exists() {
        if is_dir_path(&app_asar) {
            fs::remove_dir_all(&app_asar)?;
        } else {
            fs::remove_file(&app_asar)?;
        }
    }
    fs::rename(&bak, &app_asar)?;
    log_line(log, r#"{"ok":true,"action":"uninstall","themeId":null}"#);
    log_line(log, "\nRestored original app.asar. Open Zalo PC.");
    Ok(())
}

fn write_theme_assets(
    app_root: &Path,
    theme: &Theme,
    font_family: &str,
    font_weight: i32,
    font_size_percent: i32,
    log: &mut String,
) -> Result<(), InstallerError> {
    let dest = app_root.join("pc-dist").join(ASSET_DIR_NAME);
    fs::create_dir_all(&dest)?;
    let size_percent = font_size_percent.clamp(80, 200);
    let family = if font_family.is_empty() {
        "Maple Mono"
    } else {
        font_family
    };
    let weight = if font_weight == 0 { 600 } else { font_weight };

    let css_text = css::build_css(theme, family, weight, size_percent);
    let js_text = css::build_js(&theme.id);
    fs::write(dest.join("theme.css"), css_text)?;
    fs::write(dest.join("theme.js"), js_text)?;

    let state = serde_json::json!({
        "themeId": theme.id,
        "themeName": theme.name,
        "mode": theme.mode,
        "fontFamily": family,
        "fontWeight": weight,
        "fontSizePercent": size_percent,
        "installedAt": chrono::Utc::now().to_rfc3339(),
        "tool": "zahue",
        "source": "native-rust"
    });
    fs::write(
        dest.join(STATE_FILE),
        serde_json::to_string_pretty(&state)?,
    )?;

    let legacy = app_root.join("pc-dist/zalo-maple-dawn");
    if is_dir_path(&legacy) {
        let _ = fs::remove_dir_all(&legacy);
    }
    log_line(
        log,
        &format!(
            "[info] Copied theme assets → {} ({}, font={} {}, size={}%)",
            dest.display(),
            theme.id,
            family,
            weight,
            size_percent
        ),
    );
    Ok(())
}

fn read_installed_state(app_asar: &Path) -> Option<InstalledState> {
    if !is_dir_path(app_asar) {
        return None;
    }
    let state_path = app_asar
        .join("pc-dist")
        .join(ASSET_DIR_NAME)
        .join(STATE_FILE);
    if is_file_path(&state_path) {
        if let Ok(data) = fs::read(&state_path) {
            if let Ok(state) = serde_json::from_slice::<InstalledState>(&data) {
                return Some(state);
            }
        }
    }
    if is_dir_path(&app_asar.join("pc-dist/zalo-maple-dawn")) {
        return Some(InstalledState {
            theme_id: Some("rose-pine-dawn".into()),
            theme_name: Some("Rosé Pine Dawn".into()),
            mode: Some("light".into()),
            font_family: Some("Maple Mono".into()),
            font_weight: Some(600),
            font_size_percent: Some(100),
        });
    }
    None
}

/// Resolve Electron resources directory for macOS .app or Windows install tree.
pub fn resources_dir(zalo_path: &Path) -> PathBuf {
    let s = zalo_path.to_string_lossy();
    if s.ends_with(".app") || s.contains("Contents") {
        zalo_path.join("Contents").join("Resources")
    } else {
        zalo_path.join("resources")
    }
}

fn tmp_root() -> PathBuf {
    dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("zalo-theme-tmp")
}

fn quit_zalo(log: &mut String) {
    log_line(log, "[info] Quitting Zalo if running...");
    #[cfg(windows)]
    {
        let _ = Command::new("taskkill")
            .args(["/IM", "Zalo.exe", "/F"])
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status();
        let _ = Command::new("taskkill")
            .args(["/IM", "zalo.exe", "/F"])
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status();
    }
    #[cfg(not(windows))]
    {
        let _ = Command::new("killall")
            .arg("Zalo")
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status();
        let _ = Command::new("killall")
            .arg("zalo")
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .status();
    }
}

fn log_line(log: &mut String, line: &str) {
    log.push_str(line);
    if !line.ends_with('\n') {
        log.push('\n');
    }
}

fn is_file(path: &str) -> bool {
    Path::new(path).is_file()
}

fn is_dir(path: &str) -> bool {
    Path::new(path).is_dir()
}

fn is_file_path(path: &Path) -> bool {
    path.is_file()
}

fn is_dir_path(path: &Path) -> bool {
    path.is_dir()
}

pub fn find_theme<'a>(themes: &'a [Theme], theme_id: &str) -> Result<&'a Theme, InstallerError> {
    themes
        .iter()
        .find(|t| t.id == theme_id)
        .ok_or_else(|| InstallerError::Failed(format!("Unknown theme id: {theme_id}")))
}

