#!/bin/sh
# Page Reloader Tool for OpenWrt Router
# Author: Router Page Reloader
# Version: 1.0

# Configuration
CONFIG_FILE="/etc/page-reloader/config"
LOG_FILE="/var/log/page-reloader.log"
PID_FILE="/var/run/page-reloader.pid"
SERVICE_NAME="page-reloader"

# Default configuration
DEFAULT_CHECK_INTERVAL=30
DEFAULT_TIMEOUT=10
DEFAULT_RETRY_COUNT=3
DEFAULT_URLS=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Check if service is running
is_service_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # Remove stale PID file
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
    else
        # Create default config
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << EOF
# Page Reloader Configuration
CHECK_INTERVAL=${DEFAULT_CHECK_INTERVAL}
TIMEOUT=${DEFAULT_TIMEOUT}
RETRY_COUNT=${DEFAULT_RETRY_COUNT}
URLS="${DEFAULT_URLS}"

# Example URLs (uncomment and modify as needed):
# URLS="http://192.168.1.1 http://google.com https://github.com"

# Notification settings
ENABLE_LOG=1
ENABLE_SYSLOG=0
EOF
        log "${YELLOW}Created default configuration at $CONFIG_FILE${NC}"
        log "${BLUE}Please edit the configuration file to add URLs to monitor${NC}"
    fi
    
    # Source the config
    . "$CONFIG_FILE"
    
    # Validate configuration
    if [ -z "$URLS" ]; then
        log "${YELLOW}Warning: No URLs configured in $CONFIG_FILE${NC}"
        return 1
    fi
    
    return 0
}

# Check URL accessibility
check_url() {
    local url="$1"
    local timeout="${TIMEOUT:-10}"
    
    # Use curl if available, otherwise use wget
    if command -v curl >/dev/null 2>&1; then
        curl -s -f --max-time "$timeout" --connect-timeout "$timeout" "$url" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget -q -T "$timeout" --tries=1 -O /dev/null "$url" >/dev/null 2>&1
    else
        log "${RED}Error: Neither curl nor wget is available${NC}"
        return 1
    fi
}

# Reload page/service
reload_page() {
    local url="$1"
    local retry_count="${RETRY_COUNT:-3}"
    local attempt=1
    
    log "${BLUE}Attempting to reload: $url${NC}"
    
    while [ $attempt -le $retry_count ]; do
        if check_url "$url"; then
            log "${GREEN}Successfully reloaded: $url (attempt $attempt)${NC}"
            return 0
        else
            log "${YELLOW}Failed to reload: $url (attempt $attempt/$retry_count)${NC}"
            attempt=$((attempt + 1))
            [ $attempt -le $retry_count ] && sleep 2
        fi
    done
    
    log "${RED}Failed to reload after $retry_count attempts: $url${NC}"
    return 1
}

# Get URL-specific interval
get_url_interval() {
    local url="$1"
    local url_safe=$(echo "$url" | sed 's|[^a-zA-Z0-9]|_|g')
    local var_name="INTERVAL_$url_safe"
    
    # Use eval to get the value of the dynamic variable
    eval "local interval=\$$var_name"
    
    # Return URL-specific interval or default
    if [ -n "$interval" ] && [ "$interval" -gt 0 ]; then
        echo "$interval"
    else
        echo "${CHECK_INTERVAL:-30}"
    fi
}

# Monitor and reload pages (simplified for stability)
monitor_pages() {
    local check_interval="${CHECK_INTERVAL:-30}"
    
    log "${GREEN}Starting page monitoring with interval: ${check_interval}s${NC}"
    
    while true; do
        for url in $URLS; do
            local url_interval=$(get_url_interval "$url")
            
            if ! check_url "$url"; then
                log "${YELLOW}Page not accessible: $url${NC}"
                reload_page "$url"
            else
                log "${GREEN}Page accessible: $url${NC}"
            fi
        done
        
        sleep "$check_interval"
    done
}

