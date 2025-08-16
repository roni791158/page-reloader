#!/bin/sh
# Router Cleanup Script
# Remove unnecessary files and optimize installation

echo "🧹 Page Reloader Cleanup"
echo "======================="

# Remove temporary debug files
echo "📁 Cleaning temporary files..."
rm -f /tmp/page-reloader-api* 2>/dev/null
rm -f /tmp/index.html* 2>/dev/null  
rm -f /tmp/api-debug.log 2>/dev/null
rm -f /tmp/logs.json 2>/dev/null
rm -f /tmp/config.backup 2>/dev/null
rm -f /tmp/*debug* 2>/dev/null
rm -f /tmp/*fix* 2>/dev/null

# Remove old app.js if exists (not needed with simple GUI)
if [ -f "/www/page-reloader/app.js" ]; then
    rm -f /www/page-reloader/app.js
    echo "✅ Removed old app.js"
fi

# Disable/remove problematic CGI script
if [ -f "/www/cgi-bin/page-reloader-api" ]; then
    mv /www/cgi-bin/page-reloader-api /tmp/page-reloader-api.disabled
    echo "✅ Disabled problematic CGI script"
fi

# Clean log file if too large (keep last 100 lines)
if [ -f "/var/log/page-reloader.log" ]; then
    LOG_SIZE=$(wc -l < /var/log/page-reloader.log 2>/dev/null || echo 0)
    if [ "$LOG_SIZE" -gt 100 ]; then
        tail -100 /var/log/page-reloader.log > /tmp/page-reloader.log.clean
        mv /tmp/page-reloader.log.clean /var/log/page-reloader.log
        echo "✅ Cleaned log file (kept last 100 lines)"
    fi
fi

# Check essential files
echo ""
echo "🔍 Verifying essential files..."

ESSENTIAL_FILES="
/usr/bin/page-reloader
/etc/page-reloader/config
/etc/init.d/page-reloader
/www/page-reloader/index.html
"

ALL_GOOD=1
for file in $ESSENTIAL_FILES; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
        ALL_GOOD=0
    fi
done

echo ""
echo "📊 Current Status:"

# Service status
if page-reloader status >/dev/null 2>&1; then
    echo "✅ Service: Running"
else
    echo "⚪ Service: Stopped"
fi

# Auto-start status
if /etc/init.d/page-reloader enabled 2>/dev/null; then
    echo "✅ Auto-start: Enabled"
else
    echo "⚪ Auto-start: Disabled"
fi

# URL count
URL_COUNT=$(page-reloader list-urls 2>/dev/null | grep -c "http" || echo 0)
echo "📝 URLs configured: $URL_COUNT"

# Disk usage
GUI_SIZE=$(du -sh /www/page-reloader 2>/dev/null | cut -f1 || echo "unknown")
echo "💾 GUI size: $GUI_SIZE"

echo ""
if [ $ALL_GOOD -eq 1 ]; then
    echo "🎉 Cleanup completed successfully!"
    echo "✅ All essential files present"
    echo "✅ Temporary files removed"
    echo "✅ System optimized"
else
    echo "⚠️ Some essential files missing"
    echo "Consider reinstalling with install.sh"
fi

echo ""
echo "🌐 Access GUI: http://$(uci get network.lan.ipaddr 2>/dev/null || echo '192.168.1.1')/page-reloader/"
echo "📋 Use GUI to generate SSH commands for configuration"
