#!/bin/sh
# Uninstallation script for Page Reloader Tool
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
LOG_FILE="$LOG_DIR/page-reloader.log"
PID_FILE="/var/run/page-reloader.pid"

# Print colored messages
print_msg() {
    echo -e "$1"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_msg "${RED}Error: Uninstallation must be run as root${NC}"
        exit 1
    fi
}

# Stop and disable service
stop_service() {
    print_msg "${BLUE}Stopping page reloader service...${NC}"
    
    # Stop the service if running
    if [ -f "$SERVICE_DIR/$SERVICE_NAME" ]; then
        /etc/init.d/$SERVICE_NAME stop 2>/dev/null
        /etc/init.d/$SERVICE_NAME disable 2>/dev/null
        print_msg "${GREEN}Service stopped and disabled${NC}"
    fi
    
    # Kill any remaining processes
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            print_msg "${YELLOW}Killed remaining process (PID: $pid)${NC}"
        fi
        rm -f "$PID_FILE"
    fi
}

# Remove files
remove_files() {
    print_msg "${BLUE}Removing installed files...${NC}"
    
    # Remove main script
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        rm -f "$INSTALL_DIR/$SCRIPT_NAME"
        print_msg "${GREEN}Removed: $INSTALL_DIR/$SCRIPT_NAME${NC}"
    fi
    
    # Remove init script
    if [ -f "$SERVICE_DIR/$SERVICE_NAME" ]; then
        rm -f "$SERVICE_DIR/$SERVICE_NAME"
        print_msg "${GREEN}Removed: $SERVICE_DIR/$SERVICE_NAME${NC}"
    fi
    
    # Remove PID file
    if [ -f "$PID_FILE" ]; then
        rm -f "$PID_FILE"
        print_msg "${GREEN}Removed: $PID_FILE${NC}"
    fi
    
    # Remove web GUI files
    if [ -d "$WEB_DIR/page-reloader" ]; then
        rm -rf "$WEB_DIR/page-reloader"
        print_msg "${GREEN}Removed: Web GUI directory${NC}"
    fi
    
    # Remove CGI API
    if [ -f "$CGI_DIR/page-reloader-api" ]; then
        rm -f "$CGI_DIR/page-reloader-api"
        print_msg "${GREEN}Removed: CGI API${NC}"
    fi
}

# Remove configuration (with confirmation)
remove_config() {
    if [ -d "$CONFIG_DIR" ]; then
        print_msg "${YELLOW}Configuration directory found: $CONFIG_DIR${NC}"
        printf "Do you want to remove configuration files? [y/N]: "
        read -r response
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                rm -rf "$CONFIG_DIR"
                print_msg "${GREEN}Removed: $CONFIG_DIR${NC}"
                ;;
            *)
                print_msg "${BLUE}Configuration files preserved${NC}"
                ;;
        esac
    fi
}

# Remove logs (with confirmation)
remove_logs() {
    if [ -f "$LOG_FILE" ]; then
        print_msg "${YELLOW}Log file found: $LOG_FILE${NC}"
        printf "Do you want to remove log files? [y/N]: "
        read -r response
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                rm -f "$LOG_FILE"
                print_msg "${GREEN}Removed: $LOG_FILE${NC}"
                ;;
            *)
                print_msg "${BLUE}Log files preserved${NC}"
                ;;
        esac
    fi
}

# Check what will be removed
show_removal_plan() {
    print_msg "${BLUE}The following will be removed:${NC}"
    
    [ -f "$INSTALL_DIR/$SCRIPT_NAME" ] && print_msg "  - Main script: $INSTALL_DIR/$SCRIPT_NAME"
    [ -f "$SERVICE_DIR/$SERVICE_NAME" ] && print_msg "  - Init script: $SERVICE_DIR/$SERVICE_NAME"
    [ -f "$PID_FILE" ] && print_msg "  - PID file: $PID_FILE"
    [ -d "$WEB_DIR/page-reloader" ] && print_msg "  - Web GUI: $WEB_DIR/page-reloader"
    [ -f "$CGI_DIR/page-reloader-api" ] && print_msg "  - CGI API: $CGI_DIR/page-reloader-api"
    
    print_msg "\n${YELLOW}Optional (will ask for confirmation):${NC}"
    [ -d "$CONFIG_DIR" ] && print_msg "  - Configuration: $CONFIG_DIR"
    [ -f "$LOG_FILE" ] && print_msg "  - Log file: $LOG_FILE"
    
    print_msg ""
}

# Confirm uninstallation
confirm_uninstall() {
    printf "Are you sure you want to uninstall Page Reloader? [y/N]: "
    read -r response
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            return 0
            ;;
        *)
            print_msg "${BLUE}Uninstallation cancelled${NC}"
            exit 0
            ;;
    esac
}

# Show summary
show_summary() {
    print_msg "\n${GREEN}=== Uninstallation Complete ===${NC}"
    print_msg "${GREEN}Page Reloader has been successfully removed${NC}"
    
    if [ -d "$CONFIG_DIR" ] || [ -f "$LOG_FILE" ]; then
        print_msg "\n${BLUE}Preserved files:${NC}"
        [ -d "$CONFIG_DIR" ] && print_msg "  - Configuration: $CONFIG_DIR"
        [ -f "$LOG_FILE" ] && print_msg "  - Log file: $LOG_FILE"
        print_msg "\n${YELLOW}You can manually remove these if needed${NC}"
    fi
}

# Force uninstall (remove everything without confirmation)
force_uninstall() {
    print_msg "${RED}Force uninstalling (removing all files)...${NC}"
    
    stop_service
    remove_files
    
    # Force remove config, logs, and GUI
    [ -d "$CONFIG_DIR" ] && rm -rf "$CONFIG_DIR" && print_msg "${GREEN}Removed: $CONFIG_DIR${NC}"
    [ -f "$LOG_FILE" ] && rm -f "$LOG_FILE" && print_msg "${GREEN}Removed: $LOG_FILE${NC}"
    [ -d "$WEB_DIR/page-reloader" ] && rm -rf "$WEB_DIR/page-reloader" && print_msg "${GREEN}Removed: Web GUI${NC}"
    [ -f "$CGI_DIR/page-reloader-api" ] && rm -f "$CGI_DIR/page-reloader-api" && print_msg "${GREEN}Removed: CGI API${NC}"
    
    print_msg "\n${GREEN}Force uninstallation complete${NC}"
}

# Show help
show_help() {
    cat << EOF
${BLUE}Page Reloader Uninstaller${NC}

Usage: $0 [OPTIONS]

Options:
    --force     Remove all files without confirmation
    --help      Show this help message

Default behavior:
    - Stops and removes the service
    - Removes main script and init files
    - Asks for confirmation before removing config and logs

Examples:
    $0              # Interactive uninstall
    $0 --force      # Force remove everything

EOF
}

# Main uninstallation function
main() {
    case "${1:-}" in
        --force)
            check_root
            force_uninstall
            ;;
        --help|-h)
            show_help
            ;;
        "")
            print_msg "${RED}=== Page Reloader Uninstaller ===${NC}\n"
            check_root
            show_removal_plan
            confirm_uninstall
            stop_service
            remove_files
            remove_config
            remove_logs
            show_summary
            ;;
        *)
            print_msg "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run uninstaller
main "$@"
