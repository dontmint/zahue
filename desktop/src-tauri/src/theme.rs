use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
#[cfg(target_os = "linux")]
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Theme {
    pub id: String,
    pub name: String,
    pub family: String,
    pub variant: Option<String>,
    pub mode: String,
    pub accent: String,
    pub background: String,
    pub foreground: String,
    pub red: Option<String>,
    pub yellow: Option<String>,
    pub blue: Option<String>,
    pub cyan: Option<String>,
    pub magenta: Option<String>,
    pub green: Option<String>,
    pub black: Option<String>,
    pub white: Option<String>,
    pub bright_black: Option<String>,
    pub bright_red: Option<String>,
    pub bright_green: Option<String>,
    pub bright_yellow: Option<String>,
    pub bright_blue: Option<String>,
    pub bright_magenta: Option<String>,
    pub bright_cyan: Option<String>,
    pub bright_white: Option<String>,
    pub selection_bg: Option<String>,
    pub selection_fg: Option<String>,
}

impl Theme {
    pub fn is_light(&self) -> bool {
        self.mode == "light"
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstallerStatus {
    pub zalo_path: String,
    pub zalo_exists: bool,
    pub has_backup: bool,
    pub theme_id: Option<String>,
    pub theme_name: Option<String>,
    pub font_family: Option<String>,
    pub font_weight: Option<i32>,
    pub font_size_percent: Option<i32>,
    pub themed: bool,
    pub app_asar_is_directory: bool,
    pub theme_count: usize,
}

impl Default for InstallerStatus {
    fn default() -> Self {
        Self {
            zalo_path: default_zalo_path(),
            zalo_exists: false,
            has_backup: false,
            theme_id: None,
            theme_name: None,
            font_family: None,
            font_weight: None,
            font_size_percent: None,
            themed: false,
            app_asar_is_directory: false,
            theme_count: 0,
        }
    }
}

/// Load theme catalog from resource path candidates.
pub fn load_themes(resource_dir: Option<PathBuf>) -> Vec<Theme> {
    let mut candidates: Vec<PathBuf> = Vec::new();

    if let Some(dir) = resource_dir {
        candidates.push(dir.join("themes").join("terminalcolors.json"));
        // Bundled as resources/themes/* may flatten into resource_dir directly
        candidates.push(dir.join("terminalcolors.json"));
    }

    let manifest = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    candidates.push(manifest.join("resources/themes/terminalcolors.json"));
    candidates.push(manifest.join("../themes/terminalcolors.json"));
    candidates.push(manifest.join("../../themes/terminalcolors.json"));

    for path in candidates {
        if let Some(themes) = try_load_catalog(&path) {
            return themes;
        }
    }
    Vec::new()
}

fn try_load_catalog(path: &Path) -> Option<Vec<Theme>> {
    let data = fs::read(path).ok()?;
    let mut themes: Vec<Theme> = serde_json::from_slice(&data).ok()?;
    if themes.is_empty() {
        return None;
    }
    themes.sort_by(|a, b| {
        match (a.mode.as_str() == "light", b.mode.as_str() == "light") {
            (true, false) => std::cmp::Ordering::Less,
            (false, true) => std::cmp::Ordering::Greater,
            _ => a.name.to_lowercase().cmp(&b.name.to_lowercase()),
        }
    });
    Some(themes)
}

pub fn default_zalo_path() -> String {
    #[cfg(windows)]
    {
        let local = std::env::var("LOCALAPPDATA").unwrap_or_else(|_| {
            dirs::home_dir()
                .map(|h| h.join("AppData").join("Local").display().to_string())
                .unwrap_or_else(|| r"C:\Users\Default\AppData\Local".into())
        });
        let candidates = [
            PathBuf::from(&local).join("Programs").join("Zalo"),
            PathBuf::from(&local).join("ZaloPC"),
            PathBuf::from(&local).join("Programs").join("ZaloPC"),
        ];
        for c in &candidates {
            if c.join("resources").is_dir()
                || c.join("Zalo.exe").is_file()
                || c.is_dir()
            {
                return c.display().to_string();
            }
        }
        return PathBuf::from(&local)
            .join("Programs")
            .join("Zalo")
            .display()
            .to_string();
    }
    #[cfg(target_os = "macos")]
    {
        "/Applications/Zalo.app".to_string()
    }
    #[cfg(target_os = "linux")]
    {
        let home = dirs::home_dir().unwrap_or_else(|| PathBuf::from("."));
        let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
        let candidates = [
            PathBuf::from("/opt/Zalo"),
            PathBuf::from("/opt/zalo"),
            PathBuf::from("/usr/lib/zalo"),
            PathBuf::from("/usr/share/zalo"),
            home.join(".local/share/Zalo"),
            home.join(".local/share/zalo"),
            home.join("Applications/Zalo"),
            home.join("Applications/zalo"),
            home.join("zalo-for-linux/app"),
            home.join("zalo-linux/app"),
            home.join("zalo-linux-2026/app"),
            home.join("squashfs-root"),
            cwd.join("squashfs-root"),
        ];
        for c in &candidates {
            if looks_like_zalo_install(c) {
                return c.display().to_string();
            }
        }
        "/opt/Zalo".to_string()
    }
    #[cfg(not(any(windows, target_os = "macos", target_os = "linux")))]
    {
        "/opt/Zalo".to_string()
    }
}

#[cfg(target_os = "linux")]
fn looks_like_zalo_install(path: &Path) -> bool {
    path.join("resources").join("app.asar").is_file()
        || path.join("resources").is_dir()
        || path.join("app.asar").is_file()
        || (path.is_dir()
            && (path.join("zalo").is_file()
                || path.join("Zalo").is_file()
                || path.join("AppRun").is_file()))
}

pub fn list_fonts() -> Vec<String> {
    use std::collections::BTreeSet;

    #[cfg(windows)]
    let defaults: &[&str] = &[
        "Maple Mono",
        "Segoe UI",
        "Arial",
        "Calibri",
        "Cambria",
        "Consolas",
        "Courier New",
        "Georgia",
        "Tahoma",
        "Times New Roman",
        "Trebuchet MS",
        "Verdana",
        "Microsoft YaHei",
        "Noto Sans",
        "Inter",
    ];
    #[cfg(target_os = "macos")]
    let defaults: &[&str] = &[
        "Maple Mono",
        "Segoe UI",
        "Arial",
        "Calibri",
        "Cambria",
        "Consolas",
        "Courier New",
        "Georgia",
        "Tahoma",
        "Times New Roman",
        "Trebuchet MS",
        "Verdana",
        "Microsoft YaHei",
        "Noto Sans",
        "Inter",
    ];
    #[cfg(target_os = "linux")]
    let defaults: &[&str] = &[
        "Maple Mono",
        "Noto Sans",
        "DejaVu Sans",
        "Ubuntu",
        "Cantarell",
        "Inter",
        "Arial",
        "Courier New",
        "Georgia",
        "Times New Roman",
        "Verdana",
    ];
    #[cfg(not(any(windows, target_os = "macos", target_os = "linux")))]
    let defaults: &[&str] = &["Maple Mono", "Noto Sans", "Inter"];

    let mut fonts: BTreeSet<String> = defaults.iter().map(|s| (*s).to_string()).collect();

    let mut dirs: Vec<PathBuf> = Vec::new();
    #[cfg(windows)]
    {
        if let Ok(windir) = std::env::var("WINDIR") {
            dirs.push(PathBuf::from(windir).join("Fonts"));
        }
        if let Some(local) = dirs::data_local_dir() {
            dirs.push(local.join("Microsoft").join("Windows").join("Fonts"));
        }
    }
    #[cfg(target_os = "macos")]
    {
        dirs.push(PathBuf::from("/System/Library/Fonts"));
        dirs.push(PathBuf::from("/Library/Fonts"));
        if let Some(home) = dirs::home_dir() {
            dirs.push(home.join("Library/Fonts"));
        }
    }
    #[cfg(target_os = "linux")]
    {
        if let Ok(output) = Command::new("fc-list")
            .args([":", "family"])
            .output()
        {
            if let Ok(text) = String::from_utf8(output.stdout) {
                for line in text.lines() {
                    for part in line.split(',') {
                        let family = part.trim();
                        if !family.is_empty() {
                            fonts.insert(family.to_string());
                        }
                    }
                }
            }
        }
        dirs.push(PathBuf::from("/usr/share/fonts"));
        dirs.push(PathBuf::from("/usr/local/share/fonts"));
        if let Some(home) = dirs::home_dir() {
            dirs.push(home.join(".local/share/fonts"));
            dirs.push(home.join(".fonts"));
        }
    }

    scan_font_dirs(&dirs, &mut fonts);
    fonts.into_iter().collect()
}

fn scan_font_dirs(dirs: &[PathBuf], fonts: &mut std::collections::BTreeSet<String>) {
    let mut stack: Vec<PathBuf> = dirs.to_vec();
    while let Some(dir) = stack.pop() {
        let Ok(entries) = fs::read_dir(&dir) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                stack.push(path);
                continue;
            }
            let ext = path
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("")
                .to_ascii_lowercase();
            if !matches!(ext.as_str(), "ttf" | "otf" | "ttc" | "dfont") {
                continue;
            }
            if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                let family = stem
                    .split('-')
                    .next()
                    .unwrap_or(stem)
                    .replace('_', " ")
                    .trim()
                    .to_string();
                if !family.is_empty() {
                    fonts.insert(family);
                }
            }
        }
    }
}
