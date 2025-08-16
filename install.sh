#!/bin/sh
# Installation script for Page Reloader Tool
# For OpenWrt Router

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Installation paths
INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/page-reloader"
SERVICE_DIR="/etc/init.d"
LOG_DIR="/var/log"
WEB_DIR="/www"
CGI_DIR="/www/cgi-bin"

# Files
SCRIPT_NAME="page-reloader"
SERVICE_NAME="page-reloader"
GUI_ENABLED=1

# Print colored messages
print_msg() {
    echo -e "$1"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_msg "${RED}Error: Installation must be run as root${NC}"
        exit 1
    fi
}

# Check OpenWrt system
check_openwrt() {
    if [ ! -f "/etc/openwrt_release" ]; then
        print_msg "${YELLOW}Warning: This doesn't appear to be an OpenWrt system${NC}"
        print_msg "${BLUE}Continuing anyway...${NC}"
    else
        print_msg "${GREEN}OpenWrt system detected${NC}"
        . /etc/openwrt_release
        print_msg "${BLUE}OpenWrt Version: $DISTRIB_DESCRIPTION${NC}"
    fi
}

# Install dependencies
install_dependencies() {
    print_msg "${BLUE}Checking dependencies...${NC}"
    
    # Update package lists
    opkg update >/dev/null 2>&1
    
    # Check for curl or wget
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        print_msg "${YELLOW}Installing wget (required for URL checking)...${NC}"
        if ! opkg install wget; then
            print_msg "${RED}Failed to install wget. Please install manually.${NC}"
            exit 1
        fi
    fi
    
    print_msg "${GREEN}Dependencies satisfied${NC}"
}

# Create directories
create_directories() {
    print_msg "${BLUE}Creating directories...${NC}"
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    print_msg "${GREEN}Directories created${NC}"
}

# Install main script
install_script() {
    print_msg "${BLUE}Installing page reloader script...${NC}"
    
    if [ ! -f "page-reloader.sh" ]; then
        print_msg "${RED}Error: page-reloader.sh not found in current directory${NC}"
        exit 1
    fi
    
    # Copy and make executable
    cp "page-reloader.sh" "$INSTALL_DIR/$SCRIPT_NAME"
    chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
    
    print_msg "${GREEN}Script installed to $INSTALL_DIR/$SCRIPT_NAME${NC}"
}

# Install web GUI
install_web_gui() {
    if [ "$GUI_ENABLED" = "1" ] && [ -d "web-gui" ]; then
        print_msg "${BLUE}Installing web GUI...${NC}"
        
        # Create web directories
        mkdir -p "$WEB_DIR/page-reloader"
        mkdir -p "$CGI_DIR"
        
        # Copy GUI files
        if [ -f "web-gui/index.html" ]; then
            cp "web-gui/index.html" "$WEB_DIR/page-reloader/"
            print_msg "${GREEN}Web interface installed${NC}"
        fi
        
        if [ -f "web-gui/app.js" ]; then
            cp "web-gui/app.js" "$WEB_DIR/page-reloader/"
            print_msg "${GREEN}JavaScript app installed${NC}"
        fi
        
        # Install CGI API
        if [ -f "web-gui/page-reloader-api" ]; then
            cp "web-gui/page-reloader-api" "$CGI_DIR/"
            chmod +x "$CGI_DIR/page-reloader-api"
            print_msg "${GREEN}API backend installed${NC}"
        fi
        
        # Check if uhttpd is running (OpenWrt web server)
        if pgrep uhttpd >/dev/null 2>&1; then
            print_msg "${GREEN}Web server is running${NC}"
            print_msg "${BLUE}GUI will be available at: http://router-ip/page-reloader/${NC}"
        else
            print_msg "${YELLOW}Warning: Web server (uhttpd) not running${NC}"
            print_msg "${BLUE}Install uhttpd: opkg install uhttpd${NC}"
        fi
    else
        print_msg "${YELLOW}Web GUI not available (missing web-gui directory)${NC}"
    fi
}