# Start the service
start_service() {
    check_root
    
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log "${YELLOW}Service is already running (PID: $(cat "$PID_FILE"))${NC}"
        return 1
    fi
    
    if ! load_config; then
        log "${RED}Failed to load configuration. Please check $CONFIG_FILE${NC}"
        return 1
    fi
    
    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Start monitoring in background
    monitor_pages &
    echo $! > "$PID_FILE"
    
    log "${GREEN}Page reloader service started (PID: $!)${NC}"
}

# Stop the service
stop_service() {
    check_root
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            log "${GREEN}Service stopped (PID: $pid)${NC}"
        else
            log "${YELLOW}Service was not running${NC}"
            rm -f "$PID_FILE"
        fi
    else
        log "${YELLOW}PID file not found. Service may not be running${NC}"
    fi
}

# Check service status
status_service() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log "${GREEN}Service is running (PID: $(cat "$PID_FILE"))${NC}"
        return 0
    else
        log "${RED}Service is not running${NC}"
        return 1
    fi
}

# Restart the service
restart_service() {
    log "${BLUE}Restarting page reloader service...${NC}"
    stop_service
    sleep 2
    start_service
}

# Add URL to configuration
add_url() {
    local url="$1"
    
    if [ -z "$url" ]; then
        log "${RED}Error: No URL provided${NC}"
        log "${BLUE}Usage: $0 add-url <URL>${NC}"
        return 1
    fi
    
    # Create config if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        load_config
    fi
    
    # Read current URLs
    . "$CONFIG_FILE"
    
    # Check if URL already exists
    for existing_url in $URLS; do
        if [ "$existing_url" = "$url" ]; then
            log "${YELLOW}URL already exists: $url${NC}"
            return 1
        fi
    done
    
    # Add URL
    if [ -z "$URLS" ]; then
        NEW_URLS="$url"
    else
        NEW_URLS="$URLS $url"
    fi
    
    # Update config file
    sed -i "s|^URLS=.*|URLS=\"$NEW_URLS\"|" "$CONFIG_FILE"
    
    log "${GREEN}Added URL: $url${NC}"
    log "${BLUE}Current URLs: $NEW_URLS${NC}"
    
    # Test the new URL
    if check_url "$url"; then
        log "${GREEN}✓ URL is accessible${NC}"
    else
        log "${YELLOW}⚠ URL is not currently accessible${NC}"
    fi
    
    # Auto-restart service if running to apply new URL
    if is_service_running; then
        log "${BLUE}Service is running. Restarting to apply new URL...${NC}"
        restart_service
        log "${GREEN}Service restarted successfully${NC}"
    fi
}

# Remove URL from configuration
remove_url() {
    local url="$1"
    
    if [ -z "$url" ]; then
        log "${RED}Error: No URL provided${NC}"
        log "${BLUE}Usage: $0 remove-url <URL>${NC}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log "${RED}Error: Configuration file not found${NC}"
        return 1
    fi
    
    # Read current URLs
    . "$CONFIG_FILE"
    
    # Check if URL exists
    local url_found=0
    for existing_url in $URLS; do
        if [ "$existing_url" = "$url" ]; then
            url_found=1
            break
        fi
    done
    
    if [ $url_found -eq 0 ]; then
        log "${YELLOW}URL not found: $url${NC}"
        return 1
    fi
    
    # Remove URL
    NEW_URLS=""
    for existing_url in $URLS; do
        if [ "$existing_url" != "$url" ]; then
            if [ -z "$NEW_URLS" ]; then
                NEW_URLS="$existing_url"
            else
                NEW_URLS="$NEW_URLS $existing_url"
            fi
        fi
    done
    
    # Update config file
    sed -i "s|^URLS=.*|URLS=\"$NEW_URLS\"|" "$CONFIG_FILE"
    
    log "${GREEN}Removed URL: $url${NC}"
    log "${BLUE}Current URLs: $NEW_URLS${NC}"
    
    # Also remove URL-specific interval if exists
    local url_safe=$(echo "$url" | sed 's|[^a-zA-Z0-9]|_|g')
    local var_name="INTERVAL_$url_safe"
    sed -i "/^$var_name=/d" "$CONFIG_FILE" 2>/dev/null
    
    # Auto-restart service if running to apply URL removal
    if is_service_running; then
        log "${BLUE}Service is running. Restarting to apply URL removal...${NC}"
        restart_service
        log "${GREEN}Service restarted successfully${NC}"
    fi
}

