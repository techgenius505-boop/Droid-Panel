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
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── Ejecutar comando via Shizuku/rish ──────────
rsh() {
    rish -c "$1" 2>/dev/null
}

# ─── Verificar dependencias ─────────────────────
check_deps() {
    local missing=()
    for dep in rish whiptail; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo -e "${RED}✗ Faltan: ${missing[*]}${NC}"
        exit 1
    fi
    # Verificar que rish/Shizuku responde
    local test_rsh
    test_rsh=$(rsh "echo ok" 2>&1)
    if [ "$test_rsh" != "ok" ]; then
        echo -e "${RED}✗ Shizuku no responde. Abre la app Shizuku y asegúrate de que esté activo.${NC}"
        echo -e "${YELLOW}Luego autoriza Termux cuando aparezca el popup.${NC}"
        read -p "Presiona ENTER para salir..."
        exit 1
    fi
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
    battery_level=$(rsh "dumpsys battery" | grep "  level:" | grep -oP '\d+')
    battery_status=$(rsh "dumpsys battery" | grep "  status:" | grep -oP '\d+')
    battery_temp=$(rsh "dumpsys battery" | grep "  temperature:" | grep -oP '\d+')
    battery_temp_c=$(echo "scale=1; ${battery_temp:-0} / 10" | bc 2>/dev/null || echo "?")

    local bat_status_str="Desconocido"
    case $battery_status in
        2) bat_status_str="${GREEN}Cargando ⚡${NC}" ;;
        3) bat_status_str="${YELLOW}Descargando${NC}" ;;
        5) bat_status_str="${GREEN}Llena ✓${NC}" ;;
    esac

    local filled=$(( ${battery_level:-0} / 10 ))
    local empty=$(( 10 - filled ))
    local bat_bar="${GREEN}"
    [ "${battery_level:-100}" -lt 30 ] && bat_bar="${RED}"
    [ "${battery_level:-100}" -lt 60 ] && [ "${battery_level:-100}" -ge 30 ] && bat_bar="${YELLOW}"
    local bar="${bat_bar}["
    for i in $(seq 1 $filled); do bar+="█"; done
    for i in $(seq 1 $empty); do bar+="░"; done
    bar+="]${NC}"
    echo -e "  🔋 ${BOLD}Batería:${NC}     $bar ${bat_bar}${battery_level:-?}%${NC} │ Estado: $bat_status_str │ Temp: ${battery_temp_c}°C"

    # RAM
    local mem_total mem_avail
    mem_total=$(rsh "cat /proc/meminfo" | grep "MemTotal" | grep -oP '\d+' | head -1)
    mem_avail=$(rsh "cat /proc/meminfo" | grep "MemAvailable" | grep -oP '\d+' | head -1)
    if [ -n "$mem_total" ] && [ -n "$mem_avail" ] && [ "$mem_total" -gt 0 ]; then
        local mem_used=$(( (mem_total - mem_avail) / 1024 ))
        local mem_total_mb=$(( mem_total / 1024 ))
        local mem_pct=$(( (mem_total - mem_avail) * 100 / mem_total ))
        local mem_bar_filled=$(( mem_pct / 10 ))
        local mem_bar="["
        for i in $(seq 1 $mem_bar_filled); do mem_bar+="█"; done
        for i in $(seq 1 $(( 10 - mem_bar_filled ))); do mem_bar+="░"; done
        mem_bar+="]"
        echo -e "  💾 ${BOLD}RAM:${NC}         ${CYAN}${mem_bar}${NC} ${CYAN}${mem_used}MB / ${mem_total_mb}MB${NC} (${mem_pct}%)"
    fi

    # Uptime
    local uptime_str
    uptime_str=$(rsh "cat /proc/uptime" | awk '{s=$1; h=int(s/3600); m=int((s%3600)/60); printf "%dh %dm", h, m}')
    echo -e "  ⏱️  ${BOLD}Uptime:${NC}      ${MAGENTA}${uptime_str}${NC}"

    # Almacenamiento
    local storage_info
    storage_info=$(rsh "df /data" | tail -1 | awk '{printf "%dGB usado / %dGB total", $3/1024/1024, $2/1024/1024}')
    echo -e "  💿 ${BOLD}Almacen.:${NC}    ${YELLOW}${storage_info:-N/A}${NC}"

    # Dispositivo
    local model android_ver
    model=$(rsh "getprop ro.product.model")
    android_ver=$(rsh "getprop ro.build.version.release")
    echo -e "\n  📱 ${BOLD}Dispositivo:${NC} ${WHITE}${model:-?}${NC} │ Android ${WHITE}${android_ver:-?}${NC}"

    # Red - métodos alternativos para Motorola
    local wifi_ssid ip_addr
    # IP: usar ifconfig de wlan0 directamente
    ip_addr=$(rsh "ifconfig wlan0 2>/dev/null" | grep -oP 'inet addr:\K[\d.]+' | head -1)
    [ -z "$ip_addr" ] && ip_addr=$(rsh "ip addr show wlan0 2>/dev/null" | grep -oP 'inet \K[\d.]+' | head -1)
    # SSID
    wifi_ssid=$(rsh "dumpsys wifi" | grep -oP '(?<=SSID: )[^,]+' | head -1 | tr -d '"')
    [ -z "$wifi_ssid" ] && wifi_ssid=$(rsh "cmd wifi status" | grep -oP '(?<=SSID=)[^\s,]+' | head -1)
    # MAC
    local mac_addr
    mac_addr=$(rsh "cat /sys/class/net/wlan0/address" 2>/dev/null)
    [ -z "$mac_addr" ] && mac_addr=$(rsh "ip link show wlan0" | grep -oP 'link/ether \K[\da-f:]+' | head -1)

    echo -e "  🌐 ${BOLD}WiFi:${NC}        ${GREEN}${wifi_ssid:-Sin WiFi}${NC}"
    echo -e "  🌍 ${BOLD}IP local:${NC}    ${CYAN}${ip_addr:-No disponible}${NC}"
    echo -e "  🔑 ${BOLD}MAC:${NC}         ${YELLOW}${mac_addr:-No disponible}${NC}"

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
            1) rsh "cmd uimode night yes"; whiptail --msgbox "🌙 Dark Mode ACTIVADO" 8 40 ;;
            2) rsh "cmd uimode night no"; whiptail --msgbox "☀️  Dark Mode DESACTIVADO" 8 40 ;;
            3) rsh "cmd notification set_dnd priority"; whiptail --msgbox "🔕 No Molestar ACTIVADO" 8 40 ;;
            4) rsh "cmd notification set_dnd off"; whiptail --msgbox "🔔 No Molestar DESACTIVADO" 8 40 ;;
            5) rsh "cmd connectivity airplane-mode enable"; whiptail --msgbox "✈️  Modo Avión ACTIVADO" 8 40 ;;
            6) rsh "cmd connectivity airplane-mode disable"; whiptail --msgbox "📡 Modo Avión DESACTIVADO" 8 40 ;;
            7)
                rsh "settings put system screen_brightness_mode 0"
                rsh "settings put system screen_brightness 255"
                whiptail --msgbox "🔆 Brillo al MÁXIMO" 8 40
                ;;
            8)
                # En Motorola el 0 puede apagar pantalla, usamos 1
                rsh "settings put system screen_brightness_mode 0"
                rsh "settings put system screen_brightness 1"
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
            "4" "🗑️   Desinstalar app (usuario)" \
            "5" "🔒  Deshabilitar app del sistema" \
            "6" "✅  Habilitar app" \
            "B" "← Volver" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1)
                local tmp_file
                tmp_file=$(mktemp)
                echo "=== APPS DE USUARIO ===" > "$tmp_file"
                rsh "pm list packages -3" | sed 's/package://g' | sort >> "$tmp_file"
                echo "" >> "$tmp_file"
                echo "=== APPS DEL SISTEMA ===" >> "$tmp_file"
                rsh "pm list packages -s" | sed 's/package://g' | sort >> "$tmp_file"
                local count
                count=$(rsh "pm list packages -3" | wc -l)
                whiptail --title "Apps instaladas (~${count} de usuario)" \
                    --textbox "$tmp_file" 30 70
                rm -f "$tmp_file"
                ;;
            2)
                PKG=$(whiptail --inputbox "Package name a abrir:\n(ej: org.telegram.messenger)" \
                    10 60 --title "Abrir App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    # Resolver el activity correcto con cmd package resolve-activity
                    ACTIVITY=$(rsh "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER $PKG" | tail -1)
                    if [ -n "$ACTIVITY" ] && [[ "$ACTIVITY" != "No activity"* ]] && [[ "$ACTIVITY" != *"error"* ]]; then
                        RESULT=$(rsh "am start -n $ACTIVITY")
                        whiptail --msgbox "🚀 Abriendo:\n$PKG\n\nActivity: $ACTIVITY" 11 60
                    else
                        whiptail --msgbox "❌ No se encontró launcher para:\n$PKG\n\nVerifica que el package name sea correcto." 11 60
                    fi
                fi
                ;;
            3)
                PKG=$(whiptail --inputbox "Package name a cerrar:" \
                    10 60 --title "Forzar Cierre" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    # Verificar que el paquete existe
                    EXISTS=$(rsh "pm list packages $PKG" | grep -c "$PKG")
                    if [ "$EXISTS" -gt 0 ]; then
                        rsh "am force-stop $PKG"
                        sleep 0.3
                        rsh "am kill $PKG"
                        whiptail --msgbox "⏹️  App detenida:\n$PKG" 9 55
                    else
                        whiptail --msgbox "❌ Paquete no encontrado:\n$PKG" 9 55
                    fi
                fi
                ;;
            4)
                PKG=$(whiptail --inputbox "Package name a desinstalar:\n(solo apps de usuario, no del sistema)" \
                    10 60 --title "Desinstalar App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    # Verificar que es app de usuario
                    IS_USER=$(rsh "pm list packages -3" | grep -c "package:$PKG")
                    if [ "$IS_USER" -gt 0 ]; then
                        if whiptail --yesno "¿Desinstalar permanentemente?\n\n$PKG" 9 60; then
                            RESULT=$(rsh "pm uninstall --user 0 $PKG")
                            if echo "$RESULT" | grep -qi "success"; then
                                whiptail --msgbox "✅ Desinstalado correctamente:\n$PKG" 9 55
                            else
                                whiptail --msgbox "⚠️  Resultado:\n${RESULT:-sin respuesta}" 9 55
                            fi
                        fi
                    else
                        whiptail --msgbox "❌ No encontrado como app de usuario:\n$PKG\n\nPara apps del sistema usa 'Deshabilitar'." 11 60
                    fi
                fi
                ;;
            5)
                PKG=$(whiptail --inputbox "Package name a deshabilitar:\n(funciona con apps del sistema)" \
                    10 60 --title "Deshabilitar App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    RESULT=$(rsh "pm disable-user --user 0 $PKG")
                    if echo "$RESULT" | grep -qi "disabled\|success"; then
                        whiptail --msgbox "🔒 App deshabilitada:\n$PKG\n\nNo aparecerá en el launcher ni consumirá recursos." 11 60
                    else
                        whiptail --msgbox "⚠️  Resultado:\n${RESULT:-sin respuesta}" 9 55
                    fi
                fi
                ;;
            6)
                PKG=$(whiptail --inputbox "Package name a habilitar:" \
                    10 60 --title "Habilitar App" 3>&1 1>&2 2>&3)
                if [ -n "$PKG" ]; then
                    RESULT=$(rsh "pm enable --user 0 $PKG")
                    if echo "$RESULT" | grep -qi "enabled\|success"; then
                        whiptail --msgbox "✅ App habilitada:\n$PKG" 9 55
                    else
                        whiptail --msgbox "⚠️  Resultado:\n${RESULT:-sin respuesta}" 9 55
                    fi
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
            --menu "\nQué quieres hacer:" 16 60 5 \
            "1" "👁️   Leer portapapeles" \
            "2" "✏️   Copiar texto al portapapeles" \
            "3" "⌨️   Escribir texto en app activa" \
            "4" "🧹  Limpiar portapapeles" \
            "B" "← Volver" \
            3>&1 1>&2 2>&3)

        case $CHOICE in
            1)
                local content
                # Intentar con timeout para evitar que se quede pegado
                content=$(timeout 3 termux-clipboard-get 2>/dev/null)
                if [ -z "$content" ]; then
                    content="(vacío o no se pudo leer)"
                fi
                whiptail --msgbox "📋 Portapapeles:\n\n${content}" 15 65 --title "Portapapeles"
                ;;
            2)
                local new_content
                new_content=$(whiptail --inputbox "Texto a copiar:" \
                    10 60 --title "Copiar al portapapeles" 3>&1 1>&2 2>&3)
                if [ -n "$new_content" ]; then
                    # Usar timeout para evitar colgarse
                    if timeout 4 bash -c "echo -n '$new_content' | termux-clipboard-set" 2>/dev/null; then
                        whiptail --msgbox "✅ Copiado:\n\n$new_content" 10 55
                    else
                        whiptail --msgbox "⚠️  No se pudo copiar automáticamente.\nUsa la opción 3 para escribir en una app." 9 58
                    fi
                fi
                ;;
            3)
                local text_to_type
                text_to_type=$(whiptail --inputbox "Texto a escribir en la app activa:\n\nAbre la app y pon el cursor donde\nquieras el texto ANTES de confirmar." \
                    12 60 --title "Escribir en app activa" 3>&1 1>&2 2>&3)
                if [ -n "$text_to_type" ]; then
                    whiptail --infobox "⌨️  Enviando texto en 3 segundos...\n\nPon el cursor en el campo de texto." 8 55
                    sleep 3
                    # Escapar espacios (input text usa %s para espacios)
                    local escaped
                    escaped=$(printf '%s' "$text_to_type" | sed 's/ /%s/g')
                    rsh "input text '$escaped'"
                    whiptail --msgbox "✅ Texto enviado a la app" 7 45
                fi
                ;;
            4)
                timeout 4 bash -c "echo -n '' | termux-clipboard-set" 2>/dev/null
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

    # IP - múltiples métodos
    local ip_addr
    ip_addr=$(rsh "ifconfig wlan0 2>/dev/null" | grep -oP 'inet addr:\K[\d.]+' | head -1)
    [ -z "$ip_addr" ] && ip_addr=$(rsh "ip addr show wlan0 2>/dev/null" | grep -oP 'inet \K[\d.]+' | head -1)
    [ -z "$ip_addr" ] && ip_addr=$(rsh "ip route get 8.8.8.8 2>/dev/null" | grep -oP 'src \K[\d.]+' | head -1)

    # MAC
    local mac_addr
    mac_addr=$(rsh "cat /sys/class/net/wlan0/address" 2>/dev/null)
    [ -z "$mac_addr" ] && mac_addr=$(rsh "ip link show wlan0 2>/dev/null" | grep -oP 'link/ether \K[\da-f:]+')

    # SSID
    local wifi_ssid
    wifi_ssid=$(rsh "dumpsys wifi" | grep -oP '(?<=SSID: )[^,]+' | head -1 | tr -d '"')
    [ -z "$wifi_ssid" ] && wifi_ssid=$(rsh "dumpsys netstats" | grep -oP '(?<=iface=wlan0).*' | head -1)

    # Gateway
    local gateway
    gateway=$(rsh "ip route show default 2>/dev/null" | grep -oP 'via \K[\d.]+' | head -1)

    echo -e "  📶 ${BOLD}Red WiFi:${NC}    ${GREEN}${wifi_ssid:-No detectado}${NC}"
    echo -e "  🌍 ${BOLD}IP local:${NC}    ${CYAN}${ip_addr:-No disponible}${NC}"
    echo -e "  🔑 ${BOLD}MAC:${NC}         ${YELLOW}${mac_addr:-No disponible}${NC}"
    echo -e "  🔀 ${BOLD}Gateway:${NC}     ${MAGENTA}${gateway:-No disponible}${NC}"

    # Ping
    echo -e "\n  ⏳ ${DIM}Midiendo latencia...${NC}"
    local ping_result
    ping_result=$(ping -c 3 -W 2 8.8.8.8 2>/dev/null | tail -1)
    echo -e "  🏓 ${BOLD}Ping:${NC}        ${CYAN}${ping_result:-No disponible}${NC}"

    # Velocidad aproximada con curl
    if command -v curl &>/dev/null; then
        echo -e "  ⏳ ${DIM}Midiendo velocidad (5s)...${NC}"
        local speed
        speed=$(curl -s -o /dev/null -w "%{speed_download}" --max-time 5 https://github.com 2>/dev/null)
        if [ -n "$speed" ] && [ "$speed" != "0" ]; then
            local speed_kb
            speed_kb=$(echo "scale=1; $speed / 1024" | bc 2>/dev/null)
            echo -e "  ⚡ ${BOLD}Velocidad:${NC}   ${GREEN}~${speed_kb} KB/s${NC}"
        fi
    fi

    echo -e "\n  ${DIM}Actualizado: $(date '+%H:%M:%S')${NC}\n"
    read -p "  Presiona ENTER para volver al menú..."
}

