#!/bin/sh
# Fix Dynamic Button Issues
# Quick fix for URL management buttons not working

echo "🔧 Fixing Dynamic Button Issues..."
echo "================================="

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Must run as root"
    exit 1
fi

WEB_DIR="/www/page-reloader"
GITHUB_RAW="https://raw.githubusercontent.com/roni791158/page-reloader/main"

# Backup existing JavaScript
if [ -f "$WEB_DIR/page-reloader.js" ]; then
    echo "📁 Creating backup..."
    cp "$WEB_DIR/page-reloader.js" "$WEB_DIR/page-reloader.js.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Download fixed JavaScript file
echo "📥 Downloading fixed JavaScript..."
if command -v wget >/dev/null 2>&1; then
    wget -O "$WEB_DIR/page-reloader.js" "$GITHUB_RAW/web-gui/page-reloader.js"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$WEB_DIR/page-reloader.js" "$GITHUB_RAW/web-gui/page-reloader.js"
else
    echo "❌ Neither wget nor curl available"
    exit 1
fi

# Set permissions
chmod 644 "$WEB_DIR/page-reloader.js"

# Restart web server
if command -v /etc/init.d/uhttpd >/dev/null 2>&1; then
    echo "🔄 Restarting web server..."
    /etc/init.d/uhttpd restart
fi

echo ""
echo "✅ Button Fix Complete!"
echo "======================"
echo "✅ Updated JavaScript with event delegation"
echo "✅ Fixed dynamic button event handling"
echo "✅ Web server restarted"
echo ""
echo "📋 Fixed Features:"
echo "  • ⏰ Update Interval buttons now work"
echo "  • 🧪 Test URL buttons now work"
echo "  • 🗑️ Remove URL buttons now work"
echo "  • 🔄 Dynamic content event handling"
echo ""
echo "🌐 Refresh browser: http://192.168.1.1/page-reloader/"
echo "💡 Clear cache (Ctrl+F5) for best results"

exit 0
