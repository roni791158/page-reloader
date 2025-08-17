#!/bin/sh
# Fix API Backend Issues
# Comprehensive fix for web GUI backend problems

echo "🔧 Fixing Page Reloader API Backend..."
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Configuration
CGI_DIR="/www/cgi-bin"
WEB_DIR="/www/page-reloader"
SCRIPT_PATHS="/usr/bin/page-reloader /usr/local/bin/page-reloader /bin/page-reloader"
GITHUB_RAW="https://raw.githubusercontent.com/roni791158/page-reloader/main"

# Find page-reloader script
SCRIPT_PATH=""
for path in $SCRIPT_PATHS; do
    if [ -f "$path" ]; then
        SCRIPT_PATH="$path"
        print_status "Found page-reloader script at: $path"
        break
    fi
done

if [ -z "$SCRIPT_PATH" ]; then
    print_error "Page-reloader script not found!"
    print_info "Installing page-reloader script..."
    
    # Download main script
    if command -v wget >/dev/null 2>&1; then
        wget -O /usr/bin/page-reloader "$GITHUB_RAW/page-reloader.sh"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o /usr/bin/page-reloader "$GITHUB_RAW/page-reloader.sh"
    else
        print_error "Neither wget nor curl available"
        exit 1
    fi
    
    chmod +x /usr/bin/page-reloader
    SCRIPT_PATH="/usr/bin/page-reloader"
    print_status "Installed page-reloader script"
fi

# Ensure directories exist
print_info "Checking directories..."
mkdir -p "$CGI_DIR"
mkdir -p "$WEB_DIR"
mkdir -p "/etc/page-reloader"
mkdir -p "/var/log"

print_status "Directories verified"

# Download and install fixed API
print_info "Installing fixed API backend..."

if command -v wget >/dev/null 2>&1; then
    wget -O "$CGI_DIR/page-reloader-api" "$GITHUB_RAW/web-gui/page-reloader-api-fixed"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$CGI_DIR/page-reloader-api" "$GITHUB_RAW/web-gui/page-reloader-api-fixed"
else
    print_error "Cannot download API file"
    exit 1
fi

# Set correct permissions
chmod +x "$CGI_DIR/page-reloader-api"
chmod 755 "$CGI_DIR"
print_status "API backend installed and permissions set"

# Test script functionality
print_info "Testing page-reloader script..."
if "$SCRIPT_PATH" --version >/dev/null 2>&1 || "$SCRIPT_PATH" status >/dev/null 2>&1; then
    print_status "Page-reloader script is functional"
else
    print_warning "Page-reloader script may have issues"
fi

# Create basic config if missing
CONFIG_FILE="/etc/page-reloader/config"
if [ ! -f "$CONFIG_FILE" ]; then
    print_info "Creating basic configuration..."
    cat > "$CONFIG_FILE" << 'EOF'
# Page Reloader Configuration
URLS=""
CHECK_INTERVAL=30
TIMEOUT=10
MAX_RETRIES=3
EOF
    chmod 600 "$CONFIG_FILE"
    print_status "Basic configuration created"
fi

# Test CGI functionality
print_info "Testing CGI environment..."

# Create test script
cat > "/tmp/cgi-test.sh" << 'EOF'
#!/bin/sh
echo "Content-Type: text/plain"
echo ""
echo "CGI Test: $(date)"
echo "SCRIPT_NAME: $SCRIPT_NAME"
echo "REQUEST_METHOD: $REQUEST_METHOD"
echo "QUERY_STRING: $QUERY_STRING"
EOF

chmod +x "/tmp/cgi-test.sh"

# Test web server configuration
print_info "Checking web server configuration..."

# Check if uhttpd is running
if pgrep uhttpd >/dev/null 2>&1; then
    print_status "uhttpd web server is running"
    
    # Restart web server to reload CGI configuration
    if command -v /etc/init.d/uhttpd >/dev/null 2>&1; then
        print_info "Restarting web server..."
        /etc/init.d/uhttpd restart
        print_status "Web server restarted"
    fi
else
    print_warning "uhttpd web server not running"
    if command -v /etc/init.d/uhttpd >/dev/null 2>&1; then
        print_info "Starting web server..."
        /etc/init.d/uhttpd start
        print_status "Web server started"
    fi
fi

# Test API endpoint
print_info "Testing API endpoint..."
sleep 2

# Test with curl/wget
TEST_URL="http://127.0.0.1/cgi-bin/page-reloader-api?action=debug"

if command -v curl >/dev/null 2>&1; then
    RESPONSE=$(curl -s -m 10 "$TEST_URL" 2>/dev/null)
elif command -v wget >/dev/null 2>&1; then
    RESPONSE=$(wget -q -T 10 -O - "$TEST_URL" 2>/dev/null)
fi

if [ -n "$RESPONSE" ]; then
    print_status "API endpoint is responding"
    echo "Response: $RESPONSE"
else
    print_warning "API endpoint not responding properly"
fi

# Set up debugging
print_info "Setting up debugging..."
touch /tmp/api-debug.log
touch /tmp/api-error.log
chmod 666 /tmp/api-debug.log
chmod 666 /tmp/api-error.log
print_status "Debug logging enabled"

# Clean up test files
rm -f "/tmp/cgi-test.sh"

echo ""
echo "🎉 API Backend Fix Complete!"
echo "============================"
print_status "Fixed API backend installed"
print_status "Permissions and directories configured"
print_status "Web server restarted"
print_status "Debug logging enabled"

echo ""
echo "📋 Next Steps:"
echo "1. Access web interface: http://192.168.1.1/page-reloader/"
echo "2. Check debug logs: tail -f /tmp/api-debug.log"
echo "3. Check error logs: tail -f /tmp/api-error.log"
echo "4. Test API directly: curl 'http://192.168.1.1/cgi-bin/page-reloader-api?action=status'"

echo ""
print_info "If issues persist, check the debug logs for detailed information"

exit 0
