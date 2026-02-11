#!/bin/bash

<<<<<<< HEAD
setfont cyr-sun16
clear

cat << "EOF"
=======
# ==============================================================================
# Meowrch Installer for Asahi Linux (ARM64)
# Unified, robust installation script for custom ecosystem.
# ==============================================================================

set -e  # Exit immediately if a command exits with a non-zero status.

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ==============================================================================
# 1. Architecture & System Checks
# ==============================================================================
check_architecture() {
    log_info "Checking system architecture..."
    ARCH=$(uname -m)
    if [[ "$ARCH" != "aarch64" ]]; then
        log_error "This script is strictly for Asahi Linux (aarch64). Detected: $ARCH"
        log_error "Aborting to prevent damage to x86_64 systems."
        exit 1
    fi
    log_success "Architecture check passed: $ARCH"
}

check_root() {
    if [[ $EUID -eq 0 ]]; then
       log_warn "This script should NOT be run as root initially (makepkg will fail)."
       log_warn "Please run as a normal user with sudo privileges."
       read -p "Continue anyway? (y/N) " confirm
       if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
           exit 1
       fi
    fi
}

# ==============================================================================
# 2. Dependency Management
# ==============================================================================
install_dependencies() {
    log_info "Installing system dependencies (GTK3, Python, GObject)..."
    
    # Update database first
    sudo pacman -Sy
    
    # Core build tools and system libraries
    # Using 'needed' to avoid reinstalling up-to-date packages
    sudo pacman -S --needed --noconfirm \
        base-devel \
        git \
        gtk3 \
        gtk-layer-shell \
        python \
        python-pip \
        python-gobject \
        gobject-introspection \
        python-cairo \
        python-setuptools \
        python-wheel \
        libnotify \
        wget

    log_success "System dependencies installed."
}

setup_aur_helper() {
    log_info "Checking for AUR helper..."
    if command -v yay &> /dev/null; then
        log_success "yay is already installed."
        return
    fi
    
    if command -v paru &> /dev/null; then
        log_success "paru is already installed."
        return
    fi

    log_warn "No AUR helper found. Installing yay-bin..."
    
    # Create temp dir
    TEMP_DIR=$(mktemp -d)
    
    # On aarch64, yay-bin might not be available directly or might be x86.
    # Safe bet: build yay from source or yay-bin if it supports aarch64
    # Trying yay-bin first (usually cross-arch or checks arch), if fails, build from source
    
    cd "$TEMP_DIR"
    if git clone https://aur.archlinux.org/yay-bin.git; then
        cd yay-bin
        # Check PKGBUILD for arch validity
        if grep -q "aarch64" PKGBUILD || grep -q "'any'" PKGBUILD; then
            makepkg -si --noconfirm
            log_success "yay installed successfully."
        else
            log_warn "yay-bin might not support aarch64. Trying yay (source)..."
            cd ..
            rm -rf yay-bin
            git clone https://aur.archlinux.org/yay.git
            cd yay
            makepkg -si --noconfirm
            log_success "yay installed successfully."
        fi
    else
        log_error "Failed to clone yay."
        exit 1
    fi
    
    rm -rf "$TEMP_DIR"
}

# ==============================================================================
# 3. The "Fabric" Conflict Resolution
# ==============================================================================
install_fabric_desktop() {
    log_info "Resolving Fabric dependency for Mewline..."
    
    # Check if 'fabric' (the ssh tool) is installed and conflicts
    if pacman -Q fabric &> /dev/null; then
        log_warn "Detected conflicting package 'fabric' (SSH tool). Removing..."
        sudo pacman -Rns --noconfirm fabric
    fi
    
    # Install python-fabric-git (Desktop Fabric)
    # Check if installed first
    if pacman -Q python-fabric-git &> /dev/null; then
        log_success "python-fabric-git is already installed."
    else
        log_info "Installing python-fabric-git from AUR..."
        # Using yay/paru
        AUR_HELPER="yay"
        if command -v paru &> /dev/null; then AUR_HELPER="paru"; fi
        
        $AUR_HELPER -S --needed --noconfirm python-fabric-git
    fi
}

# ==============================================================================
# 4. Custom Ecosystem Installation
# ==============================================================================
install_repo() {
    local REPO_URL=$1
    local REPO_NAME=$(basename "$REPO_URL" .git)
    local TEMP_DIR="/tmp/meowrch_install/$REPO_NAME"

    log_info "Processing repository: $REPO_NAME"
    
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    if ! git clone "$REPO_URL" "$TEMP_DIR"; then
        log_error "Failed to clone $REPO_NAME"
        return 1
    fi
    
    cd "$TEMP_DIR"

    # Check for PKGBUILD
    if [[ -f "PKGBUILD" ]]; then
        log_info "Found PKGBUILD. Building package..."
        
        # Patch ARCH if strictly x86_64
        sed -i "s/arch=('x86_64')/arch=('x86_64' 'aarch64')/" PKGBUILD
        sed -i 's/arch=("x86_64")/arch=("x86_64" "aarch64")/' PKGBUILD
        
        if makepkg -si --noconfirm; then
            log_success "$REPO_NAME built and installed."
        else
            log_error "Failed to build $REPO_NAME via makepkg."
            # Fallback to manual?
        fi
    elif [[ -f "install.sh" ]]; then
        log_info "Found install.sh. Running script..."
        chmod +x install.sh
        if ./install.sh; then
            log_success "$REPO_NAME installed via script."
        else
            log_error "install.sh failed for $REPO_NAME"
        fi
    elif [[ -f "Makefile" ]]; then
        log_info "Found Makefile. Installing..."
        if make && sudo make install; then
            log_success "$REPO_NAME installed via Make."
        else
            log_error "Make failed for $REPO_NAME"
        fi
    else
        log_warn "No standard installer found for $REPO_NAME. Skipping."
    fi
}

