#!/bin/bash

# ==========================================================
# KOMPLEKSOWY SKRYPT KONFIGURACYJNY SYSTEMU (KDE PLASMA + FEDORA 44)
# ==========================================================

set -euo pipefail

# --- Kolory i logowanie ---
INFO='\033[0;34m'
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
WARN='\033[0;33m'
NC='\033[0m'

log_info()  { echo -e "${INFO}==> $*${NC}"; }
log_ok()    { echo -e "${SUCCESS}==> $*${NC}"; }
log_err()   { echo -e "${ERROR}==> BŁĄD: $*${NC}" >&2; }
log_warn()  { echo -e "${WARN}==> UWAGA: $*${NC}"; }

# Pułapka błędów
trap 'log_err "Skrypt zakończył się błędem w linii $LINENO. Polecenie: $BASH_COMMAND"' ERR

# --- Zmienne globalne ---
CURRENT_USER=$(whoami)
ACTUAL_USER="${SUDO_USER:-$USER}"
OLD_USER_PLACEHOLDER="bartek"
RPM_DIR="/tmp/rpms_$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Upewnij się, że skrypt NIE jest uruchamiany jako root
if [[ "$EUID" -eq 0 ]]; then
    log_err "Nie uruchamiaj skryptu jako root. Uruchom jako zwykły użytkownik z dostępem do sudo."
    exit 1
fi

# Tymczasowy wyjątek sudo dla DNF/RPM (by nie pytało o hasło podczas długiej instalacji)
sudo -v
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99-temp-installer > /dev/null

# Przejście do katalogu skryptu
cd "$SCRIPT_DIR" || exit 1

# ==========================================================
# 1. PRZYGOTOWANIE
# ==========================================================
log_info "Przygotowanie konfiguracji użytkownika..."

if [[ -f "$SCRIPT_DIR/.update.sh" ]] && \
   [[ "$(realpath "$SCRIPT_DIR/.update.sh")" != "$(realpath ~/.update.sh 2>/dev/null)" ]]; then
    cp -af "$SCRIPT_DIR/.update.sh" ~
    chmod +x ~/.update.sh
fi

# ==========================================================
# 2. KONFIGURACJA SYSTEMOWA (SUDO)
# ==========================================================
log_info "Przechodzę do konfiguracji systemowej..."

