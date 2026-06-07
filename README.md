# 🚀 Fedora + KDE Plasma — Kompleksowy Skrypt Post-Install

![Fedora](https://img.shields.io/badge/Fedora-44-blue?style=for-the-badge&logo=fedora&logoColor=white)
![KDE Plasma](https://img.shields.io/badge/KDE-Plasma%206-indigo?style=for-the-badge&logo=kde&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-Bash%20%26%20Zsh-emerald?style=for-the-badge&logo=gnu-bash&logoColor=white)

Potężny, w pełni zautomatyzowany skrypt konfiguracyjny dedykowany dla dystrybucji **Fedora** ze środowiskiem **KDE Plasma**. Automatyzuje proces optymalizacji systemu, konfiguracji sterowników graficznych, instalacji najważniejszego oprogramowania oraz pełnej personalizacji wyglądu (dot-files, ikony, tapety).

---

## ✨ Główne Funkcje Skryptu

### 🛠️ 1. Optymalizacja i System
* **Tuning DNF5:** Drastyczne przyspieszenie pobierania pakietów dzięki konfiguracji `max_parallel_downloads=10`, `retries=10`, `fastestmirror` i zwiększonym limitom timeoutu.
* **Zarządzanie Blokadami:** Inteligentne oczekiwanie na zwolnienie baz danych RPM oraz twarde czyszczenie procesów blokujących (np. Discover, PackageKit, DNF).
* **Sprzątanie Systemu:** Automatyczne usuwanie zbędnego oprogramowania (m.in. *Konqueror, KMail, Akonadi, Nano, Plasma Vault*) oraz optymalizacja wielkości logów (`journalctl --vacuum-time=2d`).
* **Szybki Rozruch:** Ustawienie czasu oczekiwania GRUB na 0 sekund i automatyczna regeneracja konfiguracji.

### 📦 2. Repozytoria i Oprogramowanie
* **Dodatkowe Repozytoria:** Automatyczna instalacja **RPM Fusion (Free/Non-free)**, repozytoriów dla **Google Chrome**, **Brave Browser** oraz **COPR** (*faugus-launcher*).
* **Bogaty Zestaw Narzędzi:** Instalacja m.in. narzędzi deweloperskich (`@development-tools`), dekompresorów (7zip, unrar), odtwarzaczy i programów multimedialnych (GIMP, Kdenlive, Audacity, Mixxx), a także Discorda, Telegrama i qBittorrenta.
* **Wirtualizacja:** Pełna konfiguracja środowiska KVM/QEMU (`virt-manager`, `libvirtd`) wraz z automatycznym otwarciem wymaganych stref w Firewalld.

### 🎮 3. Wykrywanie GPU i Architektura 32-bit
Skrypt automatycznie analizuje sprzęt za pomocą `lspci` i instaluje dedykowane biblioteki 32-bitowe (kluczowe pod Steam/Wine/Proton) oraz konfiguruje moduły jądra przez Dracut:
* 🟢 **NVIDIA:** Wymuszenie ładowania sterowników w Dracut + biblioteki CUDA i X11 32-bit.
* 🔴 **AMD/Radeon:** Optymalizacja pod `amdgpu` + sterowniki Mesa i Vulkan 32-bit.
* 🔵 **Intel:** Konfiguracja modułu jądra `i915` + sterowniki Mesa 32-bit.

### 🐚 4. Nowoczesny Terminal (ZSH)
* Automatyczna zmiana domyślnej powłoki użytkownika z Bash na **Zsh**.
* Instalacja i bezobsługowe wdrożenie frameworka **Oh My Zsh**.
* Konfiguracja i klonowanie ultra-szybkiego, czytelnego motywu **Powerlevel10k**.
* Dodanie automatycznego wyświetlania statystyk i logo systemu przy każdym uruchomieniu terminala za pomocą **Fastfetch**.

### 🎨 5. Środowisko Graficzne & Ścieżki Użytkownika
* Bezpieczna instalacja plików konfiguracyjnych (`.config`, `.local`, `.icons`) na uśpionej sesji Plasmy (zapobiega nadpisywaniu zmian przez system).
* Dynamiczna, automatyczna zamiana starych ścieżek użytkownika (placeholder `bartek`) na aktualną nazwę zalogowanego profilu w plikach tekstowych, konfiguracjach JSON, INI i CONF.
* Podmiana domyślnego ekranu powitalnego (Splash screen) motywu Breeze.
* Automatyczne wdrożenie systemowych tapet w rozdzielczościach Full HD, 2K oraz 5K wraz z ciemnymi wariantami.
* Ustawienie spersonalizowanego awatara użytkownika z pliku `piwo.png`.
* Konfiguracja szybkich serwerów DNS Cloudflare (`1.1.1.1`) dla aktywnego połączenia sieciowego.

---

## 📂 Wymagana Struktura Repozytorium

Aby skrypt `install.sh` zadziałał poprawnie i znalazł wszystkie wymagane zależności, zachowaj następującą strukturę plików w swoim folderze projektu przed wrzuceniem na GitHuba:

```text
├── install.sh             # Główny skrypt konfiguracyjny (Twój kod)
├── piwo.png               # Systemowy awatar użytkownika (KDE / AccountsService)
├── 1920x1080.png          # Tapeta systemowa (Full HD)
├── 2560x1440.png          # Tapeta systemowa (2K)
├── 5120x2880.png          # Tapeta systemowa (5K / 4K)
├── .update.sh             # Opcjonalny skrypt aktualizacyjny kopiowany do katalogu domowego ~
├── .config/               # Twoje pliki konfiguracyjne (skróty, ustawienia paneli, widgety)
├── .local/                # Lokalne dane aplikacji i konfiguracje użytkownika
├── .icons/                # Niestandardowe paczki ikon systemowych lub kursorów
├── bleachbit/             # Gotowa konfiguracja czyszczenia systemu dla aplikacji BleachBit
└── splash/                # Pliki niestandardowego ekranu powitalnego KDE Splash
```

---

## 🚀 Jak Uruchomić?

### 1. Sklonuj swoje repozytorium
```bash
git clone https://github.com/bartko4321/fedora-config-kde.git
cd fedora-config-kde
```

### 2. Nadaj uprawnienia do wykonywania skryptu
```bash
chmod +x install.sh
```

### 3. Uruchom skrypt jako zwykły użytkownik
> ⚠️ **WAŻNE:** Skryptu **NIE** wolno uruchamiać bezpośrednio przez `sudo ./install.sh` ani z konta root. Skrypt jest inteligentny – sam podniesie uprawnienia za pomocą `sudo` w wymaganych momentach, a dzięki temu prawidłowo odczyta ścieżki do Twojego katalogu domowego `/home/`.

```bash
./install.sh
```

Po zakończeniu wszystkich operacji i uprzątnięciu tymczasowych uprawnień, system automatycznie wyświetli komunikat sukcesu i **wykona restart po 3 sekundach**, aby poprawnie zainicjalizować moduły jądra i załadować nowe środowisko.

---

Wsparcie numer konta: 06291000060000000005038936

## ⚠️ Bezpieczeństwo i Dobre Praktyki

1. **Prywatność danych (`.config` / `.local`):** Zanim spakujesz i wypchniesz foldery konfiguracyjne na publicznego GitHuba, dokładnie sprawdź, czy nie zawierają one poufnych plików (np. tokenów Discorda, sesji przeglądarek, kluczy API, konfiguracji SSH czy zapamiętanych haseł). Jeśli chcesz coś wykluczyć, stwórz plik `.gitignore`.
2. **Świeża instalacja:** Skrypt został zoptymalizowany pod kątem uruchamiania na świeżym systemie Fedora KDE Spin. Użycie go na systemie, z którego korzystasz od miesięcy, zastąpi Twoje bieżące pliki konfiguracyjne w `/home/`.

---
<sub>Stworzono dla maksymalnej automatyzacji i wygody pracy z Fedorą. 🐧⚙️</sub>
