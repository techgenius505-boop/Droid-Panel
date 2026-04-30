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

# ─── 2. CONTROL DE SISTEMA ──────────────────────
system_controls() {
    while true; do
        CHOICE=$(whiptail --title "⚙️  CONTROL DEL SISTEMA" \
            --menu "\nSelecciona una acción:" 20 60 10 \
            "1" "🌙  Activar Dark Mode" \
            "2" "☀️   Desactivar Dark Mode" \
            "3" "🔕  Activar No Molestar" \
            "4" "🔔  Desactivar No Molestar" \
            "5" "✈️   Activar Modo Avión" \
            "6" "📡  Desactivar Modo Avión" \
            "7" "🔆  Brillo al máximo" \
            "8" "🔅  Brillo al mínimo" \
            "9" "🔄  Rotar pantalla (auto)" \
            "B" "← Volver" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1)
                rsh "cmd uimode night yes"
                whiptail --msgbox "🌙 Dark Mode ACTIVADO" 8 40
                ;;
            2)
                rsh "cmd uimode night no"
                whiptail --msgbox "☀️  Dark Mode DESACTIVADO" 8 40
                ;;
            3)
                rsh "cmd notification set_dnd priority"
                whiptail --msgbox "🔕 No Molestar ACTIVADO" 8 40
                ;;
            4)
                rsh "cmd notification set_dnd off"
                whiptail --msgbox "🔔 No Molestar DESACTIVADO" 8 40
                ;;
            5)
                rsh "cmd connectivity airplane-mode enable"
                whiptail --msgbox "✈️  Modo Avión ACTIVADO" 8 40
                ;;
            6)
                rsh "cmd connectivity airplane-mode disable"
                whiptail --msgbox "📡 Modo Avión DESACTIVADO" 8 40
                ;;
            7)
                rsh "settings put system screen_brightness 255"
                whiptail --msgbox "🔆 Brillo al MÁXIMO" 8 40
                ;;
            8)
                rsh "settings put system screen_brightness 0"
                whiptail --msgbox "🔅 Brillo al MÍNIMO" 8 40
                ;;
            9)
                rsh "settings put system accelerometer_rotation 1"
                whiptail --msgbox "🔄 Rotación automática ACTIVADA" 8 40
                ;;
            B|"") break ;;
        esac
    done
}

# ─── 3. GESTOR DE APPS ─────────────────────────
app_manager() {
    while true; do
        CHOICE=$(whiptail --title "📱 GESTOR DE APLICACIONES" \
            --menu "\nSelecciona una acción:" 18 60 8 \
            "1" "📋  Ver apps instaladas" \
            "2" "🚀  Abrir una app" \
            "3" "⏹️   Forzar cierre de app" \
            "4" "🗑️   Desinstalar app" \
            "5" "🔒  Deshabilitar app (sin borrar)" \
            "6" "✅  Habilitar app" \
            "B" "← Volver" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1)
                # Listar apps en un archivo temporal para mostrar
                local tmp_file=$(mktemp)
                rsh "pm list packages -3" | sed 's/package://g' | sort > "$tmp_file"
                local count=$(wc -l < "$tmp_file")
                whiptail --title "Apps instaladas (${count} apps)" \
                    --textbox "$tmp_file" 30 70
                rm "$tmp_file"
                ;;
            2)
                PKG=$(whiptail --inputbox "Escribe el package name\n(ej: com.instagram.android)" \
                    10 60 --title "Abrir App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    rsh "monkey -p $PKG 1" &>/dev/null
                    whiptail --msgbox "🚀 Abriendo $PKG..." 8 50
                fi
                ;;
            3)
                PKG=$(whiptail --inputbox "Package name de la app a cerrar:" \
                    10 60 --title "Forzar Cierre" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    rsh "am force-stop $PKG"
                    whiptail --msgbox "⏹️  App $PKG detenida" 8 50
                fi
                ;;
            4)
                PKG=$(whiptail --inputbox "Package name a desinstalar:" \
                    10 60 --title "Desinstalar App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    if whiptail --yesno "¿Seguro que quieres desinstalar $PKG?" 8 60; then
                        rsh "pm uninstall $PKG"
                        whiptail --msgbox "🗑️  $PKG desinstalado" 8 50
                    fi
                fi
                ;;
            5)
                PKG=$(whiptail --inputbox "Package name a deshabilitar:" \
                    10 60 --title "Deshabilitar App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    rsh "pm disable-user --user 0 $PKG"
                    whiptail --msgbox "🔒 $PKG deshabilitado" 8 50
                fi
                ;;
            6)
                PKG=$(whiptail --inputbox "Package name a habilitar:" \
                    10 60 --title "Habilitar App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    rsh "pm enable $PKG"
                    whiptail --msgbox "✅ $PKG habilitado" 8 50
                fi
                ;;
            B|"") break ;;
        esac
    done
}

