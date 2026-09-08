<p align="center">
  <img src="docs/assets/zahue-logo-256.png" alt="ZaHue" width="160" />
</p>

<h1 align="center">ZaHue</h1>

<p align="center">
  <strong>Đổi giao diện Zalo PC</strong> — 80 bảng màu, font tùy chỉnh, bộ cài đặt gốc cho từng hệ điều hành.
</p>

<p align="center">
  <strong>🇻🇳 Tiếng Việt</strong> · <a href="./README-us.md">🇺🇸 English</a>
</p>

<p align="center">
  <a href="https://github.com/dontmint/zahue/actions/workflows/macos-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/macos-build.yml?branch=main&style=for-the-badge&logo=apple&logoColor=white&label=macOS" alt="macOS build" /></a>
  <a href="https://github.com/dontmint/zahue/actions/workflows/windows-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/windows-build.yml?branch=main&style=for-the-badge&logo=windows&logoColor=white&label=Windows" alt="Windows build" /></a>
  <a href="https://github.com/dontmint/zahue/actions/workflows/linux-build.yml"><img src="https://img.shields.io/github/actions/workflow/status/dontmint/zahue/linux-build.yml?branch=main&style=for-the-badge&logo=linux&logoColor=white&label=Linux" alt="Linux build" /></a>
  <img src="https://img.shields.io/badge/themes-80-7c3aed?style=for-the-badge&logo=palette&logoColor=white" alt="80 themes" />
  <img src="https://img.shields.io/badge/license-MPL--2.0-blue?style=for-the-badge" alt="MPL-2.0" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/SwiftUI-native-F05138?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Tauri-Windows%20%2F%20Linux-FFC131?style=flat-square&logo=tauri&logoColor=black" alt="Tauri Windows/Linux" />
  <img src="https://img.shields.io/badge/VI%20%2F%20EN-localized-00A86B?style=flat-square" alt="Localized" />
  <img src="https://img.shields.io/badge/Electron-ASAR%20patch-47848F?style=flat-square&logo=electron&logoColor=white" alt="Electron ASAR" />
  <a href="https://github.com/dontmint/zahue/stargazers"><img src="https://img.shields.io/github/stars/dontmint/zahue?style=flat-square" alt="Stars" /></a>
</p>

**ZaHue** giúp bạn gắn theme từ catalog lên **Zalo PC** trên macOS, Windows và Linux (các bản port không chính thức):

1. Giải nén file `app.asar` của Zalo
2. Chèn CSS ghi đè mã màu + font / cỡ chữ (nếu muốn)
3. Giữ bản sao `app.asar.bak` để **Khôi phục** về bản gốc
4. Đổi theme thoải mái, không cần cài lại Zalo

