# 🐱 Meowrch Arch — Apple Silicon Edition

> A fully automated [Meowrch](https://github.com/meowrch/meowrch) Arch Linux rice, optimized for **Apple Silicon (aarch64-linux)** running Asahi Linux.

## ✨ Features

| Feature | Implementation | (Asahi Specifics) |
|---------|---------------|-------------------|
| **Window Manager** | **Hyprland** (Wayland) / **BSPWM** (X11) | Hardware accelerated with GPU drivers |
| **Status Bar** | **Mewline** (Dynamic Island) / Polybar | Custom Python-based dynamic island |
| **Launcher** | **Rofi** | With wallpaper preview & apps grid |
| **Terminal** | **Kitty** | GPU accelerated, Ligatures support |
| **Shell** | **Fish** / **Zsh** | Starship prompt, Autosuggestions |
| **Notifications** | **Dunst** / **Mewline** | Integrated with Dynamic Island |
| **Lock Screen** | **Hyprlock** / **Betterlockscreen** | Blur, media info, custom styling |
| **Theme** | **Catppuccin Mocha** | GTK, Qt, Terminal, Discord, everything |
| **Icons** | **Tela Circle Dracula** | Consistent icon pack |
| **Cursor** | **Bibata Modern Classic** | |
| **Kernel** | **linux-asahi** | Native kernel from Asahi Linux project |
| **Gaming** | **FEX-Emu** | Seamless x86_64 translation for Steam/Games |
| **Audio** | **PipeWire** | With Asahi-specific DSP profiles for speakers |

## 📁 Project Structure

```
meowrch-asahi/
├── install.sh                         # 🚀 Main entry point - Automated installer
├── README.md                          # 📄 This file
│
├── Builder/                           # 🐍 Python Installer Core
│   ├── install.py                     # User configuration wizard
│   ├── packages.py                    # Package lists (aarch64 optimized)
│   ├── managers/                      # Installation logic
│   │   ├── repo_manager.py            # Handles custom meowrch repos & patching
│   │   ├── package_manager.py         # Pacman/AUR wrapper
│   │   └── custom_apps/               # App-specific configurators (Pawlette, etc)
│   └── utils/                         # Helpers (backup, logging)
│
└── misc/                              # 🎨 Assets & Themes
    └── services/                      # Systemd services (Plymouth, etc)
```

## 🚀 Installation

### Prerequisites

1.  **Install Asahi Linux (ALARM)** on your Mac:
    ```bash
    curl https://alx.sh | sh
    ```
    Choose **"Arch Linux ARM"** (sometimes labeled as "UEFI environment only" + manual install, but ideally use the pre-built Arch Linux ARM rootfs from the installer if available, or install Arch ARM manually).
    *(Note: This rice assumes you have a base Arch Linux ARM installation).*

2.  **Connect to the Internet**:
    ```bash
    # WiFi
    iwctl station wlan0 connect "YourNetwork"
    
    # Verify
    ping -c 3 archlinux.org
    ```

### Install

```bash
# 1. Clone this repository
git clone https://github.com/Redm00use/meowrch-asahi --depth 1 --single-branch
cd meowrch-asahi

# 2. Run the optimized installer
chmod +x install.sh
./install.sh
```

**The installer will:**
*   Check for `aarch64` architecture.
*   Install system dependencies (GTK3, Python).
*   Clone & Build custom tools (Mewline, Pawlette) patching them for ARM64 if needed.
*   Setup FEX-Emu for x86 compatibility.
*   configure the entire Desktop Environment.

### Post-Install

```bash
# Reboot into your new system
reboot

# Enjoy Meowrch!
```

## 🎮 FEX-Emu & Steam on ARM

### How It Works (Magic 🪄)

Meowrch uses **FEX-Emu** to run x86_64 binaries (like Steam, Discord, Games) on your ARM processor.

```
┌─────────────────────────────────────────────────┐
│  Windows Game (.exe)                             │
│    ↓                                             │
│  Proton / Wine (Win32 → Linux syscalls)          │
│    ↓                                             │
│  x86_64 Linux Binary                             │
│    ↓                                             │
│  FEX-Emu (x86_64 → aarch64 translation)         │
│    ↓                                             │
│  Native aarch64 Linux                            │
│    ↓                                             │
│  mesa-asahi (OpenGL/Vulkan → Apple GPU)          │
│    ↓                                             │
│  Apple M-Series GPU Hardware                     │
└─────────────────────────────────────────────────┘
```

### Key Points

*   **Transparent Emulation**: You usually don't need to do anything. `binfmt_misc` is configured so the kernel runs x86 binaries with FEX automatically.
*   **Steam**: Installed automatically. If it doesn't open, try running `steam` from terminal to see FEX logs.
*   **Performance**: FEX is fast, but it is still emulation. Expect some overhead compared to native, but it's much faster than QEMU.

## 🔧 Daily Usage

### Common Commands

```bash
# Update System (including AUR)
yay
# OR
paru

# Install packages
pacman -S package_name
yay -S aur_package_name

# Change Wallpaper
Super + W

# Launch Apps
Super + A
```

### Hyprland Keybindings

| Key | Action |
|-----|--------|
| `Super + Enter` | Open terminal (Kitty) |
| `Super + A` | Application launcher (Rofi) |
| `Super + E` | File manager (Nemo) |
| `Super + Q` | Close window |
| `Super + Space` | Toggle floating |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Arrow` | Focus direction |
| `Super + L` | Lock screen |
| `Super + X` | Power menu |
| `Super + W` | Wallpaper selector |
| `Super + V` | Clipboard manager |
| `Super + B` | Bluetooth Manager |
| `Super + N` | Network Manager |
| `Print` | Screenshot (area) |
| `Super + Print` | Screenshot (full) |
| `XF86Audio*` | Volume controls |
| `XF86MonBrightness*` | Brightness controls |

## 🎨 Theming

The entire system uses **Catppuccin Mocha** with **Lavender** accent:

- **Background**: `#1e1e2e`
- **Foreground**: `#cdd6f4`
- **Accent**: `#b4befe` (lavender)
- **Secondary**: `#f5c2e7` (pink)
- **Error/Alert**: `#f38ba8` (red)
- **Success**: `#a6e3a1` (green)
- **Warning**: `#fab387` (peach)

**Pawlette** is used to manage these themes. To change theme:
```bash
pawlette apply catppuccin-latte
# or
pawlette apply catppuccin-mocha
```

## 📝 Customization

### Add/Remove Packages
Edit `Builder/packages.py` before installation to add or remove default packages.
*   `BASE` dictionary contains system packages (pacman/AUR).
*   `CUSTOM` dictionary contains optional groups (Gaming, Office, etc).

### Monitor Configuration
**Hyprland**: Edit `~/.config/hypr/monitors.conf` (or `hyprland.conf` directly).
```bash
# Example for M1 Pro
monitor=eDP-1,preferred,auto,2
```

## 📜 License

This configuration is based on [Meowrch](https://github.com/meowrch/meowrch) (MIT License).
Optimized for [Asahi Linux](https://asahilinux.org/).
