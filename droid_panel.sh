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

# ─── 1. STATS DEL SISTEMA ───────────────────────
show_stats() {
    clear
    show_banner
    echo -e "${BOLD}${WHITE}  📊 ESTADÍSTICAS DEL SISTEMA${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    # Batería
    local battery_level battery_status battery_temp
    battery_level=$(rsh "dumpsys battery | grep level" | grep -oP '\d+')
    battery_status=$(rsh "dumpsys battery | grep status" | grep -oP '\d+')
    battery_temp=$(rsh "dumpsys battery | grep temperature" | grep -oP '\d+')
    battery_temp_c=$(echo "scale=1; $battery_temp / 10" | bc 2>/dev/null || echo "?")

    local bat_status_str="Desconocido"
    case $battery_status in
        2) bat_status_str="${GREEN}Cargando ⚡${NC}" ;;
        3) bat_status_str="${YELLOW}Descargando${NC}" ;;
        5) bat_status_str="${GREEN}Llena ✓${NC}" ;;
    esac

    # Barra de batería visual
    local filled=$(( battery_level / 10 ))
    local empty=$(( 10 - filled ))
    local bat_bar="${GREEN}"
    [ "$battery_level" -lt 30 ] && bat_bar="${RED}"
    [ "$battery_level" -lt 60 ] && [ "$battery_level" -ge 30 ] && bat_bar="${YELLOW}"
    local bar="${bat_bar}["
    for i in $(seq 1 $filled); do bar+="█"; done
    for i in $(seq 1 $empty); do bar+="░"; done
    bar+="]${NC}"

    echo -e "  🔋 ${BOLD}Batería:${NC}     $bar ${bat_bar}${battery_level}%${NC} │ Estado: $bat_status_str │ Temp: ${battery_temp_c}°C"

    # RAM
    local mem_total mem_avail mem_used mem_pct
    mem_total=$(rsh "cat /proc/meminfo | grep MemTotal" | grep -oP '\d+' | head -1)
    mem_avail=$(rsh "cat /proc/meminfo | grep MemAvailable" | grep -oP '\d+' | head -1)
    if [ -n "$mem_total" ] && [ -n "$mem_avail" ]; then
        mem_used=$(( (mem_total - mem_avail) / 1024 ))
        mem_total_mb=$(( mem_total / 1024 ))
        mem_pct=$(( (mem_total - mem_avail) * 100 / mem_total ))
        local mem_bar_filled=$(( mem_pct / 10 ))
        local mem_bar="["
        for i in $(seq 1 $mem_bar_filled); do mem_bar+="█"; done
        for i in $(seq 1 $(( 10 - mem_bar_filled )) ); do mem_bar+="░"; done
        mem_bar+="]"
        echo -e "  💾 ${BOLD}RAM:${NC}         ${CYAN}${mem_bar}${NC} ${CYAN}${mem_used}MB / ${mem_total_mb}MB${NC} (${mem_pct}%)"
    fi

    # Uptime
    local uptime_str
    uptime_str=$(rsh "cat /proc/uptime" | awk '{s=$1; h=int(s/3600); m=int((s%3600)/60); printf "%dh %dm", h, m}')
    echo -e "  ⏱️  ${BOLD}Uptime:${NC}      ${MAGENTA}${uptime_str}${NC}"

    # Almacenamiento
    local storage_info
    storage_info=$(rsh "df /data" | tail -1 | awk '{used=$3; total=$2; pct=int(used*100/total); printf "%dGB / %dGB (%d%%)", used/1024/1024, total/1024/1024, pct}')
    echo -e "  💿 ${BOLD}Almacen.:${NC}    ${YELLOW}${storage_info}${NC}"

    # Modelo y Android
    local model android_ver
    model=$(rsh "getprop ro.product.model")
    android_ver=$(rsh "getprop ro.build.version.release")
    echo -e "\n  📱 ${BOLD}Dispositivo:${NC} ${WHITE}${model}${NC} │ Android ${WHITE}${android_ver}${NC}"

    # Red
    local wifi_ssid ip_addr
    wifi_ssid=$(rsh "dumpsys wifi | grep 'mWifiInfo'" | grep -oP 'SSID: \K[^,]+' | head -1)
    ip_addr=$(rsh "ip route get 1" 2>/dev/null | grep -oP 'src \K[\d.]+' | head -1)
    echo -e "  🌐 ${BOLD}Red:${NC}         ${GREEN}${wifi_ssid:-Sin WiFi}${NC} │ IP: ${CYAN}${ip_addr:-N/A}${NC}"

    echo -e "\n  ${DIM}Actualizado: $(date '+%H:%M:%S')${NC}\n"
    read -p "  Presiona ENTER para volver al menú..."
}

