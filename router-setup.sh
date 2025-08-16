#!/bin/sh
# Page Reloader Setup Script for Router
# URL: https://tasktreasure-otp1.onrender.com
# Interval: 600 seconds (10 minutes)

echo "=== Page Reloader Configuration Setup ==="
echo "Target URL: https://tasktreasure-otp1.onrender.com"
echo "Check Interval: 600 seconds (10 minutes)"
echo ""

# Check if Page Reloader is installed
if [ ! -f "/usr/bin/page-reloader" ]; then
    echo "❌ Page Reloader not found. Please install first."
    exit 1
fi

echo "✅ Page Reloader found"

# Stop service if running
echo "🔄 Stopping service..."
/etc/init.d/page-reloader stop 2>/dev/null

# Add the target URL
echo "➕ Adding target URL..."
page-reloader add-url "https://tasktreasure-otp1.onrender.com"

# Set custom interval for the URL (600 seconds = 10 minutes)
echo "⏰ Setting 10-minute interval..."
page-reloader set-url-interval "https://tasktreasure-otp1.onrender.com" 600

# Set timeout to 30 seconds for external URL
echo "⏱️ Setting timeout to 30 seconds..."
page-reloader set-timeout 30

# Set retry count to 3
echo "🔄 Setting retry count to 3..."
if [ -f "/etc/page-reloader/config" ]; then
    sed -i 's/RETRY_COUNT=.*/RETRY_COUNT=3/' /etc/page-reloader/config
fi

# Test the URL first
echo "🧪 Testing URL connectivity..."
if page-reloader test-url "https://tasktreasure-otp1.onrender.com"; then
    echo "✅ URL is accessible"
else
    echo "⚠️ URL test failed, but continuing setup..."
fi

# Start the service
echo "🚀 Starting service..."
/etc/init.d/page-reloader start

# Enable auto-start
echo "⚡ Enabling auto-start..."
/etc/init.d/page-reloader enable

# Show current configuration
echo ""
echo "=== Current Configuration ==="
page-reloader list-urls
page-reloader show-timing

echo ""
echo "=== Setup Complete ==="
echo "✅ URL: https://tasktreasure-otp1.onrender.com"
echo "✅ Interval: 600 seconds (10 minutes)"
echo "✅ Timeout: 30 seconds"
echo "✅ Retry count: 3"
echo "✅ Service: Started and enabled"
echo ""
echo "🌐 Web GUI: http://192.168.1.1/page-reloader/"
echo "📋 Logs: page-reloader logs"
echo "📊 Status: page-reloader status"
echo ""
echo "Your TaskTreasure app will be monitored every 10 minutes! 🎉"
