#!/bin/sh
# GUI Diagnosis and Fix Script for Page Reloader
# Run this on your OpenWrt router

echo "=== Page Reloader GUI Diagnosis ==="
echo "Date: $(date)"
echo

# Check if files exist
echo "1. Checking GUI files..."
if [ -f "/www/page-reloader/index.html" ]; then
    echo "✓ Web interface: /www/page-reloader/index.html"
else
    echo "✗ Missing: /www/page-reloader/index.html"
fi

if [ -f "/www/page-reloader/app.js" ]; then
    echo "✓ JavaScript app: /www/page-reloader/app.js"
else
    echo "✗ Missing: /www/page-reloader/app.js"
fi

if [ -f "/www/cgi-bin/page-reloader-api" ]; then
    echo "✓ CGI API: /www/cgi-bin/page-reloader-api"
    ls -la /www/cgi-bin/page-reloader-api
else
    echo "✗ Missing: /www/cgi-bin/page-reloader-api"
fi

echo

# Check uhttpd status
echo "2. Checking web server (uhttpd)..."
if pgrep uhttpd >/dev/null; then
    echo "✓ uhttpd is running"
    echo "   PIDs: $(pgrep uhttpd | tr '\n' ' ')"
else
    echo "✗ uhttpd is not running"
fi

echo

# Check uhttpd configuration
echo "3. Checking uhttpd CGI configuration..."
if command -v uci >/dev/null 2>&1; then
    CGI_PREFIX=$(uci get uhttpd.main.cgi_prefix 2>/dev/null)
    if [ "$CGI_PREFIX" = "/cgi-bin" ]; then
        echo "✓ CGI prefix configured: $CGI_PREFIX"
    else
        echo "✗ CGI prefix not set or wrong: '$CGI_PREFIX'"
        echo "  Fixing CGI configuration..."
        uci set uhttpd.main.cgi_prefix='/cgi-bin'
        uci commit uhttpd
        echo "✓ CGI prefix fixed"
    fi
else
    echo "⚠ UCI not available, cannot check CGI config"
fi

echo

# Check CGI permissions
echo "4. Checking CGI permissions..."
if [ -f "/www/cgi-bin/page-reloader-api" ]; then
    PERMS=$(ls -la /www/cgi-bin/page-reloader-api | cut -d' ' -f1)
    echo "   Current permissions: $PERMS"
    
    if [ -x "/www/cgi-bin/page-reloader-api" ]; then
        echo "✓ CGI script is executable"
    else
        echo "✗ CGI script not executable, fixing..."
        chmod +x /www/cgi-bin/page-reloader-api
        echo "✓ Permissions fixed"
    fi
fi

echo

# Test CGI script directly
echo "5. Testing CGI script directly..."
if [ -f "/www/cgi-bin/page-reloader-api" ]; then
    echo "   Running: /www/cgi-bin/page-reloader-api"
    echo "   Query: action=status"
    
    # Set environment for CGI test
    export REQUEST_METHOD="GET"
    export QUERY_STRING="action=status"
    export CONTENT_TYPE="application/x-www-form-urlencoded"
    
    echo "--- CGI Output ---"
    /www/cgi-bin/page-reloader-api 2>&1
    echo "--- End CGI Output ---"
fi

echo

# Check page-reloader script
echo "6. Checking page-reloader script..."
if [ -f "/usr/bin/page-reloader" ]; then
    echo "✓ Main script exists: /usr/bin/page-reloader"
    if [ -x "/usr/bin/page-reloader" ]; then
        echo "✓ Script is executable"
        echo "   Testing status command..."
        /usr/bin/page-reloader status 2>&1
    else
        echo "✗ Script not executable"
        chmod +x /usr/bin/page-reloader
        echo "✓ Made executable"
    fi
else
    echo "✗ Missing: /usr/bin/page-reloader"
fi

echo

# Check logs
echo "7. Checking logs..."
if [ -f "/var/log/page-reloader.log" ]; then
    echo "✓ Log file exists"
    echo "   Last 5 lines:"
    tail -5 /var/log/page-reloader.log 2>/dev/null || echo "   (Log file empty or unreadable)"
else
    echo "✗ No log file found"
fi

if [ -f "/tmp/api-debug.log" ]; then
    echo "✓ API debug log exists"
    echo "   Last 3 lines:"
    tail -3 /tmp/api-debug.log 2>/dev/null || echo "   (Debug log empty)"
else
    echo "⚠ No API debug log (this is normal if no API calls made)"
fi

echo

# Restart web server
echo "8. Restarting web server..."
/etc/init.d/uhttpd restart
if [ $? -eq 0 ]; then
    echo "✓ uhttpd restarted successfully"
    sleep 2
    
    if pgrep uhttpd >/dev/null; then
        echo "✓ uhttpd is running after restart"
        echo "   New PIDs: $(pgrep uhttpd | tr '\n' ' ')"
    else
        echo "✗ uhttpd failed to start after restart"
    fi
else
    echo "✗ Failed to restart uhttpd"
fi

echo

# Final status
echo "=== FINAL RECOMMENDATIONS ==="

# Check if GUI should work now
ISSUES=0

if [ ! -f "/www/page-reloader/index.html" ]; then
    echo "❌ Missing web interface files - reinstall GUI"
    ISSUES=$((ISSUES + 1))
fi

if [ ! -f "/www/cgi-bin/page-reloader-api" ] || [ ! -x "/www/cgi-bin/page-reloader-api" ]; then
    echo "❌ CGI API missing or not executable"
    ISSUES=$((ISSUES + 1))
fi

if ! pgrep uhttpd >/dev/null; then
    echo "❌ Web server not running"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "✅ GUI should work now!"
    echo "✅ Try: http://192.168.1.1/page-reloader/"
    echo
    echo "🔧 If buttons still don't work, check browser console:"
    echo "   - Press F12 in browser"
    echo "   - Go to Console tab"
    echo "   - Look for error messages"
    echo "   - Try clicking a button and see errors"
else
    echo "❌ Found $ISSUES issues - GUI may not work properly"
    echo "📝 Consider reinstalling with: ./install.sh"
fi

echo
echo "=== Diagnosis Complete ==="
