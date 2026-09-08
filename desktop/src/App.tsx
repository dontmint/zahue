import { useEffect, useMemo, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { t, type Lang } from "./i18n";
import "./App.css";

export type Theme = {
  id: string;
  name: string;
  family: string;
  mode: string;
  accent: string;
  background: string;
  foreground: string;
};

export type InstallerStatus = {
  zalo_path: string;
  zalo_exists: boolean;
  has_backup: boolean;
  theme_id?: string | null;
  theme_name?: string | null;
  font_family?: string | null;
  font_weight?: number | null;
  font_size_percent?: number | null;
  themed: boolean;
  app_asar_is_directory: boolean;
  theme_count: number;
};

const SYSTEM_ID = "__system__";

function App() {
  const [lang, setLang] = useState<Lang>(() =>
    (localStorage.getItem("appLanguage") as Lang) || "vi",
  );
  const L = t(lang);

  const [themes, setThemes] = useState<Theme[]>([]);
  const [fonts, setFonts] = useState<string[]>([]);
  const [status, setStatus] = useState<InstallerStatus | null>(null);
  const [zaloPath, setZaloPath] = useState("");
  const [selectedThemeId, setSelectedThemeId] = useState(SYSTEM_ID);
  const [fontFamily, setFontFamily] = useState("Segoe UI");
  const [fontWeight, setFontWeight] = useState(400);
  const [fontSizePercent, setFontSizePercent] = useState(100);
  const [themeQuery, setThemeQuery] = useState("");
  const [fontQuery, setFontQuery] = useState("");
  const [modeFilter, setModeFilter] = useState<"all" | "light" | "dark">("all");
  const [showThemePicker, setShowThemePicker] = useState(false);
  const [showFontPicker, setShowFontPicker] = useState(false);
  const [showLogs, setShowLogs] = useState(false);
  const [logText, setLogText] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const selectedTheme = useMemo(
    () => themes.find((th) => th.id === selectedThemeId) || null,
    [themes, selectedThemeId],
  );

  const palette = selectedTheme
    ? {
        bg: selectedTheme.background,
        fg: selectedTheme.foreground,
        accent: selectedTheme.accent,
        muted: mixHex(selectedTheme.foreground, selectedTheme.background, 0.45),
        card: mixHex(selectedTheme.background, "#ffffff", selectedTheme.mode === "light" ? 0.55 : 0.04),
      }
    : {
        bg: "#f4f4f5",
        fg: "#18181b",
        accent: "#2563eb",
        muted: "#71717a",
        card: "#ffffff",
      };

  const filteredThemes = useMemo(() => {
    const q = themeQuery.trim().toLowerCase();
    return themes.filter((th) => {
      if (modeFilter !== "all" && th.mode !== modeFilter) return false;
      if (!q) return true;
      return (
        th.name.toLowerCase().includes(q) ||
        th.family.toLowerCase().includes(q) ||
        th.id.toLowerCase().includes(q)
      );
    });
  }, [themes, themeQuery, modeFilter]);

  const filteredFonts = useMemo(() => {
    const q = fontQuery.trim().toLowerCase();
    if (!q) return fonts;
    return fonts.filter((f) => f.toLowerCase().includes(q));
  }, [fonts, fontQuery]);

  useEffect(() => {
    localStorage.setItem("appLanguage", lang);
  }, [lang]);

  useEffect(() => {
    (async () => {
      try {
        const [themeList, fontList, defaultPath] = await Promise.all([
          invoke<Theme[]>("list_themes"),
          invoke<string[]>("list_fonts"),
          invoke<string>("default_zalo_path"),
        ]);
        setThemes(themeList);
        setFonts(fontList);
        setZaloPath(defaultPath);
        const st = await invoke<InstallerStatus>("get_status", { zaloPath: defaultPath });
        setStatus(st);
        if (st.font_family) setFontFamily(st.font_family);
        if (st.font_weight) setFontWeight(st.font_weight);
        if (st.font_size_percent) setFontSizePercent(st.font_size_percent);
        if (st.theme_id) setSelectedThemeId(st.theme_id);
      } catch (e) {
        setError(String(e));
      }
    })();
  }, []);

  async function refreshStatus(path = zaloPath) {
    const st = await invoke<InstallerStatus>("get_status", { zaloPath: path || null });
    setStatus(st);
    return st;
  }

  async function applyTheme() {
    if (!selectedTheme) {
      setError(L.pickHint);
      return;
    }
    setBusy(true);
    setError(null);
    setShowLogs(true);
    try {
      const log = await invoke<string>("apply_theme", {
        themeId: selectedTheme.id,
        zaloPath,
        fontFamily,
        fontWeight,
        fontSizePercent,
      });
      setLogText((prev) => prev + log + "\n");
      await refreshStatus();
    } catch (e) {
      const msg = String(e);
      setError(msg);
      setLogText((prev) => prev + `[error] ${msg}\n`);
    } finally {
      setBusy(false);
    }
  }

  async function restore() {
    setBusy(true);
    setError(null);
    setShowLogs(true);
    try {
      const log = await invoke<string>("restore_original", { zaloPath });
      setLogText((prev) => prev + log + "\n");
      setSelectedThemeId(SYSTEM_ID);
      await refreshStatus();
    } catch (e) {
      const msg = String(e);
      setError(msg);
      setLogText((prev) => prev + `[error] ${msg}\n`);
    } finally {
      setBusy(false);
    }
  }

  const subtitle = selectedTheme
    ? `${selectedTheme.family} · ${selectedTheme.mode}`
    : L.subtitleSystem;

  return (
    <div
      className="app"
      style={{
        ["--bg" as string]: palette.bg,
        ["--fg" as string]: palette.fg,
        ["--accent" as string]: palette.accent,
        ["--muted" as string]: palette.muted,
        ["--card" as string]: palette.card,
      }}
    >
      <header className="header">
        <div className="brand">
          <div className="logo" aria-hidden>Z</div>
          <div>
            <div className="title">{L.title}</div>
            <div className="subtitle">{subtitle}</div>
          </div>
        </div>

        <div className="header-actions">
          <div className="flags" role="group" aria-label={L.language}>
            <button
              className={lang === "vi" ? "flag active" : "flag"}
              onClick={() => setLang("vi")}
              title="Tiếng Việt"
            >
              🇻🇳
            </button>
            <button
              className={lang === "en" ? "flag active" : "flag"}
              onClick={() => setLang("en")}
              title="English"
            >
              🇺🇸
            </button>
          </div>

          <button className="ghost" disabled={busy || !status?.has_backup} onClick={restore}>
            {L.restore}
          </button>
          <button className="pill" disabled={busy} onClick={() => setShowThemePicker(true)}>
            {L.themes}
          </button>
        </div>
      </header>

      <section className="panel">
        <Row label={L.accent}>
          <Swatch color={palette.accent} text={palette.accent} />
        </Row>
        <Row label={L.background}>
          <Swatch color={palette.bg} text={palette.bg} />
        </Row>
        <Row label={L.foreground}>
          <Swatch color={palette.fg} text={palette.fg} />
        </Row>
        <Row label={L.uiFont}>
          <button className="pill" disabled={busy} onClick={() => setShowFontPicker(true)}>
            {fontFamily} · {fontWeight}
          </button>
        </Row>
        <Row label={L.fontSize}>
          <div className="font-size">
            <button
              className="ghost"
              disabled={busy || fontSizePercent <= 80}
              onClick={() => setFontSizePercent((v) => Math.max(80, v - 5))}
            >
              −
            </button>
            <input
              type="range"
              min={80}
              max={200}
              step={5}
              value={fontSizePercent}
              disabled={busy}
              onChange={(e) => setFontSizePercent(Number(e.target.value))}
            />
            <span className="mono">{fontSizePercent}%</span>
            <button
              className="ghost"
              disabled={busy || fontSizePercent >= 200}
              onClick={() => setFontSizePercent((v) => Math.min(200, v + 5))}
            >
              +
            </button>
          </div>
        </Row>
        <Row label={L.status}>
          <span className="mono muted">
            {status?.has_backup ? L.backupOK : L.noBackup}
            {status?.themed && status.theme_name ? ` · ${status.theme_name}` : ""}
          </span>
        </Row>
        <Row label={L.path}>
          <input
            className="path-input"
            value={zaloPath}
            disabled={busy}
            onChange={(e) => setZaloPath(e.target.value)}
            onBlur={() => refreshStatus().catch((e) => setError(String(e)))}
          />
        </Row>

        <div className="action-row">
          <div className="hint">
            {error ? (
              <span className="danger">{error}</span>
            ) : selectedThemeId === SYSTEM_ID ? (
              L.pickHint
            ) : status?.zalo_exists ? (
              L.ready(status.theme_count || themes.length)
            ) : (
              L.zaloNotFound
            )}
          </div>
          <button className="ghost" onClick={() => setShowLogs((v) => !v)}>
            {showLogs ? L.hideLog : L.showLog}
          </button>
          <button className="primary" disabled={busy || selectedThemeId === SYSTEM_ID} onClick={applyTheme}>
            {busy ? L.working : L.apply}
          </button>
        </div>
      </section>

      <div className="tip">{L.tip}</div>

      {showLogs && (
        <section className="log-panel">
          <div className="log-head">
            <strong>{L.installerLog}</strong>
            <button className="ghost" onClick={() => setLogText("")}>{L.clear}</button>
          </div>
          <pre>{logText || L.logPlaceholder}</pre>
        </section>
      )}

      {showThemePicker && (
        <Modal onClose={() => setShowThemePicker(false)} title={`${L.themes} (${filteredThemes.length}/${themes.length})`}>
          <div className="filters">
            <input
              placeholder={L.searchThemes}
              value={themeQuery}
              onChange={(e) => setThemeQuery(e.target.value)}
            />
            <select value={modeFilter} onChange={(e) => setModeFilter(e.target.value as typeof modeFilter)}>
              <option value="all">{L.all}</option>
              <option value="light">{L.light}</option>
              <option value="dark">{L.dark}</option>
            </select>
          </div>
          <button
            className={selectedThemeId === SYSTEM_ID ? "theme-item active" : "theme-item"}
            onClick={() => {
              setSelectedThemeId(SYSTEM_ID);
              setShowThemePicker(false);
            }}
          >
            <div>
              <div className="theme-name">{L.systemDefault}</div>
              <div className="theme-meta">{L.followSystem}</div>
            </div>
          </button>
          <div className="theme-list">
            {filteredThemes.map((th) => (
              <button
                key={th.id}
                className={selectedThemeId === th.id ? "theme-item active" : "theme-item"}
                onClick={() => {
                  setSelectedThemeId(th.id);
                  setShowThemePicker(false);
                }}
              >
                <div className="swatches">
                  <i style={{ background: th.background }} />
                  <i style={{ background: th.accent }} />
                  <i style={{ background: th.foreground }} />
                </div>
                <div>
                  <div className="theme-name">{th.name}</div>
                  <div className="theme-meta">{th.family} · {th.mode}</div>
                </div>
              </button>
            ))}
          </div>
        </Modal>
      )}

      {showFontPicker && (
        <Modal onClose={() => setShowFontPicker(false)} title={L.systemFonts}>
          <div className="filters">
            <input
              placeholder={L.searchFonts}
              value={fontQuery}
              onChange={(e) => setFontQuery(e.target.value)}
            />
            <select value={fontWeight} onChange={(e) => setFontWeight(Number(e.target.value))}>
              {[300, 400, 500, 600, 700, 800].map((w) => (
                <option key={w} value={w}>{w}</option>
              ))}
            </select>
          </div>
          <div className="theme-list">
            {filteredFonts.map((f) => (
              <button
                key={f}
                className={fontFamily === f ? "theme-item active" : "theme-item"}
                style={{ fontFamily: f }}
                onClick={() => {
                  setFontFamily(f);
                  setShowFontPicker(false);
                }}
              >
                {f}
              </button>
            ))}
          </div>
        </Modal>
      )}
    </div>
  );
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="row">
      <div className="row-label">{label}</div>
      <div className="row-value">{children}</div>
    </div>
  );
}