# Brutalne wyłączenie menedżerów pakietów z tła, w tym Discover (KDE) i DNF5
sudo systemctl stop packagekit.service dnf-makecache.timer dnf5-makecache.timer 2>/dev/null || true
sudo systemctl mask packagekit.service dnf-makecache.timer dnf5-makecache.timer 2>/dev/null || true
sudo killall -9 packagekitd dnf dnf5 discover rpm 2>/dev/null || true
sudo rm -f /var/lib/rpm/.rpm.lock /usr/lib/sysimage/rpm/.rpm.lock /var/cache/libdnf5/*.lock 2>/dev/null || true

# Ulepszone oczekiwanie na blokadę (dostosowane do dnf5)
wait_for_rpm_lock() {
    local i=0
    while pgrep -x dnf >/dev/null || pgrep -x dnf5 >/dev/null || pgrep -x packagekitd >/dev/null || pgrep -x rpm >/dev/null || sudo fuser /usr/lib/sysimage/rpm/.rpm.lock >/dev/null 2>&1; do
        if (( i++ >= 12 )); then
            log_warn "Blokada RPM zajęta zbyt długo. Wymuszam twarde czyszczenie..."
            sudo killall -9 rpm dnf dnf5 packagekitd discover 2>/dev/null || true
            sudo rm -f /var/lib/rpm/.rpm.lock /usr/lib/sysimage/rpm/.rpm.lock /var/cache/libdnf5/*.lock 2>/dev/null || true
            sudo rpm --rebuilddb 2>/dev/null || true
            break
        fi
        log_info "Czekam na zwolnienie menedżera RPM/DNF5... ($((i*5))s)"
        sleep 5
    done
}

# Instalacja podstawowych narzędzi skryptowych (KRYTYCZNE)
wait_for_rpm_lock
sudo dnf5 install -y wget curl pciutils

# Optymalizacja DNF5
log_info "Optymalizacja menedżera pakietów DNF5..."
for conf in /etc/dnf/dnf.conf /etc/dnf/dnf5.conf; do
    if [[ -f "$conf" ]]; then
        sudo sed -i '/^fastestmirror=/d; /^retries=/d; /^timeout=/d; /^max_parallel_downloads=/d; /^ip_resolve=/d' "$conf"
        echo -e "fastestmirror=False\nmax_parallel_downloads=10\nretries=10\ntimeout=120\nip_resolve=4" | sudo tee -a "$conf" > /dev/null
    fi
done

wait_for_rpm_lock

# --- Repozytoria RPM Fusion ---
FEDORA_VER=$(rpm -E %fedora)
log_info "Wykryta wersja Fedory: $FEDORA_VER"

wait_for_rpm_lock
sudo dnf5 install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm" \
    || log_warn "Część repozytoriów RPM Fusion już zainstalowana"

# --- Chrome ---
wait_for_rpm_lock
log_info "Ręczny import klucza Google..."
sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub || log_warn "Błąd pobierania klucza Google, pomijam."

sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<'EOF'
[google-chrome]
name=Google Chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF
wait_for_rpm_lock
sudo dnf5 install -y google-chrome-stable

# --- Brave ---
sudo tee /etc/yum.repos.d/brave-browser.repo > /dev/null <<'EOF'
[brave-browser]
name=Brave Browser
baseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/
enabled=1
gpgcheck=1
gpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
EOF
sudo chmod 644 /etc/yum.repos.d/brave-browser.repo
wait_for_rpm_lock
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc || log_warn "Import klucza Brave nie powiódł się"
wait_for_rpm_lock
sudo dnf5 install -y brave-browser

# --- Narzędzia deweloperskie ---
wait_for_rpm_lock
sudo dnf5 install -y @development-tools @c-development || log_warn "Błąd grup deweloperskich"
sudo dnf5 install -y gcc gcc-c++ make || log_warn "Błąd narzędzi deweloperskich"

# --- Czyszczenie zbędnych pakietów ---
log_info "Usuwanie zbędnych pakietów..."
TO_REMOVE=(
    nano konqueror plasma-browser-integration plasma-vault
    krdp plasma-thunderbolt kontact kmail kontrast plasma-welcome
    kaddressbook kdepim-runtime akonadi
    krfb krdc
)
wait_for_rpm_lock
sudo dnf5 remove -y "${TO_REMOVE[@]}" 2>/dev/null || true
sudo dnf5 autoremove -y

# --- Główna lista pakietów ---
PACKAGES=(
    dconf-editor hunspell-pl fastfetch unrar git mc exfatprogs ntfs-3g
    os-prober android-tools fsarchiver inxi pv python3-defusedxml
    python3-packaging 7zip zenity innoextract python3-pip pipx kio-admin
    audacity gimp gmic mixxx kdenlive telegram-desktop qbittorrent
    wine winetricks bleachbit gamemode vulkan-tools gamescope mangohud
    goverlay cmake meson ninja-build python3-tqdm just
    gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-ugly
    bluez-tools zsh libayatana-appindicator psmisc makeself
)

wait_for_rpm_lock
log_info "Instalacja głównej listy pakietów..."
sudo dnf5 install -y --skip-unavailable "${PACKAGES[@]}" || log_warn "Część pakietów nie powiodła się"

# ==========================================================
# WYKRYWANIE GPU: BIBLIOTEKI 32-BIT I DRACUT
# ==========================================================
log_info "Wykrywanie GPU i instalacja bibliotek 32-bitowych..."
PACKAGES_32=(
    glibc.i686 libstdc++.i686 libgcc.i686 vulkan-loader.i686 wine.i686
    alsa-lib.i686 pipewire-alsa.i686 pipewire-libs.i686 pulseaudio-libs.i686 openal-soft.i686
    mangohud.i686 gamemode.i686 openssl-libs.i686 nss.i686 nspr.i686
    libXcomposite.i686 libXcursor.i686 libXdamage.i686 libXext.i686 libXfixes.i686
    libXi.i686 libXrandr.i686 libXrender.i686 libXtst.i686 libxkbcommon.i686
)

GPU_INFO=$(lspci -nn | grep -iE "VGA|3D|Display" || true)
DRACUT_CONF="/etc/dracut.conf.d/90-gpu.conf"

if echo "$GPU_INFO" | grep -iq "NVIDIA"; then
    PACKAGES_32+=(xorg-x11-drv-nvidia-libs.i686 xorg-x11-drv-nvidia-cuda-libs.i686)
    echo 'force_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "' | sudo tee "$DRACUT_CONF" > /dev/null
elif echo "$GPU_INFO" | grep -iqE "AMD|Radeon"; then
    PACKAGES_32+=(mesa-dri-drivers.i686 mesa-vulkan-drivers.i686 mesa-libGL.i686)
    echo 'force_drivers+=" amdgpu "' | sudo tee "$DRACUT_CONF" > /dev/null
elif echo "$GPU_INFO" | grep -iq "Intel"; then
    PACKAGES_32+=(mesa-dri-drivers.i686 mesa-vulkan-drivers.i686 mesa-libGL.i686)
    echo 'force_drivers+=" i915 "' | sudo tee "$DRACUT_CONF" > /dev/null
else
    PACKAGES_32+=(mesa-dri-drivers.i686 mesa-vulkan-drivers.i686 mesa-libGL.i686)
    sudo rm -f "$DRACUT_CONF"
fi

wait_for_rpm_lock
sudo dnf5 install -y --skip-unavailable "${PACKAGES_32[@]}" || log_warn "Błąd bibliotek 32-bit"

if [[ -f "$DRACUT_CONF" ]]; then
    sudo dracut --force
fi

# --- Firmware WiFi ---
wait_for_rpm_lock
for pkg in broadcom-wl; do
    if sudo dnf5 info "$pkg" &>/dev/null; then
        sudo dnf5 install -y "$pkg"
    fi
done

# --- Pakiety RPM ---
mkdir -p "$RPM_DIR"
download_rpm() {
    local name="$1" url="$2" dldest="$3"
    wget -q --timeout=30 -O "$dldest" "$url" && log_ok "Pobrano: $name" || { log_warn "Błąd: $name"; rm -f "$dldest"; }
}

wait_for_rpm_lock
if sudo dnf5 repolist 2>/dev/null | grep -iq "rpmfusion-nonfree"; then
    sudo dnf5 install -y discord || log_err "Błąd instalacji Discorda"
else
    dest="/tmp/discord.rpm"
    wget -q --user-agent="Mozilla/5.0" "https://discord.com/api/download?platform=linux&format=rpm" -O "$dest"
    if file "$dest" | grep -q "RPM"; then
        sudo dnf5 install -y "$dest"
    fi
    rm -f "$dest"
fi

LSFG_URL=$(curl -sf https://api.github.com/repos/YuriSizov/ls-fg/releases/latest | grep "browser_download_url.*ls-fg_.*rpm" | cut -d '"' -f 4 || true)
[[ -n "$LSFG_URL" ]] && download_rpm "ls-fg" "$LSFG_URL" "$RPM_DIR/lsfg.rpm"

LSFG_VK_URL=$(curl -sf https://api.github.com/repos/YuriSizov/ls-fg-vk/releases/latest | grep "browser_download_url.*rpm" | cut -d '"' -f 4 || true)
[[ -n "$LSFG_VK_URL" ]] && download_rpm "ls-fg-vk" "$LSFG_VK_URL" "$RPM_DIR/lsfg-vk.rpm"

wait_for_rpm_lock
sudo dnf5 -y copr enable faugus/faugus-launcher && sudo dnf5 --refresh -y install faugus-launcher

shopt -s nullglob
RPM_FILES=("$RPM_DIR"/*.rpm)
if [[ ${#RPM_FILES[@]} -gt 0 ]]; then
    wait_for_rpm_lock
    sudo dnf5 install -y "${RPM_FILES[@]}"
fi
shopt -u nullglob
rm -rf "$RPM_DIR"

# --- Wirtualizacja ---
wait_for_rpm_lock
sudo dnf5 install -y --skip-unavailable virt-manager qemu-kvm qemu-img libvirt libvirt-daemon-kvm edk2-ovmf dnsmasq

if command -v firewall-cmd &>/dev/null; then
    sudo systemctl enable --now firewalld
    sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
    sudo firewall-cmd --permanent --add-source=192.168.122.0/24
    sudo firewall-cmd --reload
fi

for svc in libvirtd virtqemud; do
    if systemctl list-unit-files "$svc.service" &>/dev/null 2>&1; then
        sudo systemctl enable --now "$svc.service"
        break
    fi
done

# ==========================================================
# 3. FINALIZACJA I OPTYMALIZACJA
# ==========================================================
log_info "Finalizacja i optymalizacja..."

sudo systemctl unmask packagekit.service dnf-makecache.timer dnf5-makecache.timer 2>/dev/null || true

if [[ -d "$SCRIPT_DIR/bleachbit" ]]; then
    sudo mkdir -p /root/.config/bleachbit
    sudo cp -af "$SCRIPT_DIR/bleachbit/." /root/.config/bleachbit/
fi

sudo systemctl enable fstrim.timer
sudo journalctl --vacuum-time=2d
sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub

# Zunifikowana ścieżka GRUB2 (standard w nowoczesnej Fedorze niezależnie od EFI/BIOS)
sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true

if [[ -f "$SCRIPT_DIR/piwo.png" ]]; then
    sudo mkdir -p /usr/share/plasma/avatars/ /var/lib/AccountsService/icons/
    sudo cp -af "$SCRIPT_DIR/piwo.png" /usr/share/plasma/avatars/piwo.png
    sudo cp -af "$SCRIPT_DIR/piwo.png" "/var/lib/AccountsService/icons/$ACTUAL_USER"
    sudo chmod 644 /usr/share/plasma/avatars/piwo.png "/var/lib/AccountsService/icons/$ACTUAL_USER"
    sudo chown root:root "/var/lib/AccountsService/icons/$ACTUAL_USER"
    sudo restorecon -v "/var/lib/AccountsService/icons/$ACTUAL_USER"
fi

if [[ -d "$SCRIPT_DIR/splash" ]]; then
    sudo rm -rf /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/splash
    sudo cp -af "$SCRIPT_DIR/splash" /usr/share/plasma/look-and-feel/org.kde.breeze.desktop/contents/
    log_ok "Ekran powitalny (Splash) skopiowany."
else
    log_warn "Katalog splash nie istnieje w $SCRIPT_DIR"
fi

log_info "Podmiana tapet w motywie Next..."
TARGET_DIR="/usr/share/wallpapers/Next/contents/images"

for res in 1920x1080 2560x1440 5120x2880; do
    if [ -f "$SCRIPT_DIR/$res.png" ]; then
        sudo mkdir -p "$TARGET_DIR/contents/images"
        # Używamy standardowego cp aby root został właścicielem
        sudo cp -f "$SCRIPT_DIR/$res.png" "$TARGET_DIR/$res.png"
        sudo cp -f "$SCRIPT_DIR/$res.png" "$TARGET_DIR/contents/images/$res.png"
        sudo chmod 644 "$TARGET_DIR/$res.png" "$TARGET_DIR/contents/images/$res.png"
    else
        log_warn "Brak pliku $res.png w katalogu ze skryptem - pomijam."
    fi
done

sudo mkdir -p /usr/share/wallpapers/Next/contents/images_dark/
if [ -f "$SCRIPT_DIR/5120x2880.png" ]; then
    sudo cp -f "$SCRIPT_DIR/5120x2880.png" /usr/share/wallpapers/Next/contents/images_dark/5120x2880.png
    sudo chmod 644 /usr/share/wallpapers/Next/contents/images_dark/5120x2880.png
fi

# -------------------------------------------------------

ACTIVE_CONN=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep -v "^lo" | head -n 1 | cut -d: -f1 || true)
if [[ -n "$ACTIVE_CONN" ]]; then
    sudo nmcli connection modify "$ACTIVE_CONN" ipv4.dns "1.1.1.1,1.0.0.1" ipv6.dns "2606:4700:4700::1112,2606:4700:4700::1002"
    sudo nmcli connection up "$ACTIVE_CONN" || true
fi

ZSH_BIN=$(command -v zsh || true)
if [[ -n "$ZSH_BIN" ]]; then
    sudo chsh -s "$ZSH_BIN" "$CURRENT_USER"
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ ! -d "$P10K_DIR" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    fi
    ZSHRC="$HOME/.zshrc"
    if [[ -f "$ZSHRC" ]]; then
        sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$ZSHRC"
        grep -q "LC_ALL=pl_PL.UTF-8" "$ZSHRC" || echo "export LC_ALL=pl_PL.UTF-8" >> "$ZSHRC"
        grep -q "^fastfetch" "$ZSHRC" || echo "fastfetch" >> "$ZSHRC"
    fi
fi

# ==========================================================
# 4. KOPIOWANIE KONFIGURACJI
# ==========================================================
log_info "Zatrzymywanie środowiska KDE, aby nie nadpisało naszych zmian..."
kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
sleep 2

log_info "Kopiowanie plików konfiguracyjnych na uśpionym środowisku..."
if [[ -d "$SCRIPT_DIR/.config" ]]; then cp -af "$SCRIPT_DIR/.config/." ~/.config/; fi
if [[ -d "$SCRIPT_DIR/.local" ]]; then cp -af "$SCRIPT_DIR/.local/." ~/.local/; fi
if [[ -d "$SCRIPT_DIR/.icons" ]]; then cp -af "$SCRIPT_DIR/.icons/." ~/.icons/; fi

# Podmiana ścieżki
if [[ "$OLD_USER_PLACEHOLDER" != "$CURRENT_USER" ]]; then
    grep -rl --include="*.conf" --include="*.json" --include="*.ini" \
        "/home/$OLD_USER_PLACEHOLDER" ~/.config 2>/dev/null \
        | xargs -r sed -i "s|/home/$OLD_USER_PLACEHOLDER|/home/$CURRENT_USER|g" || true
fi

log_info "Czyszczenie pamięci podręcznej (Cache)..."
rm -rf ~/.cache/icon-cache.kcache ~/.cache/plasma* ~/.cache/ico*

# Odpalamy chwilowo Plasmę w tle (wczyta już Twoje skopiowane przed chwilą ustawienia .config)
plasmashell >/dev/null 2>&1 &
sleep 5

# Zabijamy proces drugi raz. Plasma zrzuci stan RAMu na dysk - zapisując konfigurację
kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
sleep 2

# Odbudowa bazy systemowej
if command -v kbuildsycoca6 &>/dev/null; then
    kbuildsycoca6 --noincremental &>/dev/null || true
elif command -v kbuildsycoca5 &>/dev/null; then
    kbuildsycoca5 --noincremental &>/dev/null || true
fi

# ==========================================================
# 5. SPRZĄTANIE WYJĄTKÓW SUDO
# ==========================================================
sudo rm -f /etc/sudoers.d/99-temp-installer

log_ok "KONFIGURACJA ZAKOŃCZONA SUKCESEM!"
sleep 3
systemctl reboot