install_ecosystem() {
    # 1. Core Settings & Tools
    install_repo "https://github.com/meowrch/meowrch-settings"
    install_repo "https://github.com/meowrch/meowrch-tools"
    
    # 2. UI/UX
    install_repo "https://github.com/meowrch/nemo-extensions"
    install_repo "https://github.com/meowrch/HotKeyHub"
    install_repo "https://github.com/meowrch/rofi-network-manager"
    
    # 3. Mewline (Requires Fabric Logic above)
    install_repo "https://github.com/meowrch/mewline"
    # Create wrapper for mewline
    log_info "Creating mewline wrapper..."
    sudo bash -c 'cat > /usr/local/bin/mewline-start << EOF
#!/bin/bash
exec python -m mewline
EOF'
    sudo chmod +x /usr/local/bin/mewline-start
    
    # 4. Plymouth Theme
    install_repo "https://github.com/meowrch/plymouth-theme"
    
    # 5. Pawlette & Themes
    install_repo "https://github.com/meowrch/pawlette"
    
    # Install specific themes manually if not handled by PKGBUILDs
    log_info "Installing Pawlette themes..."
    mkdir -p "$HOME/.local/share/pawlette/themes"
    
    # Helper to clone theme directly to destination if no PKGBUILD
    install_theme_direct() {
        local URL=$1
        local NAME=$(basename "$URL" | sed 's/pawlette-//' | sed 's/-theme//')
        local DEST="$HOME/.local/share/pawlette/themes/$NAME"
        
        if [[ ! -d "$DEST" ]]; then
            log_info "Cloning theme $NAME..."
            git clone "$URL" "$DEST"
        else
            log_info "Theme $NAME already exists."
        fi
    }
    
    install_theme_direct "https://github.com/meowrch/pawlette-catppuccin-mocha-theme"
    install_theme_direct "https://github.com/meowrch/pawlette-catppuccin-latte-theme"
}

# ==============================================================================
# 5. Post-Install Configuration
# ==============================================================================
configure_system() {
    log_info "Configuring system..."

    # Plymouth Initramfs (Dracut for Asahi)
    log_info "Regenerating initramfs for Plymouth..."
    if command -v dracut &> /dev/null; then
        log_info "Detected Dracut. Regenerating..."
        sudo dracut --regenerate-all --force
    elif command -v mkinitcpio &> /dev/null; then
        log_info "Detected mkinitcpio. Regenerating..."
        sudo mkinitcpio -P
    fi

    # SDDM
    log_info "Enabling SDDM..."
    sudo systemctl enable sddm || true
    # Note: Theme config handled by meowrch-settings or python script later, 
    # but we can ensure the config file points to meowrch if needed.
    
    # Pawlette Default Theme
    log_info "Applying Pawlette theme: catppuccin-mocha..."
    if command -v pawlette &> /dev/null; then
        pawlette apply catppuccin-mocha || log_warn "Failed to apply pawlette theme."
    else
        log_warn "Pawlette command not found."
    fi
}

# ==============================================================================
# Main Execution Flow
# ==============================================================================
main() {
    clear
    cat << "EOF"
>>>>>>> f7b4f55 (feat: optimize installer for Asahi Linux (ARM64))
    __  ___                                __           ___               __    _ 
   /  |/  /___   ____ _      __  ____     / /_         /   |  _____ __ _ / /_  (_)
  / /|_/ // _ \ / __ \ | /| / / / __/    / __ \       / /| | / ___// _`// __/ / / 
 / /  / //  __// /_/ / |/ |/ / / /      / / / /      / ___ |(__  )/ (_|// /_ / /  
/_/  /_/ \___/ \____/|__/|__/ /_/      /_/ /_/      /_/  |_/____/ \__,_/ \__//_/   
                                                                                  
<<<<<<< HEAD
                 For Asahi Linux (ALARM)
EOF
echo
echo "Starting pre-install..." && sleep 2


##==> Initializing git submodules
#######################################################
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Initializing git submodules..."
    git submodule update --init --recursive
else
    echo "Error: This directory is not a git repository. Please clone the project using git clone."
    exit 1
fi
#######################################################


##==> Installing basic dependencies for pacman
#######################################################
dependencies=(python python-pip)
for package in "${dependencies[@]}"; do
    if ! pacman -Q $package &> /dev/null; then
        sudo pacman -S --needed $package
    fi
done
#######################################################


##==> Installing python and dependencies for it
#######################################################
declare -a packages=(
	"inquirer"
	"loguru"
	"psutil"
	"gputil"
	"pyamdgpuinfo"
	"colorama"
)

for package in "${packages[@]}"; do
    if ! pip show $package &> /dev/null; then
        pip install $package --break-system-packages
    fi
done
#######################################################


##==> Building the system
#######################################################
python Builder/install.py
=======
                 For Asahi Linux (ALARM) - Optimized
EOF
    echo

    check_architecture
    # check_root # Optional, depending on if user runs as root or sudo user

    install_dependencies
    setup_aur_helper
    install_fabric_desktop
    install_ecosystem
    configure_system

    log_success "Core ecosystem installation complete!"
    log_info "Launching User Configuration Wizard (Python)..."
    sleep 2
    
    # Run the Python builder for the final touches (Dotfiles, User Packages, etc.)
    # We assume we are in the root of the repo
    if [[ -f "Builder/install.py" ]]; then
        python Builder/install.py
    else
        log_error "Builder/install.py not found!"
    fi
}

main
>>>>>>> f7b4f55 (feat: optimize installer for Asahi Linux (ARM64))