function Swatch({ color, text }: { color: string; text: string }) {
  return (
    <div className="swatch">
      <span className="dot" style={{ background: color }} />
      <code>{text}</code>
    </div>
  );
}

function Modal({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
}) {
  const L = t((localStorage.getItem("appLanguage") as Lang) || "vi");
  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <strong>{title}</strong>
          <button className="ghost" onClick={onClose}>{L.done}</button>
        </div>
        {children}
      </div>
    </div>
  );
}

function mixHex(a: string, b: string, tVal: number) {
  const pa = hexToRgb(a);
  const pb = hexToRgb(b);
  const clamp = (n: number) => Math.max(0, Math.min(255, Math.round(n)));
  const r = clamp(pa.r + (pb.r - pa.r) * tVal);
  const g = clamp(pa.g + (pb.g - pa.g) * tVal);
  const bch = clamp(pa.b + (pb.b - pa.b) * tVal);
  return `#${[r, g, bch].map((n) => n.toString(16).padStart(2, "0")).join("")}`;
}

function hexToRgb(hex: string) {
  const h = hex.replace("#", "");
  if (h.length !== 6) return { r: 0, g: 0, b: 0 };
  return {
    r: parseInt(h.slice(0, 2), 16),
    g: parseInt(h.slice(2, 4), 16),
    b: parseInt(h.slice(4, 6), 16),
  };
}

export default App;