# List all configured URLs with intervals
list_urls() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "${RED}Error: Configuration file not found${NC}"
        return 1
    fi
    
    . "$CONFIG_FILE"
    
    if [ -z "$URLS" ]; then
        log "${YELLOW}No URLs configured${NC}"
        return 1
    fi
    
    log "${BLUE}Configured URLs with intervals:${NC}"
    local count=1
    for url in $URLS; do
        local url_interval=$(get_url_interval "$url")
        local status_icon=""
        local status_color=""
        
        if check_url "$url"; then
            status_icon="✓"
            status_color="${GREEN}"
        else
            status_icon="✗"
            status_color="${RED}"
        fi
        
        # Format interval display
        local interval_display=""
        if [ "$url_interval" -eq "${CHECK_INTERVAL:-30}" ]; then
            interval_display="(${url_interval}s - default)"
        else
            local minutes=$((url_interval / 60))
            local seconds=$((url_interval % 60))
            if [ $minutes -gt 0 ]; then
                if [ $seconds -gt 0 ]; then
                    interval_display="(${url_interval}s - ${minutes}m ${seconds}s - custom)"
                else
                    interval_display="(${url_interval}s - ${minutes}min - custom)"
                fi
            else
                interval_display="(${url_interval}s - custom)"
            fi
        fi
        
        log "${status_color}$count. $status_icon $url ${BLUE}$interval_display${NC}"
        count=$((count + 1))
    done
}

# Clear all URLs
clear_urls() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "${RED}Error: Configuration file not found${NC}"
        return 1
    fi
    
    printf "Are you sure you want to remove all URLs? [y/N]: "
    read -r response
    
    case "$response" in
        [Yy]|[Yy][Ee][Ss])
            sed -i 's|^URLS=.*|URLS=""|' "$CONFIG_FILE"
            log "${GREEN}All URLs removed${NC}"
            ;;
        *)
            log "${BLUE}Operation cancelled${NC}"
            ;;
    esac
}

# Bulk add URLs from file
bulk_add_urls() {
    local file="$1"
    
    if [ -z "$file" ]; then
        log "${RED}Error: No file provided${NC}"
        log "${BLUE}Usage: $0 bulk-add <file>${NC}"
        log "${BLUE}File format: One URL per line${NC}"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        log "${RED}Error: File not found: $file${NC}"
        return 1
    fi
    
    local added_count=0
    local skipped_count=0
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        case "$line" in
            ""|\#*) continue ;;
        esac
        
        # Try to add URL
        if add_url "$line" >/dev/null 2>&1; then
            added_count=$((added_count + 1))
            log "${GREEN}Added: $line${NC}"
        else
            skipped_count=$((skipped_count + 1))
            log "${YELLOW}Skipped: $line${NC}"
        fi
    done < "$file"
    
    log "${BLUE}Summary: $added_count added, $skipped_count skipped${NC}"
}

