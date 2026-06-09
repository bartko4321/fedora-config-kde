# 🚀 Fedora + KDE Plasma — Comprehensive Post-Install Script

![Fedora](https://img.shields.io/badge/Fedora-44-blue?style=for-the-badge&logo=fedora&logoColor=white)
![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-indigo?style=for-the-badge&logo=kde&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash%20%26%20Zsh-emerald?style=for-the-badge&logo=gnu-bash&logoColor=white)

A powerful, fully automated configuration script dedicated to **Fedora** with the **KDE Plasma** desktop environment. It automates system optimization, graphics driver configuration, essential software installation, and full visual personalization (dot-files, icons, wallpapers).

---

## ✨ Main Features

### 🛠️ 1. Optimization & System
* **DNF5 Tuning:** Dramatically speeds up package downloads by configuring `max_parallel_downloads=10`, `retries=10`, `fastestmirror`, and increased timeout limits.
* **Lock Management:** Intelligently waits for RPM database locks to be released and forcefully clears blocking processes (e.g. Discover, PackageKit, DNF).
* **System Cleanup:** Automatically removes unnecessary software (including *Konqueror, KMail, Akonadi, Nano, Plasma Vault*) and optimizes log size (`journalctl --vacuum-time=2d`).
* **Fast Boot:** Sets GRUB timeout to 0 seconds and automatically regenerates the configuration.

### 📦 2. Repositories & Software
* **Extra Repositories:** Automatic setup of **RPM Fusion (Free/Non-free)**, repositories for **Google Chrome**, **Brave Browser**, and **COPR** (*faugus-launcher*).
* **Rich Toolset:** Installs developer tools (`@development-tools`), decompressors (7zip, unrar), multimedia players and editors (GIMP, Kdenlive, Audacity, Mixxx), as well as Discord, Telegram, and qBittorrent.
* **Virtualization:** Full KVM/QEMU environment setup (`virt-manager`, `libvirtd`) with automatic Firewalld zone configuration.

### 🎮 3. GPU Detection & 32-bit Architecture
The script automatically analyzes hardware via `lspci` and installs dedicated 32-bit libraries (essential for Steam/Wine/Proton) and configures kernel modules via Dracut:
* 🟢 **NVIDIA:** Forces driver loading in Dracut + 32-bit CUDA and X11 libraries.
* 🔴 **AMD/Radeon:** Optimized for `amdgpu` + 32-bit Mesa and Vulkan drivers.
* 🔵 **Intel:** Configures the `i915` kernel module + 32-bit Mesa drivers.

### 🐚 4. Modern Terminal (ZSH)
* Automatically changes the default user shell from Bash to **Zsh**.
* Installs and silently deploys the **Oh My Zsh** framework.
* Configures and clones the ultra-fast, readable **Powerlevel10k** theme.
* Adds automatic system stats and logo display on every terminal launch via **Fastfetch**.

### 🎨 5. Desktop Environment & User Paths
* Safely installs configuration files (`.config`, `.local`, `.icons`) into a dormant Plasma session (prevents the system from overwriting changes).
* Dynamically replaces old user paths (placeholder `bartek`) with the currently logged-in profile name in text files, JSON, INI, and CONF configurations.
* Replaces the default Breeze splash screen with a custom one.
* Automatically deploys system wallpapers in Full HD, 2K, and 5K resolutions including dark variants.
* Sets a personalized user avatar from the `piwo.png` file.
* Configures Cloudflare fast DNS servers (`1.1.1.1`) for the active network connection.

---

## 📂 Required Repository Structure

For the `install.sh` script to work correctly and find all required dependencies, maintain the following file structure in your project folder before pushing to GitHub:

```text
├── install.sh             # Main configuration script
├── piwo.png               # System user avatar (KDE / AccountsService)
├── 1920x1080.png          # System wallpaper (Full HD)
├── 2560x1440.png          # System wallpaper (2K)
├── 5120x2880.png          # System wallpaper (5K / 4K)
├── .update.sh             # Optional update script copied to the home directory ~
├── .config/               # Your configuration files (shortcuts, panel settings, widgets)
├── .local/                # Local app data and user configurations
├── .icons/                # Custom system icon packs or cursors
├── bleachbit/             # Pre-configured BleachBit system cleanup settings
└── splash/                # Custom KDE splash screen files
```

---

## 🚀 How to Run

### 1. Clone your repository
```bash
git clone https://github.com/bartko4321/fedora-config-kde.git
cd fedora-config-kde
```

### 2. Enter the downloaded folder
```bash
cd fedora-config-kde
```

### 3. Make the script executable
```bash
chmod +x install.sh
```

### 4. Run the script as a regular user
> ⚠️ **IMPORTANT:** Do **NOT** run the script directly with `sudo ./install.sh` or from the root account. The script is smart — it will elevate privileges via `sudo` only when needed, and this ensures it correctly reads the paths to your home directory `/home/`.

```bash
./install.sh
```

Once all operations are complete and temporary privileges are cleaned up, the system will display a success message and **automatically restart after 3 seconds** to properly initialize kernel modules and load the new environment.

---

Bank account for support: 06291000060000000005038936

## ⚠️ Security & Best Practices

1. **Data privacy (`.config` / `.local`):** Before packing and pushing your configuration folders to a public GitHub repository, carefully check that they don't contain sensitive files (e.g. Discord tokens, browser sessions, API keys, SSH configs, or saved passwords). If you want to exclude something, create a `.gitignore` file.
2. **Fresh installation:** This script is optimized to run on a fresh Fedora KDE Spin installation. Running it on a system you've been using for months will overwrite your current configuration files in `/home/`.

If you find this project useful, leave a star! ⭐

---
<sub>Built for maximum automation and convenience when working with Fedora. 🐧⚙️</sub>
