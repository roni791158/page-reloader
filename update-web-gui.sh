#!/bin/sh
# Web GUI Update Script for Page Reloader
# Updates only the web interface files

echo "🌐 Page Reloader Web GUI Updater"
echo "=================================="

# Configuration
GITHUB_REPO="https://raw.githubusercontent.com/roni791158/page-reloader/main"
WEB_DIR="/www/page-reloader"
CGI_DIR="/www/cgi-bin"
TEMP_DIR="/tmp/page-reloader-gui-update"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    print_error "This script must be run as root"
    exit 1
fi

# Check if wget or curl is available
if command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget -O"
    print_info "Using wget for downloads"
elif command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl -L -o"
    print_info "Using curl for downloads"
else
    print_error "Neither wget nor curl found. Installing wget..."
    opkg update && opkg install wget
    DOWNLOADER="wget -O"
fi

# Create temporary directory
print_info "Creating temporary directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Download latest web GUI files
print_info "Downloading latest web GUI files..."

# Download index.html
if $DOWNLOADER "$TEMP_DIR/index.html" "$GITHUB_REPO/web-gui/index.html"; then
    print_status "Downloaded index.html"
else
    print_error "Failed to download index.html"
    exit 1
fi

# Download API script
if $DOWNLOADER "$TEMP_DIR/page-reloader-api" "$GITHUB_REPO/web-gui/page-reloader-api"; then
    print_status "Downloaded page-reloader-api"
else
    print_error "Failed to download page-reloader-api"
    exit 1
fi

# Create web directory if it doesn't exist
if [ ! -d "$WEB_DIR" ]; then
    print_info "Creating web directory: $WEB_DIR"
    mkdir -p "$WEB_DIR"
fi

# Create CGI directory if it doesn't exist
if [ ! -d "$CGI_DIR" ]; then
    print_info "Creating CGI directory: $CGI_DIR"
    mkdir -p "$CGI_DIR"
fi

# Backup existing files
if [ -f "$WEB_DIR/index.html" ]; then
    print_info "Backing up existing index.html"
    cp "$WEB_DIR/index.html" "$WEB_DIR/index.html.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -f "$CGI_DIR/page-reloader-api" ]; then
    print_info "Backing up existing page-reloader-api"
    cp "$CGI_DIR/page-reloader-api" "$CGI_DIR/page-reloader-api.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Install new files
print_info "Installing new web GUI files..."

# Install index.html
if cp "$TEMP_DIR/index.html" "$WEB_DIR/index.html"; then
    chmod 644 "$WEB_DIR/index.html"
    print_status "Installed index.html"
else
    print_error "Failed to install index.html"
    exit 1
fi

# Install API script
if cp "$TEMP_DIR/page-reloader-api" "$CGI_DIR/page-reloader-api"; then
    chmod +x "$CGI_DIR/page-reloader-api"
    print_status "Installed page-reloader-api"
else
    print_error "Failed to install page-reloader-api"
    exit 1
fi

# Set correct permissions
chmod -R 755 "$WEB_DIR"
chmod +x "$CGI_DIR/page-reloader-api"

# Clean up
print_info "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Test web interface
print_info "Testing web interface..."
if [ -f "$WEB_DIR/index.html" ] && [ -f "$CGI_DIR/page-reloader-api" ]; then
    print_status "Web interface files installed successfully"
else
    print_error "Web interface installation incomplete"
    exit 1
fi

# Restart web server if available
if command -v /etc/init.d/uhttpd >/dev/null 2>&1; then
    print_info "Restarting web server..."
    /etc/init.d/uhttpd restart
    print_status "Web server restarted"
fi

echo ""
echo "🎉 Web GUI Update Complete!"
echo "=========================="
print_status "Web interface updated successfully"
print_info "Access URL: http://192.168.1.1/page-reloader/"
print_info "API URL: http://192.168.1.1/cgi-bin/page-reloader-api"

# Show version info
echo ""
echo "📋 Updated Features:"
echo "  ✅ Multiple URLs monitoring"
echo "  ✅ Per-URL interval configuration" 
echo "  ✅ Real-time status display"
echo "  ✅ Enhanced URL management"
echo "  ✅ Auto-restart functionality"
echo "  ✅ Mobile responsive design"

echo ""
print_info "If buttons don't work, use Manual Commands tab for SSH access"
print_info "All changes have been applied successfully!"

exit 0
