mod asar;
mod css;
mod installer;
mod theme;

use theme::{InstallerStatus, Theme};

fn resource_dir(app: &tauri::AppHandle) -> Option<std::path::PathBuf> {
    use tauri::Manager;
    app.path().resource_dir().ok()
}

fn catalog(app: &tauri::AppHandle) -> Vec<Theme> {
    theme::load_themes(resource_dir(app))
}

#[tauri::command]
fn list_themes(app: tauri::AppHandle) -> Vec<Theme> {
    catalog(&app)
}

#[tauri::command]
fn get_status(app: tauri::AppHandle, zalo_path: Option<String>) -> InstallerStatus {
    let path = zalo_path
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(theme::default_zalo_path);
    let themes = catalog(&app);
    let mut log = String::new();
    installer::status(&path, &themes, &mut log)
}

#[tauri::command]
fn apply_theme(
    app: tauri::AppHandle,
    theme_id: String,
    zalo_path: String,
    font_family: String,
    font_weight: i32,
    font_size_percent: i32,
) -> Result<String, String> {
    let themes = catalog(&app);
    let theme = installer::find_theme(&themes, &theme_id).map_err(|e| e.to_string())?;
    let mut log = String::new();
    installer::apply(
        theme,
        &zalo_path,
        &font_family,
        font_weight,
        font_size_percent,
        &mut log,
    )
    .map_err(|e| e.to_string())?;
    Ok(log)
}

#[tauri::command]
fn restore_original(zalo_path: String) -> Result<String, String> {
    let mut log = String::new();
    installer::restore(&zalo_path, &mut log).map_err(|e| e.to_string())?;
    Ok(log)
}

#[tauri::command]
fn list_fonts() -> Vec<String> {
    theme::list_fonts()
}

#[tauri::command]
fn default_zalo_path() -> String {
    theme::default_zalo_path()
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![
            list_themes,
            get_status,
            apply_theme,
            restore_original,
            list_fonts,
            default_zalo_path
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