Cách làm lấy cảm hứng từ [ZaDark](https://github.com/ncdai/zadark) (MPL-2.0) — vá gói ASAR của Electron. Bảng màu lấy từ catalog Alacritty của [terminalcolors.com](https://terminalcolors.com).

**Lưu ý Linux:** Zalo **không có** bản desktop chính thức trên Linux. ZaHue chỉ hỗ trợ các bản AppImage / `.deb` cộng đồng khi bạn trỏ vào thư mục cài đặt **có quyền ghi**.

## Tải về

| Hệ điều hành | File | Cách lấy |
|--------------|------|----------|
| **macOS** | `ZaHue.dmg` | [Releases](https://github.com/dontmint/zahue/releases) hoặc Actions → **macOS build** |
| **Windows** | NSIS `.exe` / `.msi` | [Releases](https://github.com/dontmint/zahue/releases) hoặc Actions → **Windows build** |
| **Linux** | `.AppImage` / `.deb` | [Releases](https://github.com/dontmint/zahue/releases) hoặc Actions → **Linux build** |

Trên macOS (ứng dụng ký ad-hoc): nếu Gatekeeper cảnh báo, hãy **chuột phải → Open**.

## Tính năng

- **80 theme** (18 sáng / 62 tối) trong `themes/terminalcolors.json`
- Xem trước bảng màu ngay trên giao diện chọn theme
- Dùng mọi font đã cài trên máy (ưu tiên Maple Mono nếu có; không bắt buộc)
- Chỉnh độ đậm font và cỡ chữ giao diện (theo thang rem)
- Giao diện mặc định tiếng Việt, có nút chuyển sang tiếng Anh
- **Áp dụng** / **Khôi phục** kèm nhật ký cài đặt
- App gốc — người dùng cuối **không cần** cài Node.js
- macOS: hiện trạng thái quyền **App Management**, cảnh báo đỏ nếu chưa cấp, kèm nút mở Cài đặt Hệ thống

## ZaHue cho macOS (SwiftUI)

Ứng dụng **Swift gốc** (~1,6 MB):

```bash
./macos/scripts/build-app.sh
open dist/ZaHue.app
```

Hoặc tải DMG từ CI / Releases (không cần Xcode trên máy bạn).

- Giao diện mặc định theo **System Default** (Sáng / Tối của macOS)
- Chọn theme trong catalog để xem trước bảng màu ngay
- Áp dụng / Khôi phục bằng Swift: giải nén ASAR rồi chèn HTML/CSS
- Cần quyền **App Management** để ghi vào `/Applications/Zalo.app`
- Nếu chưa cấp quyền: ZaHue hiện cảnh báo đỏ + nút **Mở Cài đặt** / **Kiểm tra lại**

Chi tiết: [macos/README.md](./macos/README.md).

## ZaHue Desktop (Windows + Linux)

Giao diện đa nền tảng (React + Rust) nằm trong `desktop/`:

```bash
cd desktop
npm install
npm run tauri:dev      # phát triển (UI chạy được mọi OS; Áp dụng cần có Zalo trên máy)
npm run tauri:build    # đóng gói bộ cài trên đúng hệ điều hành đích
```

- **Windows** — đường dẫn mặc định: `%LOCALAPPDATA%\Programs\Zalo`
- **Linux** — bản AppImage / `.deb` không chính thức; cần bản giải nén **có quyền ghi**. ZaHue tự dò các vị trí như `/opt/Zalo`, `/usr/{lib,share}/zalo`, `~/.local/share/Zalo`, `~/Applications/Zalo`, `~/zalo-*/app`, `squashfs-root` (xem [desktop/README.md](./desktop/README.md)). Mount AppImage thường **chỉ đọc**.
- **CI:** Actions → **Windows build** / **Linux build** → tải artifact `zahue-windows` / `zahue-linux`

Chi tiết: [desktop/README.md](./desktop/README.md).

## CLI tùy chọn (dành cho nhà phát triển)

Công cụ Node 18+ ở thư mục gốc repo (macOS + Windows + Linux):

```bash
npm install

node install.js list [--mode light|dark]
node install.js status [ZaloPath]
node install.js install <theme-id> [ZaloPath] [--font "Family"] [--weight 600]
node install.js uninstall [ZaloPath]
```

Ví dụ:

```bash
node install.js install rose-pine-dawn
node install.js install rose-pine-dawn --font "SF Pro Text" --weight 500
node install.js install rose-pine-moon --font "Segoe UI"
node install.js uninstall
```

Các lệnh tắt trong `package.json`: `npm run theme:list`, `theme:dawn`, `theme:moon`, `theme:restore`.

## Lưu ý quan trọng

- Sau mỗi lần Zalo cập nhật, hãy **Áp dụng lại** theme (bản cập nhật có thể thay `app.asar`)
- Khi dùng theme sáng, nên giữ giao diện sẵn có của Zalo ở chế độ **Sáng** để màu hiển thị đúng
- ZaHue chỉnh sửa ứng dụng bên thứ ba — có thể xung đột với điều khoản sử dụng của Zalo hoặc cơ chế kiểm tra toàn vẹn sau này
- Cần quyền ghi vào `/Applications/Zalo.app` (macOS), thư mục cài Zalo (Windows), hoặc bản giải nén Linux có quyền ghi
- AppImage trên Linux thường chỉ đọc — hãy giải nén trước, rồi trỏ ZaHue vào thư mục đó

Ví dụ giải nén AppImage:

```bash
chmod +x Zalo*.AppImage
./Zalo*.AppImage --appimage-extract
# Trong ZaHue, chọn đường dẫn ./squashfs-root
```

## Cấu trúc repo

```
themes/terminalcolors.json   # Catalog 80 theme
assets/theme.js              # Bootstrap nhỏ được chèn vào Zalo
assets/theme.css             # Placeholder (CSS được tạo lúc Áp dụng)
install.js                   # CLI Node tùy chọn (giải nén ASAR → chèn)
macos/                       # App SwiftUI gốc + script build
desktop/                     # App Tauri + React cho Windows/Linux
docs/assets/                 # Ảnh branding / README
.github/workflows/           # CI build macOS + Windows + Linux
```

## Tùy chỉnh

- **Chọn theme:** dùng ZaHue.app / Desktop GUI, hoặc `node install.js list`
- **Catalog:** sửa / bổ sung `themes/terminalcolors.json`
- **Font:** chọn họ font đã cài trong GUI, hoặc dùng `--font` trên CLI

## Giấy phép

[MPL-2.0](./LICENSE) — kỹ thuật dựa trên ZaDark; bảng màu từ terminalcolors.com.