# Set check interval (global default)
set_interval() {
    local interval="$1"
    
    if [ -z "$interval" ]; then
        log "${RED}Error: No interval provided${NC}"
        log "${BLUE}Usage: $0 set-interval <seconds>${NC}"
        log "${BLUE}Examples:${NC}"
        log "${BLUE}  $0 set-interval 30     # 30 seconds (default for all URLs)${NC}"
        log "${BLUE}  $0 set-interval 300    # 5 minutes${NC}"
        log "${BLUE}  $0 set-interval 1800   # 30 minutes${NC}"
        return 1
    fi
    
    # Validate interval (must be a positive number)
    if ! echo "$interval" | grep -q '^[0-9]\+$' || [ "$interval" -lt 5 ]; then
        log "${RED}Error: Interval must be a number >= 5 seconds${NC}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        load_config
    fi
    
    # Update config file
    sed -i "s|^CHECK_INTERVAL=.*|CHECK_INTERVAL=$interval|" "$CONFIG_FILE"
    
    # Convert to human readable
    local minutes=$((interval / 60))
    local seconds=$((interval % 60))
    
    if [ $minutes -gt 0 ]; then
        if [ $seconds -gt 0 ]; then
            log "${GREEN}Default check interval set to: ${minutes}m ${seconds}s${NC}"
        else
            log "${GREEN}Default check interval set to: ${minutes} minutes${NC}"
        fi
    else
        log "${GREEN}Default check interval set to: ${seconds} seconds${NC}"
    fi
    
    # Auto-restart service if running to apply new interval
    if is_service_running; then
        log "${BLUE}Service is running. Restarting to apply new interval...${NC}"
        restart_service
        log "${GREEN}Service restarted successfully${NC}"
    else
        log "${BLUE}Start service to apply changes: page-reloader start${NC}"
    fi
}

# Set URL-specific interval
set_url_interval() {
    local url="$1"
    local interval="$2"
    
    if [ -z "$url" ] || [ -z "$interval" ]; then
        log "${RED}Error: URL and interval required${NC}"
        log "${BLUE}Usage: $0 set-url-interval <URL> <seconds>${NC}"
        log "${BLUE}Examples:${NC}"
        log "${BLUE}  $0 set-url-interval \"http://192.168.1.1\" 60      # Check every 1 minute${NC}"
        log "${BLUE}  $0 set-url-interval \"https://google.com\" 300     # Check every 5 minutes${NC}"
        return 1
    fi
    
    # Validate interval
    if ! echo "$interval" | grep -q '^[0-9]\+$' || [ "$interval" -lt 5 ]; then
        log "${RED}Error: Interval must be a number >= 5 seconds${NC}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        load_config
    fi
    
    # Check if URL exists in configuration
    . "$CONFIG_FILE"
    local url_found=0
    for existing_url in $URLS; do
        if [ "$existing_url" = "$url" ]; then
            url_found=1
            break
        fi
    done
    
    if [ $url_found -eq 0 ]; then
        log "${RED}Error: URL not found in configuration: $url${NC}"
        log "${BLUE}Add the URL first: $0 add-url \"$url\"${NC}"
        return 1
    fi
    
    # Create safe variable name
    local url_safe=$(echo "$url" | sed 's|[^a-zA-Z0-9]|_|g')
    local var_name="INTERVAL_$url_safe"
    
    # Check if this interval variable already exists in config
    if grep -q "^$var_name=" "$CONFIG_FILE"; then
        # Update existing
        sed -i "s|^$var_name=.*|$var_name=$interval|" "$CONFIG_FILE"
    else
        # Add new interval setting
        echo "$var_name=$interval" >> "$CONFIG_FILE"
    fi
    
    # Convert to human readable
    local minutes=$((interval / 60))
    local seconds=$((interval % 60))
    
    if [ $minutes -gt 0 ]; then
        if [ $seconds -gt 0 ]; then
            log "${GREEN}Set interval for $url: ${minutes}m ${seconds}s${NC}"
        else
            log "${GREEN}Set interval for $url: ${minutes} minutes${NC}"
        fi
    else
        log "${GREEN}Set interval for $url: ${seconds} seconds${NC}"
    fi
    
    # Auto-restart service if running to apply new URL interval
    if is_service_running; then
        log "${BLUE}Service is running. Restarting to apply new URL interval...${NC}"
        restart_service
        log "${GREEN}Service restarted successfully${NC}"
    else
        log "${BLUE}Start service to apply changes: page-reloader start${NC}"
    fi
}

