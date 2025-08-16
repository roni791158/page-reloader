#!/bin/sh
# Router Update Script for Page Reloader
# Updates to latest version with GUI fixes

echo "🔄 Page Reloader Update Script"
echo "=============================="
echo ""

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Please run as root: sudo $0"
    exit 1
fi

echo "📥 Downloading latest version..."

# Stop service first
echo "⏸️ Stopping service..."
/etc/init.d/page-reloader stop 2>/dev/null

# Backup current config
echo "💾 Backing up configuration..."
if [ -f "/etc/page-reloader/config" ]; then
    cp /etc/page-reloader/config /tmp/page-reloader-config.backup
    echo "✅ Config backed up to /tmp/page-reloader-config.backup"
fi

# Remove old installation files
echo "🗑️ Cleaning old installation..."
rm -rf /tmp/page-reloader-main /tmp/main.zip /tmp/main

# Download latest version
echo "📦 Downloading from GitHub..."
cd /tmp
wget https://github.com/roni791158/page-reloader/archive/refs/heads/main.zip

# Handle wget output filename
if [ -f "main.zip" ]; then
    echo "✅ Downloaded as main.zip"
elif [ -f "main" ]; then
    echo "✅ Downloaded as main, renaming..."
    mv main main.zip
else
    echo "❌ Download failed"
    exit 1
fi

# Extract
echo "📂 Extracting files..."
unzip -q main.zip
cd page-reloader-main

# Update files
echo "🔄 Updating files..."

# Update main script
if [ -f "page-reloader.sh" ]; then
    cp page-reloader.sh /usr/bin/page-reloader
    chmod +x /usr/bin/page-reloader
    echo "✅ Main script updated"
fi

# Update web GUI
if [ -d "web-gui" ]; then
    echo "🌐 Updating web interface..."
    
    # Create directories
    mkdir -p /www/page-reloader
    mkdir -p /www/cgi-bin
    
    # Copy GUI files
    cp web-gui/index.html /www/page-reloader/ 2>/dev/null && echo "  ✅ index.html updated"
    cp web-gui/app.js /www/page-reloader/ 2>/dev/null && echo "  ✅ app.js updated"
    
    # Update CGI API
    cp web-gui/page-reloader-api /www/cgi-bin/
    chmod +x /www/cgi-bin/page-reloader-api
    echo "  ✅ CGI API updated"
fi

# Update init script
if [ -f "page-reloader.init" ]; then
    cp page-reloader.init /etc/init.d/page-reloader
    chmod +x /etc/init.d/page-reloader
    echo "✅ Init script updated"
fi

# Restore config
echo "🔧 Restoring configuration..."
if [ -f "/tmp/page-reloader-config.backup" ]; then
    cp /tmp/page-reloader-config.backup /etc/page-reloader/config
    echo "✅ Configuration restored"
fi

# Fix GUI issues
echo "🛠️ Applying GUI fixes..."

# Configure CGI support
if command -v uci >/dev/null 2>&1; then
    uci set uhttpd.main.cgi_prefix='/cgi-bin' 2>/dev/null
    uci commit uhttpd 2>/dev/null
    echo "✅ CGI configuration applied"
fi

# Fix permissions
chmod +x /www/cgi-bin/page-reloader-api 2>/dev/null
chmod 644 /www/page-reloader/* 2>/dev/null

# Restart web server
echo "🌐 Restarting web server..."
/etc/init.d/uhttpd restart

# Start service
echo "▶️ Starting service..."
/etc/init.d/page-reloader start

# Test API
echo "🧪 Testing API..."
if command -v curl >/dev/null; then
    response=$(curl -s "http://localhost/cgi-bin/page-reloader-api?action=status" 2>/dev/null)
    if echo "$response" | grep -q "success\|running\|stopped"; then
        echo "✅ API is working"
    else
        echo "⚠️ API response: $response"
    fi
fi

# Cleanup
echo "🧹 Cleaning up..."
cd /
rm -rf /tmp/page-reloader-main /tmp/main.zip

echo ""
echo "🎉 Update Complete!"
echo "=================="
echo "✅ Page Reloader updated to latest version"
echo "✅ GUI fixes applied"
echo "✅ Service restarted"
echo ""
echo "🌐 Web Interface: http://router-ip/page-reloader/"
echo "📋 Check status: page-reloader status"
echo "📊 View logs: page-reloader logs"
echo ""
echo "🔧 If GUI still has issues, clear browser cache (Ctrl+F5)"
echo ""

# Show current status
echo "📊 Current Status:"
page-reloader status 2>/dev/null || echo "Service status: Check manually"
echo ""
echo "🎯 TaskTreasure URL setup:"
echo "page-reloader add-url 'https://tasktreasure-otp1.onrender.com'"
echo "page-reloader set-preset tasktreasure"