# ─── 4. PORTAPAPELES ────────────────────────────
clipboard_manager() {
    while true; do
        CHOICE=$(whiptail --title "📋 PORTAPAPELES" \
            --menu "\nQué quieres hacer:" 14 55 5 \
            "1" "👁️   Leer portapapeles" \
            "2" "✏️   Escribir al portapapeles" \
            "3" "🧹  Limpiar portapapeles" \
            "B" "← Volver" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1)
                local content
                content=$(rsh "cmd clipboard get" 2>/dev/null || \
                          termux-clipboard-get 2>/dev/null || \
                          echo "(vacío o no disponible)")
                whiptail --msgbox "📋 Contenido:\n\n$content" 15 70 --title "Portapapeles"
                ;;
            2)
                local new_content
                new_content=$(whiptail --inputbox "Texto a copiar al portapapeles:" \
                    10 60 --title "Escribir Portapapeles" 3>&1 1>&2 2>&3)
                if [ -n "$new_content" ]; then
                    echo -n "$new_content" | termux-clipboard-set 2>/dev/null || \
                    rsh "cmd clipboard set '$new_content'" 2>/dev/null
                    whiptail --msgbox "✅ Copiado al portapapeles" 8 45
                fi
                ;;
            3)
                rsh "cmd clipboard clear" 2>/dev/null
                echo -n "" | termux-clipboard-set 2>/dev/null
                whiptail --msgbox "🧹 Portapapeles limpiado" 8 45
                ;;
            B|"") break ;;
        esac
    done
}