# Remove URL-specific interval (revert to default)
remove_url_interval() {
    local url="$1"
    
    if [ -z "$url" ]; then
        log "${RED}Error: No URL provided${NC}"
        log "${BLUE}Usage: $0 remove-url-interval <URL>${NC}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log "${RED}Error: Configuration file not found${NC}"
        return 1
    fi
    
    # Create safe variable name
    local url_safe=$(echo "$url" | sed 's|[^a-zA-Z0-9]|_|g')
    local var_name="INTERVAL_$url_safe"
    
    # Remove the interval setting
    sed -i "/^$var_name=/d" "$CONFIG_FILE"
    
    log "${GREEN}Removed custom interval for: $url${NC}"
    log "${BLUE}URL will now use default interval${NC}"
    
    # Auto-restart service if running to apply interval removal
    if is_service_running; then
        log "${BLUE}Service is running. Restarting to apply interval removal...${NC}"
        restart_service
        log "${GREEN}Service restarted successfully${NC}"
    else
        log "${BLUE}Start service to apply changes: page-reloader start${NC}"
    fi
}

# Set timeout
set_timeout() {
    local timeout="$1"
    
    if [ -z "$timeout" ]; then
        log "${RED}Error: No timeout provided${NC}"
        log "${BLUE}Usage: $0 set-timeout <seconds>${NC}"
        log "${BLUE}Examples:${NC}"
        log "${BLUE}  $0 set-timeout 10     # 10 seconds${NC}"
        log "${BLUE}  $0 set-timeout 30     # 30 seconds${NC}"
        return 1
    fi
    
    # Validate timeout (must be a positive number)
    if ! echo "$timeout" | grep -q '^[0-9]\+$' || [ "$timeout" -lt 1 ]; then
        log "${RED}Error: Timeout must be a number >= 1 second${NC}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        load_config
    fi
    
    # Update config file
    sed -i "s|^TIMEOUT=.*|TIMEOUT=$timeout|" "$CONFIG_FILE"
    
    log "${GREEN}Connection timeout set to: ${timeout} seconds${NC}"
    
    # Auto-restart service if running to apply new timeout
    if is_service_running; then
        log "${BLUE}Service is running. Restarting to apply new timeout...${NC}"
        restart_service
        log "${GREEN}Service restarted successfully${NC}"
    else
        log "${BLUE}Start service to apply changes: page-reloader start${NC}"
    fi
}

# Show current timing settings
show_timing() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "${RED}Error: Configuration file not found${NC}"
        return 1
    fi
    
    . "$CONFIG_FILE"
    
    log "${BLUE}Current Timing Settings:${NC}"
    
    # Check interval
    local minutes=$((CHECK_INTERVAL / 60))
    local seconds=$((CHECK_INTERVAL % 60))
    
    if [ $minutes -gt 0 ]; then
        if [ $seconds -gt 0 ]; then
            log "${GREEN}Check Interval: ${CHECK_INTERVAL}s (${minutes}m ${seconds}s)${NC}"
        else
            log "${GREEN}Check Interval: ${CHECK_INTERVAL}s (${minutes} minutes)${NC}"
        fi
    else
        log "${GREEN}Check Interval: ${CHECK_INTERVAL} seconds${NC}"
    fi
    
    # Timeout
    log "${GREEN}Connection Timeout: ${TIMEOUT} seconds${NC}"
    
    # Retry count
    log "${GREEN}Retry Count: ${RETRY_COUNT} attempts${NC}"
    
    # Calculate approximate cycle time
    local max_cycle_time=$((CHECK_INTERVAL + (TIMEOUT * RETRY_COUNT)))
    log "${YELLOW}Max cycle time per URL: ~${max_cycle_time}s${NC}"
    
    # URL count
    local url_count=0
    for url in $URLS; do
        url_count=$((url_count + 1))
    done
    
    if [ $url_count -gt 0 ]; then
        local total_cycle_time=$((max_cycle_time * url_count))
        log "${YELLOW}Total cycle time (all URLs): ~${total_cycle_time}s${NC}"
    fi
}

