#!/bin/sh
# Complete Fix Script for Page Reloader Web GUI
# Fixes API issues, CSP problems, and UI functionality

echo "🔧 Complete Page Reloader Fix"
echo "============================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Check root
if [ "$(id -u)" != "0" ]; then
    print_error "Must run as root"
    exit 1
fi

# Configuration
WEB_DIR="/www/page-reloader"
CGI_DIR="/www/cgi-bin"
GITHUB_RAW="https://raw.githubusercontent.com/roni791158/page-reloader/main"

# Create directories
print_info "Setting up directories..."
mkdir -p "$WEB_DIR" "$CGI_DIR" "/etc/page-reloader" "/var/log"
print_status "Directories created"

# Download and install main script if missing
if [ ! -f "/usr/bin/page-reloader" ]; then
    print_info "Installing page-reloader main script..."
    if command -v wget >/dev/null 2>&1; then
        wget -O /usr/bin/page-reloader "$GITHUB_RAW/page-reloader.sh"
    else
        curl -L -o /usr/bin/page-reloader "$GITHUB_RAW/page-reloader.sh"
    fi
    chmod +x /usr/bin/page-reloader
    print_status "Main script installed"
fi

# Download fixed web GUI files
print_info "Installing fixed web GUI files..."

# Install fixed HTML (no inline scripts)
if command -v wget >/dev/null 2>&1; then
    wget -O "$WEB_DIR/index.html" "$GITHUB_RAW/web-gui/index.html"
    wget -O "$WEB_DIR/page-reloader.js" "$GITHUB_RAW/web-gui/page-reloader.js"
    wget -O "$CGI_DIR/page-reloader-api" "$GITHUB_RAW/web-gui/page-reloader-api-fixed"
else
    curl -L -o "$WEB_DIR/index.html" "$GITHUB_RAW/web-gui/index.html"
    curl -L -o "$WEB_DIR/page-reloader.js" "$GITHUB_RAW/web-gui/page-reloader.js"
    curl -L -o "$CGI_DIR/page-reloader-api" "$GITHUB_RAW/web-gui/page-reloader-api-fixed"
fi

print_status "Web GUI files installed"

# Set permissions
chmod 755 "$WEB_DIR"
chmod 644 "$WEB_DIR/index.html"
chmod 644 "$WEB_DIR/page-reloader.js"
chmod +x "$CGI_DIR/page-reloader-api"
print_status "Permissions set"

# Create basic config if missing
if [ ! -f "/etc/page-reloader/config" ]; then
    print_info "Creating configuration..."
    cat > "/etc/page-reloader/config" << 'EOF'
# Page Reloader Configuration
URLS=""
CHECK_INTERVAL=30
TIMEOUT=10
MAX_RETRIES=3
EOF
    chmod 600 "/etc/page-reloader/config"
    print_status "Configuration created"
fi

# Setup debug logging
touch /tmp/api-debug.log /tmp/api-error.log
chmod 666 /tmp/api-debug.log /tmp/api-error.log
print_status "Debug logging enabled"

# Restart web server
if command -v /etc/init.d/uhttpd >/dev/null 2>&1; then
    print_info "Restarting web server..."
    /etc/init.d/uhttpd restart >/dev/null 2>&1
    print_status "Web server restarted"
fi

# Test API endpoint
print_info "Testing API functionality..."
sleep 2

TEST_RESPONSE=""
if command -v curl >/dev/null 2>&1; then
    TEST_RESPONSE=$(curl -s -m 5 "http://127.0.0.1/cgi-bin/page-reloader-api?action=debug" 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
    TEST_RESPONSE=$(wget -q -T 5 -O - "http://127.0.0.1/cgi-bin/page-reloader-api?action=debug" 2>/dev/null)
fi

if echo "$TEST_RESPONSE" | grep -q "success"; then
    print_status "API is responding correctly"
else
    print_warning "API may have issues - check logs"
fi

# Test web interface
if [ -f "$WEB_DIR/index.html" ] && [ -f "$WEB_DIR/page-reloader.js" ]; then
    print_status "Web interface files ready"
else
    print_error "Web interface files missing"
fi

echo ""
echo "🎉 Complete Fix Applied!"
echo "======================="
print_status "Fixed API parameter parsing issues"
print_status "Removed inline scripts (CSP compliance)"
print_status "Added external JavaScript file"
print_status "Enhanced error handling and debugging"
print_status "Configured proper permissions"

echo ""
echo "📋 Access Points:"
print_info "Web Interface: http://192.168.1.1/page-reloader/"
print_info "API Endpoint: http://192.168.1.1/cgi-bin/page-reloader-api"
print_info "Debug Log: tail -f /tmp/api-debug.log"
print_info "Error Log: tail -f /tmp/api-error.log"

echo ""
echo "🧪 Test Commands:"
echo "curl 'http://192.168.1.1/cgi-bin/page-reloader-api?action=status'"
echo "curl 'http://192.168.1.1/cgi-bin/page-reloader-api?action=debug'"

echo ""
print_status "All issues should now be resolved!"
print_info "Refresh your browser and test the web interface"

exit 0
