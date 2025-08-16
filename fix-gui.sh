#!/bin/sh
# Fix GUI Button Issues
# Troubleshoot and repair web interface

echo "🔧 Page Reloader GUI Fix"
echo "======================="
echo ""

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "❌ Please run as root"
    exit 1
fi

echo "🔍 Diagnosing GUI issues..."

# 1. Check web server
echo "1. Checking web server..."
if pgrep uhttpd >/dev/null; then
    echo "✅ uhttpd is running"
else
    echo "❌ uhttpd is not running - starting..."
    /etc/init.d/uhttpd start
fi

# 2. Check CGI configuration
echo "2. Checking CGI configuration..."
cgi_prefix=$(uci get uhttpd.main.cgi_prefix 2>/dev/null)
if [ "$cgi_prefix" = "/cgi-bin" ]; then
    echo "✅ CGI prefix is correct: $cgi_prefix"
else
    echo "🔧 Setting CGI prefix..."
    uci set uhttpd.main.cgi_prefix='/cgi-bin'
    uci commit uhttpd
    echo "✅ CGI prefix set to /cgi-bin"
fi

# 3. Check web files
echo "3. Checking web files..."
if [ -f "/www/page-reloader/index.html" ]; then
    echo "✅ Web interface found"
else
    echo "❌ Web interface missing"
fi

if [ -f "/www/cgi-bin/page-reloader-api" ]; then
    echo "✅ CGI API found"
    
    # Check permissions
    if [ -x "/www/cgi-bin/page-reloader-api" ]; then
        echo "✅ CGI API is executable"
    else
        echo "🔧 Making CGI API executable..."
        chmod +x /www/cgi-bin/page-reloader-api
        echo "✅ CGI API permissions fixed"
    fi
else
    echo "❌ CGI API missing - reinstalling..."
    
    # Try to copy from installation source
    if [ -f "/tmp/page-reloader-main/web-gui/page-reloader-api" ]; then
        cp /tmp/page-reloader-main/web-gui/page-reloader-api /www/cgi-bin/
        chmod +x /www/cgi-bin/page-reloader-api
        echo "✅ CGI API restored from installation"
    else
        echo "❌ CGI API source not found - please reinstall"
    fi
fi

# 4. Check main script
echo "4. Checking main script..."
if [ -f "/usr/bin/page-reloader" ]; then
    echo "✅ Main script found"
else
    echo "❌ Main script missing - please reinstall"
fi

# 5. Test CGI manually
echo "5. Testing CGI API..."
if command -v curl >/dev/null; then
    response=$(curl -s "http://localhost/cgi-bin/page-reloader-api?action=status" 2>/dev/null)
    if echo "$response" | grep -q "success"; then
        echo "✅ CGI API responds correctly"
    else
        echo "⚠️ CGI API response: $response"
    fi
else
    echo "ℹ️ curl not available for testing"
fi

# 6. Restart web server
echo "6. Restarting web server..."
/etc/init.d/uhttpd restart
echo "✅ Web server restarted"

# 7. Clear browser cache
echo ""
echo "🌐 Browser Instructions:"
echo "1. Open http://router-ip/page-reloader/"
echo "2. Press F12 to open Developer Tools"
echo "3. Right-click refresh button → Empty Cache and Hard Reload"
echo "4. Check Console tab for any error messages"

echo ""
echo "📋 Manual Test Commands:"
echo "# Test CGI directly:"
echo "curl 'http://localhost/cgi-bin/page-reloader-api?action=status'"
echo ""
echo "# Check CGI permissions:"
echo "ls -la /www/cgi-bin/page-reloader-api"
echo ""
echo "# View CGI logs:"
echo "tail -f /tmp/api-debug.log"

echo ""
echo "🎯 If buttons still don't work:"
echo "1. Use manual commands via SSH"
echo "2. Check router firewall settings"
echo "3. Try different browser"
echo "4. Check JavaScript is enabled"

echo ""
echo "✅ GUI fix completed!"
echo "Try refreshing your browser now."