# Quick timing presets
set_timing_preset() {
    local preset="$1"
    
    if [ -z "$preset" ]; then
        log "${RED}Error: No preset provided${NC}"
        log "${BLUE}Usage: $0 set-preset <preset_name>${NC}"
        log "${BLUE}Available presets:${NC}"
        log "${BLUE}  fast       - 15s interval, 5s timeout${NC}"
        log "${BLUE}  normal     - 30s interval, 10s timeout${NC}"
        log "${BLUE}  slow       - 60s interval, 15s timeout${NC}"
        log "${BLUE}  very-slow  - 300s interval, 30s timeout${NC}"
        log "${BLUE}  tasktreasure - 600s interval, 30s timeout (for external apps)${NC}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        load_config
    fi
    
    case "$preset" in
        fast)
            sed -i "s|^CHECK_INTERVAL=.*|CHECK_INTERVAL=15|" "$CONFIG_FILE"
            sed -i "s|^TIMEOUT=.*|TIMEOUT=5|" "$CONFIG_FILE"
            log "${GREEN}Applied 'fast' preset: 15s interval, 5s timeout${NC}"
            ;;
        normal)
            sed -i "s|^CHECK_INTERVAL=.*|CHECK_INTERVAL=30|" "$CONFIG_FILE"
            sed -i "s|^TIMEOUT=.*|TIMEOUT=10|" "$CONFIG_FILE"
            log "${GREEN}Applied 'normal' preset: 30s interval, 10s timeout${NC}"
            ;;
        slow)
            sed -i "s|^CHECK_INTERVAL=.*|CHECK_INTERVAL=60|" "$CONFIG_FILE"
            sed -i "s|^TIMEOUT=.*|TIMEOUT=15|" "$CONFIG_FILE"
            log "${GREEN}Applied 'slow' preset: 60s interval, 15s timeout${NC}"
            ;;
        very-slow)
            sed -i "s|^CHECK_INTERVAL=.*|CHECK_INTERVAL=300|" "$CONFIG_FILE"
            sed -i "s|^TIMEOUT=.*|TIMEOUT=30|" "$CONFIG_FILE"
            log "${GREEN}Applied 'very-slow' preset: 5min interval, 30s timeout${NC}"
            ;;
        tasktreasure)
            sed -i "s|^CHECK_INTERVAL=.*|CHECK_INTERVAL=600|" "$CONFIG_FILE"
            sed -i "s|^TIMEOUT=.*|TIMEOUT=30|" "$CONFIG_FILE"
            log "${GREEN}Applied 'tasktreasure' preset: 10min interval, 30s timeout${NC}"
            log "${BLUE}Perfect for external apps like TaskTreasure!${NC}"
            ;;
        *)
            log "${RED}Unknown preset: $preset${NC}"
            return 1
            ;;
    esac
    
    log "${BLUE}Restart service to apply changes: page-reloader restart${NC}"
}