# ─── 5. INFORMACIÓN DE RED ──────────────────────
network_info() {
    clear
    show_banner
    echo -e "${BOLD}${WHITE}  🌐 INFORMACIÓN DE RED${NC}"
    echo -e "  ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    local wifi_state ip_addr dns mac_addr
    wifi_state=$(rsh "cmd wifi status" | grep -i "wifi is" | head -1)
    ip_addr=$(rsh "ip route get 1 2>/dev/null" | grep -oP 'src \K[\d.]+' | head -1)
    mac_addr=$(rsh "cat /sys/class/net/wlan0/address" 2>/dev/null)

    echo -e "  📡 ${BOLD}Estado WiFi:${NC}  ${GREEN}${wifi_state:-Desconocido}${NC}"
    echo -e "  🌍 ${BOLD}IP local:${NC}     ${CYAN}${ip_addr:-No disponible}${NC}"
    echo -e "  🔑 ${BOLD}MAC:${NC}          ${YELLOW}${mac_addr:-No disponible}${NC}"

    # Velocidad de descarga rápida
    echo -e "\n  ⏳ ${DIM}Midiendo velocidad de conexión...${NC}"
    local speed
    speed=$(curl -s -o /dev/null -w "%{speed_download}" \
        --max-time 5 https://github.com 2>/dev/null)
    if [ -n "$speed" ]; then
        local speed_kb=$(echo "scale=2; $speed / 1024" | bc 2>/dev/null)
        echo -e "  ⚡ ${BOLD}Velocidad:${NC}    ${GREEN}${speed_kb} KB/s${NC}"
    fi

    # Latencia
    echo -e "  🏓 ${BOLD}Ping a 8.8.8.8:${NC}"
    rsh "ping -c 3 8.8.8.8" 2>/dev/null | tail -2 | while read line; do
        echo -e "     ${CYAN}$line${NC}"
    done

    echo -e "\n  ${DIM}Actualizado: $(date '+%H:%M:%S')${NC}\n"
    read -p "  Presiona ENTER para volver al menú..."
}

# ─── 6. AUTOMATIZACIÓN RÁPIDA ──────────────────
quick_automations() {
    while true; do
        CHOICE=$(whiptail --title "⚡ AUTOMATIZACIONES RÁPIDAS" \
            --menu "\nAcciones de un clic:" 18 65 8 \
            "1" "😴  Modo Noche completo" \
            "2" "☀️   Modo Día completo" \
            "3" "🎮  Modo Gaming (máx rendimiento)" \
            "4" "🔋  Modo Ahorro de batería" \
            "5" "🧹  Matar apps en background" \
            "6" "📸  Captura de pantalla" \
            "B" "← Volver" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1)
                # Modo noche: dark mode + DND + brillo bajo
                rsh "cmd uimode night yes"
                rsh "cmd notification set_dnd priority"
                rsh "settings put system screen_brightness 30"
                rsh "settings put system accelerometer_rotation 0"
                whiptail --msgbox "😴 MODO NOCHE ACTIVADO\n\n✓ Dark Mode ON\n✓ No Molestar ON\n✓ Brillo al mínimo\n✓ Rotación bloqueada" 12 45
                ;;
            2)
                # Modo día: light + notificaciones + brillo alto
                rsh "cmd uimode night no"
                rsh "cmd notification set_dnd off"
                rsh "settings put system screen_brightness 200"
                rsh "settings put system accelerometer_rotation 1"
                whiptail --msgbox "☀️  MODO DÍA ACTIVADO\n\n✓ Light Mode ON\n✓ Notificaciones ON\n✓ Brillo alto\n✓ Rotación auto" 12 45
                ;;
            3)
                # Modo gaming
                rsh "settings put global low_power 0"
                rsh "settings put system screen_brightness 255"
                rsh "cmd notification set_dnd priority"
                rsh "settings put global game_driver_all_apps 1" 2>/dev/null
                whiptail --msgbox "🎮 MODO GAMING ACTIVADO\n\n✓ Ahorro batería OFF\n✓ Brillo máximo\n✓ DND ON\n✓ Performance mode" 12 45
                ;;
            4)
                # Modo ahorro
                rsh "settings put global low_power 1"
                rsh "settings put system screen_brightness 50"
                rsh "cmd connectivity airplane-mode disable"
                whiptail --msgbox "🔋 MODO AHORRO ACTIVADO\n\n✓ Battery saver ON\n✓ Brillo reducido\n✓ Sync reducido" 12 45
                ;;
            5)
                # Matar apps en background
                local killed_count=0
                local apps_bg
                apps_bg=$(rsh "am dump | grep 'Activities in' -A2" 2>/dev/null | grep -oP 'com\.\S+' | head -10)
                for app in $apps_bg; do
                    [[ "$app" == *"termux"* ]] && continue
                    [[ "$app" == *"shizuku"* ]] && continue
                    rsh "am force-stop $app" 2>/dev/null
                    ((killed_count++))
                done
                whiptail --msgbox "🧹 Apps en background detenidas\n\nProcesadas: ~${killed_count} apps" 10 45
                ;;
            6)
                local screenshot_path="/sdcard/DCIM/Screenshots/droidpanel_$(date +%Y%m%d_%H%M%S).png"
                rsh "screencap -p '$screenshot_path'"
                whiptail --msgbox "📸 Screenshot guardado en:\n\n$screenshot_path" 10 60
                ;;
            B|"") break ;;
        esac
    done
}

# ─── MENÚ PRINCIPAL ─────────────────────────────
main_menu() {
    check_deps

    while true; do
        show_banner

        CHOICE=$(whiptail --title "DROID PANEL │ Termux + Shizuku" \
            --menu "Selecciona una opción:" 20 65 8 \
            "1" "📊  Estadísticas del sistema" \
            "2" "⚙️   Control del sistema" \
            "3" "📱  Gestor de aplicaciones" \
            "4" "📋  Portapapeles" \
            "5" "🌐  Información de red" \
            "6" "⚡  Automatizaciones rápidas" \
            "Q" "🚪  Salir" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1) show_stats ;;
            2) system_controls ;;
            3) app_manager ;;
            4) clipboard_manager ;;
            5) network_info ;;
            6) quick_automations ;;
            Q|"")
                clear
                echo -e "\n  ${CYAN}╔══════════════════════════════╗${NC}"
                echo -e "  ${CYAN}║  Hasta luego! 👋             ║${NC}"
                echo -e "  ${CYAN}║  Droid Panel by @TechGenius   ║${NC}"
                echo -e "  ${CYAN}╚══════════════════════════════╝${NC}\n"
                exit 0
                ;;
        esac
    done
}

# ─── Inicio ─────────────────────────────────────
main_menu