# Create init script for OpenWrt
create_init_script() {
    print_msg "${BLUE}Creating init script...${NC}"
    
    cat > "$SERVICE_DIR/$SERVICE_NAME" << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

SERVICE_NAME="page-reloader"
SERVICE_BIN="/usr/bin/page-reloader"
SERVICE_PID_FILE="/var/run/page-reloader.pid"

start() {
    echo "Starting $SERVICE_NAME"
    
    # Check if already running
    if [ -f "$SERVICE_PID_FILE" ] && kill -0 "$(cat "$SERVICE_PID_FILE")" 2>/dev/null; then
        echo "$SERVICE_NAME is already running"
        return 1
    fi
    
    # Start the service
    $SERVICE_BIN start
    
    if [ $? -eq 0 ]; then
        echo "$SERVICE_NAME started successfully"
        return 0
    else
        echo "Failed to start $SERVICE_NAME"
        return 1
    fi
}

stop() {
    echo "Stopping $SERVICE_NAME"
    
    $SERVICE_BIN stop
    
    if [ $? -eq 0 ]; then
        echo "$SERVICE_NAME stopped successfully"
        return 0
    else
        echo "Failed to stop $SERVICE_NAME"
        return 1
    fi
}

restart() {
    echo "Restarting $SERVICE_NAME"
    stop
    sleep 2
    start
}

status() {
    $SERVICE_BIN status
}

reload() {
    restart
}
EOF
    
    chmod +x "$SERVICE_DIR/$SERVICE_NAME"
    print_msg "${GREEN}Init script created${NC}"
}

# Enable service
enable_service() {
    print_msg "${BLUE}Enabling service...${NC}"
    
    # Enable service to start on boot
    /etc/init.d/$SERVICE_NAME enable
    
    print_msg "${GREEN}Service enabled for automatic startup${NC}"
}

# Create default configuration
create_default_config() {
    print_msg "${BLUE}Creating default configuration...${NC}"
    
    if [ ! -f "$CONFIG_DIR/config" ]; then
        cat > "$CONFIG_DIR/config" << EOF
# Page Reloader Configuration
# Edit this file to configure your page monitoring

# Check interval in seconds
CHECK_INTERVAL=30

# Connection timeout in seconds
TIMEOUT=10

# Number of retry attempts
RETRY_COUNT=3

# URLs to monitor (space-separated)
# Examples:
# URLS="http://192.168.1.1 http://google.com https://github.com"
URLS=""

# Logging settings
ENABLE_LOG=1
ENABLE_SYSLOG=0
EOF
        print_msg "${GREEN}Default configuration created at $CONFIG_DIR/config${NC}"
    else
        print_msg "${YELLOW}Configuration file already exists${NC}"
    fi
}

# Show installation summary
show_summary() {
    print_msg "\n${GREEN}=== Installation Complete ===${NC}"
    print_msg "${BLUE}Script location:${NC} $INSTALL_DIR/$SCRIPT_NAME"
    print_msg "${BLUE}Configuration:${NC} $CONFIG_DIR/config"
    print_msg "${BLUE}Service control:${NC} /etc/init.d/$SERVICE_NAME"
    print_msg "${BLUE}Logs:${NC} $LOG_DIR/page-reloader.log"
    
    if [ "$GUI_ENABLED" = "1" ] && [ -d "web-gui" ]; then
        print_msg "${BLUE}Web GUI:${NC} http://router-ip/page-reloader/"
        print_msg "${BLUE}API Endpoint:${NC} /cgi-bin/page-reloader-api"
    fi
    
    print_msg "\n${YELLOW}Next steps:${NC}"
    
    if [ "$GUI_ENABLED" = "1" ] && [ -d "web-gui" ]; then
        print_msg "1. ${GREEN}Web Interface:${NC} Open http://router-ip/page-reloader/ in browser"
        print_msg "2. ${GREEN}Command Line:${NC} Use ${BLUE}$SCRIPT_NAME${NC} commands"
    else
        print_msg "1. Edit configuration: ${BLUE}$SCRIPT_NAME config${NC}"
        print_msg "2. Test URLs: ${BLUE}$SCRIPT_NAME test${NC}"
    fi
    
    print_msg "3. Start service: ${BLUE}/etc/init.d/$SERVICE_NAME start${NC}"
    print_msg "4. Check status: ${BLUE}$SCRIPT_NAME status${NC}"
    
    print_msg "\n${GREEN}Service will start automatically on boot${NC}"
    
    if [ "$GUI_ENABLED" = "1" ] && [ -d "web-gui" ]; then
        print_msg "\n${GREEN}🌐 Web GUI Features:${NC}"
        print_msg "  ✅ Browser-based management"
        print_msg "  ✅ Real-time monitoring"
        print_msg "  ✅ Easy URL management"
        print_msg "  ✅ Timing control"
        print_msg "  ✅ System logs"
        print_msg "  ✅ Mobile responsive"
    fi
}

# Main installation function
main() {
    print_msg "${GREEN}=== Page Reloader Installation ===${NC}"
    print_msg "${BLUE}Installing on OpenWrt Router...${NC}\n"
    
    check_root
    check_openwrt
    install_dependencies
    create_directories
    install_script
    install_web_gui
    create_init_script
    create_default_config
    enable_service
    show_summary
    
    print_msg "\n${GREEN}Installation completed successfully!${NC}"
}

# Run installation
main "$@"