# ─── 6. AUTOMATIZACIÓN RÁPIDA ──────────────────
quick_automations() {
    while true; do
        CHOICE=$(whiptail --title "⚡ AUTOMATIZACIONES RÁPIDAS" \
            --menu "\nAcciones de un clic:" 18 65 6 \
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
                rsh "cmd uimode night yes"
                rsh "cmd notification set_dnd priority"
                rsh "settings put system screen_brightness_mode 0"
                rsh "settings put system screen_brightness 1"
                rsh "settings put system accelerometer_rotation 0"
                whiptail --msgbox "😴 MODO NOCHE ACTIVADO\n\n✓ Dark Mode ON\n✓ No Molestar ON\n✓ Brillo mínimo\n✓ Rotación bloqueada" 12 45
                ;;
            2)
                rsh "cmd uimode night no"
                rsh "cmd notification set_dnd off"
                rsh "settings put system screen_brightness_mode 1"
                rsh "settings put system accelerometer_rotation 1"
                whiptail --msgbox "☀️  MODO DÍA ACTIVADO\n\n✓ Light Mode ON\n✓ Notificaciones ON\n✓ Brillo automático\n✓ Rotación auto" 12 45
                ;;
            3)
                rsh "settings put global low_power 0"
                rsh "settings put system screen_brightness_mode 0"
                rsh "settings put system screen_brightness 255"
                rsh "cmd notification set_dnd priority"
                whiptail --msgbox "🎮 MODO GAMING ACTIVADO\n\n✓ Battery saver OFF\n✓ Brillo máximo\n✓ DND ON" 12 45
                ;;
            4)
                rsh "settings put global low_power 1"
                rsh "settings put system screen_brightness_mode 0"
                rsh "settings put system screen_brightness 30"
                whiptail --msgbox "🔋 MODO AHORRO ACTIVADO\n\n✓ Battery saver ON\n✓ Brillo reducido" 12 45
                ;;
            5)
                whiptail --infobox "🧹 Detectando apps en background..." 6 50
                local apps_bg killed_count=0
                # Listar pids de apps en background
                apps_bg=$(rsh "am dump" | grep "Proc #" | grep -oP '\{[^\}]+\}' | grep -oP 'com\.[^\s]+' | grep -v "termux\|shizuku" | sort -u | head -15)
                for app in $apps_bg; do
                    rsh "am force-stop $app" 2>/dev/null
                    ((killed_count++))
                done
                whiptail --msgbox "🧹 Listo!\n\nApps procesadas: ${killed_count}" 9 40
                ;;
            6)
                # Screenshot - guardar en Screenshots con nombre único
                local ts
                ts=$(date +%Y%m%d_%H%M%S)
                local path="/sdcard/Pictures/droidpanel_${ts}.png"
                rsh "screencap -p $path"
                sleep 1
                # Verificar si existe
                local existe
                existe=$(rsh "ls $path 2>/dev/null")
                if [ -n "$existe" ]; then
                    # Notificar a la galería
                    rsh "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://$path"
                    whiptail --msgbox "📸 Screenshot guardado!\n\nRuta: $path\n\n✓ Visible en Galería > Pictures" 11 60
                else
                    whiptail --msgbox "⚠️  No se pudo guardar.\nVerifica permisos de almacenamiento en Termux." 9 55
                fi
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
            --menu "Selecciona una opción:" 20 65 7 \
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

main_menu