# Show help
show_help() {
    cat << EOF
${BLUE}Page Reloader Tool for OpenWrt Router${NC}

Usage: $0 [COMMAND] [OPTIONS]

${YELLOW}Service Commands:${NC}
    start           Start the page reloader service
    stop            Stop the page reloader service
    restart         Restart the page reloader service
    status          Show service status

${YELLOW}URL Management:${NC}
    add-url <URL>      Add a URL to monitor
    remove-url <URL>   Remove a URL from monitoring
    list-urls          List all configured URLs with status
    clear-urls         Remove all URLs (with confirmation)
    bulk-add <file>    Add multiple URLs from file

${YELLOW}Timing Control:${NC}
    set-interval <sec>        Set default check interval (seconds)
    set-url-interval <URL> <sec>  Set custom interval for specific URL
    remove-url-interval <URL>     Remove custom interval (use default)
    set-timeout <sec>         Set connection timeout (seconds)
    set-preset <name>         Apply timing preset (fast/normal/slow/very-slow)
    show-timing               Show current timing settings

${YELLOW}Configuration:${NC}
    config          Edit configuration file
    test            Test all configured URLs once
    
${YELLOW}Monitoring:${NC}
    logs            Show recent logs
    help            Show this help message

${YELLOW}Files:${NC}
    Configuration: $CONFIG_FILE
    Log file: $LOG_FILE

${YELLOW}URL Examples:${NC}
    $0 add-url "http://192.168.1.1"           # Add router admin
    $0 add-url "https://www.google.com"       # Add external site
    $0 remove-url "http://192.168.1.1"        # Remove specific URL
    $0 list-urls                              # Show all URLs with status

${YELLOW}Timing Examples:${NC}
    $0 set-interval 60                        # Default: Check every 1 minute
    $0 set-url-interval "http://192.168.1.1" 30   # Router: every 30 seconds
    $0 set-url-interval "https://google.com" 300  # External: every 5 minutes
    $0 remove-url-interval "http://192.168.1.1"   # Remove custom interval
    $0 set-timeout 15                         # 15 second timeout
    $0 set-preset fast                        # Quick monitoring
    $0 set-preset tasktreasure                # TaskTreasure apps (10min)
    $0 show-timing                            # Show current settings

${YELLOW}Quick Start:${NC}
    $0 add-url "http://192.168.1.1"           # Add URL
    $0 set-preset normal                      # Set timing
    $0 start                                  # Start monitoring
    $0 logs                                   # Check logs

${YELLOW}Bulk Operations:${NC}
    echo "http://192.168.1.1" > urls.txt
    echo "https://github.com" >> urls.txt
    $0 bulk-add urls.txt                      # Add from file

EOF
}

# Edit configuration
edit_config() {
    if command -v vi >/dev/null 2>&1; then
        vi "$CONFIG_FILE"
    elif command -v nano >/dev/null 2>&1; then
        nano "$CONFIG_FILE"
    else
        log "${YELLOW}No text editor found. Please edit $CONFIG_FILE manually${NC}"
        cat "$CONFIG_FILE"
    fi
}

# Test URLs once
test_urls() {
    if ! load_config; then
        return 1
    fi
    
    log "${BLUE}Testing configured URLs...${NC}"
    
    for url in $URLS; do
        if check_url "$url"; then
            log "${GREEN}✓ $url - Accessible${NC}"
        else
            log "${RED}✗ $url - Not accessible${NC}"
        fi
    done
}

# Show recent logs
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -20 "$LOG_FILE"
    else
        log "${YELLOW}No log file found${NC}"
    fi
}

# Main function
main() {
    case "${1:-help}" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            status_service
            ;;
        config)
            edit_config
            ;;
        test)
            test_urls
            ;;
        logs)
            show_logs
            ;;
        add-url)
            add_url "$2"
            ;;
        remove-url)
            remove_url "$2"
            ;;
        list-urls)
            list_urls
            ;;
        clear-urls)
            clear_urls
            ;;
        bulk-add)
            bulk_add_urls "$2"
            ;;
        set-interval)
            set_interval "$2"
            ;;
        set-url-interval)
            set_url_interval "$2" "$3"
            ;;
        remove-url-interval)
            remove_url_interval "$2"
            ;;
        set-timeout)
            set_timeout "$2"
            ;;
        set-preset)
            set_timing_preset "$2"
            ;;
        show-timing)
            show_timing
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log "${RED}Unknown command: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
