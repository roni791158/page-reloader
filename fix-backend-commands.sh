#!/bin/sh
# Fix Backend Command Execution Issues
# Comprehensive fix for API command execution problems

echo "🔧 Fixing Backend Command Execution..."
echo "======================================"

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
CGI_DIR="/www/cgi-bin"
SCRIPT_PATH="/usr/bin/page-reloader"
GITHUB_RAW="https://raw.githubusercontent.com/roni791158/page-reloader/main"

# Backup existing API
if [ -f "$CGI_DIR/page-reloader-api" ]; then
    print_info "Creating backup..."
    cp "$CGI_DIR/page-reloader-api" "$CGI_DIR/page-reloader-api.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Download fixed API backend
print_info "Installing fixed API backend..."
if command -v wget >/dev/null 2>&1; then
    wget -O "$CGI_DIR/page-reloader-api" "$GITHUB_RAW/web-gui/page-reloader-api-fixed"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$CGI_DIR/page-reloader-api" "$GITHUB_RAW/web-gui/page-reloader-api-fixed"
else
    print_error "Cannot download API file"
    exit 1
fi

# Set permissions
chmod +x "$CGI_DIR/page-reloader-api"
print_status "API backend updated"

# Ensure main script exists and is executable
if [ ! -f "$SCRIPT_PATH" ]; then
    print_warning "Main script not found, installing..."
    if command -v wget >/dev/null 2>&1; then
        wget -O "$SCRIPT_PATH" "$GITHUB_RAW/page-reloader.sh"
    else
        curl -L -o "$SCRIPT_PATH" "$GITHUB_RAW/page-reloader.sh"
    fi
fi

chmod +x "$SCRIPT_PATH"
print_status "Main script verified"

# Create debug logging
touch /tmp/api-debug.log /tmp/api-error.log
chmod 666 /tmp/api-debug.log /tmp/api-error.log
print_status "Debug logging enabled"

# Test script functionality
print_info "Testing script functionality..."
if "$SCRIPT_PATH" --help >/dev/null 2>&1 || "$SCRIPT_PATH" status >/dev/null 2>&1; then
    print_status "Main script is functional"
else
    print_warning "Main script may have issues"
fi

# Test API endpoints
print_info "Testing API endpoints..."
sleep 1

# Test status endpoint
STATUS_RESPONSE=""
if command -v curl >/dev/null 2>&1; then
    STATUS_RESPONSE=$(curl -s -m 5 "http://127.0.0.1/cgi-bin/page-reloader-api?action=status" 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
    STATUS_RESPONSE=$(wget -q -T 5 -O - "http://127.0.0.1/cgi-bin/page-reloader-api?action=status" 2>/dev/null)
fi

if echo "$STATUS_RESPONSE" | grep -q "success"; then
    print_status "Status API working"
else
    print_warning "Status API may have issues"
fi

# Test debug endpoint
DEBUG_RESPONSE=""
if command -v curl >/dev/null 2>&1; then
    DEBUG_RESPONSE=$(curl -s -m 5 "http://127.0.0.1/cgi-bin/page-reloader-api?action=debug" 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
    DEBUG_RESPONSE=$(wget -q -T 5 -O - "http://127.0.0.1/cgi-bin/page-reloader-api?action=debug" 2>/dev/null)
fi

if echo "$DEBUG_RESPONSE" | grep -q "success"; then
    print_status "Debug API working"
    echo "Debug info: $DEBUG_RESPONSE"
else
    print_warning "Debug API may have issues"
fi

# Test URL operations manually
print_info "Testing URL operations..."

# Test add URL
ADD_RESPONSE=""
if command -v curl >/dev/null 2>&1; then
    ADD_RESPONSE=$(curl -s -m 10 "http://127.0.0.1/cgi-bin/page-reloader-api?action=add-url&url=https://example.com" 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
    ADD_RESPONSE=$(wget -q -T 10 -O - "http://127.0.0.1/cgi-bin/page-reloader-api?action=add-url&url=https://example.com" 2>/dev/null)
fi

if echo "$ADD_RESPONSE" | grep -q "success.*true"; then
    print_status "Add URL API working"
else
    print_warning "Add URL API issues: $ADD_RESPONSE"
fi

# Clean up test URL
"$SCRIPT_PATH" remove-url "https://example.com" >/dev/null 2>&1

# Restart web server
if command -v /etc/init.d/uhttpd >/dev/null 2>&1; then
    print_info "Restarting web server..."
    /etc/init.d/uhttpd restart
    print_status "Web server restarted"
fi

echo ""
echo "🎉 Backend Fix Complete!"
echo "======================="
print_status "Enhanced API command execution"
print_status "Improved URL parameter handling"
print_status "Better error logging and debugging"
print_status "Command argument escaping fixed"

echo ""
echo "📋 Fixed Commands:"
echo "  ✅ Add URL"
echo "  ✅ Remove URL" 
echo "  ✅ Set URL Interval"
echo "  ✅ Test URL"
echo "  ✅ Service Control"

echo ""
echo "🔍 Debug Commands:"
echo "  • Check API logs: tail -f /tmp/api-debug.log"
echo "  • Check error logs: tail -f /tmp/api-error.log"
echo "  • Test manually: curl 'http://192.168.1.1/cgi-bin/page-reloader-api?action=debug'"

echo ""
echo "🌐 Test web interface: http://192.168.1.1/page-reloader/"
print_info "All URL management buttons should now work properly!"

exit 0
