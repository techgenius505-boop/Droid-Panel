#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════╗
# ║        DROID PANEL - Termux + Shizuku        ║
# ║     Control total de Android sin root        ║
# ╚══════════════════════════════════════════════╝

# ─── Colores ───────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ─── Verificar dependencias ─────────────────────
check_deps() {
    local missing=()
    for dep in rish whiptail curl; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}✗ Faltan dependencias: ${missing[*]}${NC}"
        echo -e "${YELLOW}Instala con: pkg install whiptail${NC}"
        echo -e "${YELLOW}Para rish: necesitas Shizuku activo${NC}"
        exit 1
    fi
}

# ─── Ejecutar comando via Shizuku/rish ──────────
rsh() {
    rish -c "$1" 2>/dev/null
}

# ─── Banner de inicio ───────────────────────────
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
  ██████╗ ██████╗  ██████╗ ██╗██████╗     ██████╗  █████╗ ███╗   ██╗███████╗██╗
  ██╔══██╗██╔══██╗██╔═══██╗██║██╔══██╗    ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║
  ██║  ██║██████╔╝██║   ██║██║██║  ██║    ██████╔╝███████║██╔██╗ ██║█████╗  ██║
  ██║  ██║██╔══██╗██║   ██║██║██║  ██║    ██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║
  ██████╔╝██║  ██║╚██████╔╝██║██████╔╝    ██║     ██║  ██║██║ ╚████║███████╗███████╗
  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═════╝    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "  ${DIM}Termux + Shizuku │ Control total sin root${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

