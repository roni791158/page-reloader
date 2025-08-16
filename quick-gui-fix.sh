#!/bin/sh
# Quick GUI Fix for Page Reloader
# Run this on your OpenWrt router if GUI buttons don't work

echo "🔧 Quick GUI Fix Starting..."

# 1. Fix CGI permissions
if [ -f "/www/cgi-bin/page-reloader-api" ]; then
    chmod +x /www/cgi-bin/page-reloader-api
    echo "✅ Fixed CGI permissions"
else
    echo "❌ CGI script missing - reinstall needed"
    exit 1
fi

# 2. Configure uhttpd for CGI
if command -v uci >/dev/null 2>&1; then
    uci set uhttpd.main.cgi_prefix='/cgi-bin'
    uci commit uhttpd
    echo "✅ Configured CGI prefix"
else
    echo "⚠️ UCI not available"
fi

# 3. Restart web server
/etc/init.d/uhttpd restart
echo "✅ Restarted web server"

# 4. Test CGI
echo "🧪 Testing CGI..."
export REQUEST_METHOD="GET"
export QUERY_STRING="action=status"
export CONTENT_TYPE="application/x-www-form-urlencoded"

CGI_OUTPUT=$(/www/cgi-bin/page-reloader-api 2>&1)
if echo "$CGI_OUTPUT" | grep -q "Content-Type"; then
    echo "✅ CGI is working"
else
    echo "❌ CGI test failed:"
    echo "$CGI_OUTPUT"
fi

# 5. Test TaskTreasure setup
echo "🎯 Setting up TaskTreasure monitoring..."
page-reloader add-url "https://tasktreasure-otp1.onrender.com"
page-reloader set-preset tasktreasure
page-reloader start

echo
echo "✅ Quick fix complete!"
echo "🌐 Try GUI: http://192.168.1.1/page-reloader/"
echo "📊 Check status: page-reloader status"
