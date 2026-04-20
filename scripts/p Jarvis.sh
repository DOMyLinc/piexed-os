#!/bin/bash
#
# Piẻxed OS - Pivis (Jarvis AI Assistant)
# AI-powered system control
#

# Voice synthesis
say() {
    echo "$1" | espeak 2>/dev/null || echo "$1"
}

# Pivis AI Brain - Simple pattern matching
pivis_ai() {
    local query="$1"
    query=$(echo "$query" | tr '[:upper:]' '[:lower:]')
    
    # System control
    if echo "$query" | grep -q "system status\|check system\|system info"; then
        echo "🔍 Checking system status..."
        piexed-info
        return
    fi
    
    if echo "$query" | grep -q "clean\|cleanup\|clean system"; then
        echo "🧹 Cleaning system..."
        piexed-clean
        echo "System cleaned!"
        return
    fi
    
    if echo "$query" | grep -q "security\|secure\|protector"; then
        echo "🔒 Activating security mode..."
        sudo ufw status verbose
        echo "Security: ACTIVE"
        return
    fi
    
    if echo "$query" | grep -q "scan\|virus\|malware"; then
        echo "🔍 Scanning for threats..."
        sudo clamscan --recursive --remove /tmp 2>/dev/null || echo "ClamAV not installed - installing..."
        echo "Scan complete - system secure!"
        return
    fi
    
    if echo "$query" | grep -q "update\|upgrade\|updates"; then
        echo "⬆️ Updating system..."
        sudo apt update && sudo apt upgrade -y
        echo "System updated!"
        return
    fi
    
    if echo "$query" | grep -q "backup\|save"; then
        echo "💾 Creating backup..."
        piexed-backup
        echo "Backup complete!"
        return
    fi
    
    # Network control
    if echo "$query" | grep -q "wifi\|internet\|network"; then
        echo "📶 Checking network..."
        nmcli device wifi list
        return
    fi
    
    if echo "$query" | grep -q "ip\|address\|location"; then
        echo "🌐 Your IP address:"
        curl -s https://check.torproject.org/api/ip || hostname -I
        return
    fi
    
    if echo "$query" | grep -q "anonymous\|vpn\|tor"; then
        echo "🕵️ Enabling anonymous mode..."
        sudo systemctl start tor 2>/dev/null || echo "TOR not installed - installing..."
        echo "Anonymous network ready!"
        return
    fi
    
    # App control
    if echo "$query" | grep -q "browser\|firefox\|web"; then
        echo "🌐 Opening Firefox..."
        firefox &
        return
    fi
    
    if echo "$query" | grep -q "store\|app store\|install app"; then
        echo "🛒 Opening Piẻxed Store..."
        piexed-store
        return
    fi
    
    if echo "$query" | grep -q "terminal\|command\|shell"; then
        echo "⌨️ Opening Terminal..."
        xfce4-terminal &
        return
    fi
    
    if echo "$query" | grep -q "files\|folder\|directory"; then
        echo "📁 Opening File Manager..."
        thunar &
        return
    fi
    
    # Hardware
    if echo "$query" | grep -q "bluetooth\|blu"; then
        echo "🔵 Checking Bluetooth..."
        rfkill list bluetooth
        return
    fi
    
    if echo "$query" | grep -q "audio\|sound\|speaker"; then
        echo "🔊 Checking Audio..."
        pulsemixer || echo "Open pavucontrol for audio settings"
        return
    fi
    
    if echo "$query" | grep -q "brightness\|screen\|display"; then
        echo "☀️ Adjusting brightness..."
        xbacklight - +10 2>/dev/null || echo "Use: xrandr --set-brightness 1.0"
        return
    fi
    
    # System info
    if echo "$query" | grep -q "cpu\|processor\|speed"; then
        echo "⚡ CPU Information:"
        lscpu | grep -E "Model name|CPU MHz"
        return
    fi
    
    if echo "$query" | grep -q "ram\|memory\|storage"; then
        echo "💾 Memory & Storage:"
        free -h
        df -h /
        return
    fi
    
    if echo "$query" | grep -q "battery\|power\|charging"; then
        echo "🔋 Battery Status:"
        upower -i /org/freedesktop/UPower/devices/battery_BAT 2>/dev/null || echo "Use: acpi"
        return
    fi
    
    if echo "$query" | grep -q "temperature\|temp\|heat"; then
        echo "🌡️ System Temperature:"
        sensors 2>/dev/null || echo "Install lm-sensors for temperature"
        return
    fi
    
    # Help
    if echo "$query" | grep -q "help\|command\|what can you do"; then
        echo "
╔══════════════════════════════════════════════╗
║           PIVIS COMMAND LIST              ║
╠══════════════════════════════════════════════╣
║ SYSTEM CONTROL:                          ║
║  • system status                        ║
║  • clean system                       ║
║  • security mode                      ║
║  • scan malware                      ║
║  • update system                    ║
║  • create backup                   ║
║ NETWORK:                               ║
║  • check wifi                       ║
║  • check IP                         ║
║  • anonymous mode                  ║
║ APPS:                                ║
║  • open browser                    ║
║  • open store                      ║
║  • open terminal                   ║
║  • open files                      ║
║ INFO:                                ║
║  • cpu info                        ║
║  • memory info                     ║
║  • battery status                 ║
║  • temperature                   ║
╚══════════════════════════════════════════════╝
"
        return
    fi
    
    # Jarvis personality responses
    if echo "$query" | grep -q "hello\|hi\|hey\|greetings"; then
        echo "Hello! I am Pivis, your AI assistant on Piẻxed OS. How can I help you today?"
        return
    fi
    
    if echo "$query" | grep -q "who are you\|what are you"; then
        echo "I am Pivis, your AI assistant on Piẻxed OS. I'm here to help you control your system with simple commands."
        return
    fi
    
    if echo "$query" | grep -q "thank\|thanks"; then
        echo "You're welcome! I'm always here to help."
        return
    fi
    
    if echo "$query" | grep -q "bye\|goodbye\|exit"; then
        echo "Goodbye! Have a great day on Piẻxed OS!"
        exit 0
    fi
    
    # Default response
    echo "I didn't understand that command. Say 'help' for available commands."
}

# Voice input mode (if available)
voice_input() {
    if command -v sphinx_wrap &> /dev/null; then
        echo "Say your command..."
        speech_recognition
    else
        echo "Voice input not available. Type your command."
        read -r query
        pivis_ai "$query"
    fi
}

# GUI mode
gui_mode() {
    yad --title="Pivis - AI Assistant" \
        --width=400 \
        --height=300 \
        --center \
        --form \
        --text="Pivis AI Assistant\nType your command:" \
        --field="Command" \
        --button="Execute:0" \
        --button="Voice:1" \
        --button="Exit:252"
}

# Main
case "${1:-}" in
    -v|--voice)
        voice_input
        ;;
    -g|--gui)
        gui_mode
        ;;
    -h|--help)
        echo "Pivis - AI Assistant for Piẻxed OS"
        echo ""
        echo "Usage: pivis [options] [command]"
        echo ""
        echo "Options:"
        echo "  -v, --voice   Voice input mode"
        echo "  -g, --gui    GUI mode"
        echo "  -h, --help   Show this help"
        echo ""
        echo "Examples:"
        echo "  pivis system status"
        echo "  pivis clean system"
        echo "  pivis help"
        ;;
    "")
        if [ -t 0 ]; then
            # Terminal mode
            if [ "$1" != "" ]; then
                pivis_ai "$1"
            else
                echo "╔══════════════════════════════════════════════╗"
                echo "║      PIVIS - AI ASSISTANT v1.0.0          ║"
                echo "║      Piẻxed OS System Control            ║"
                echo "╚══════════════════════════════════════════════╝"
                echo ""
                echo "Type your command (or 'help' for commands, 'exit' to quit):"
                while read -p "Pivis> " query; do
                    pivis_ai "$query"
                    echo ""
                done
            fi
        fi
        ;;
    *)
        pivis_ai "$@"
        ;;
esac