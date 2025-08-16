#!/bin/sh
# Quick Setup Script for TaskTreasure Monitoring
# URL: https://tasktreasure-otp1.onrender.com
# Optimized for external app monitoring with 10-minute intervals

echo "🚀 TaskTreasure Quick Setup"
echo "================================="
echo ""

# Check if Page Reloader is installed
if [ ! -f "/usr/bin/page-reloader" ]; then
    echo "❌ Page Reloader not installed!"
    echo "📦 Please install first: ./install.sh"
    exit 1
fi

echo "✅ Page Reloader found"

# Stop service
echo "🔄 Stopping service..."
/etc/init.d/page-reloader stop >/dev/null 2>&1

# Apply TaskTreasure preset
echo "⚙️ Applying TaskTreasure preset..."
page-reloader set-preset tasktreasure

# Add TaskTreasure URL
echo "🌐 Adding TaskTreasure URL..."
page-reloader add-url "https://tasktreasure-otp1.onrender.com"

# Set specific interval for TaskTreasure (10 minutes)
echo "⏰ Setting 10-minute monitoring interval..."
page-reloader set-url-interval "https://tasktreasure-otp1.onrender.com" 600

# Test the URL
echo "🧪 Testing TaskTreasure connectivity..."
if page-reloader test >/dev/null 2>&1; then
    echo "✅ TaskTreasure is accessible"
else
    echo "⚠️ TaskTreasure test warning (continuing setup...)"
fi

# Start service
echo "🚀 Starting monitoring service..."
/etc/init.d/page-reloader start

# Enable auto-start
echo "⚡ Enabling auto-start on boot..."
/etc/init.d/page-reloader enable

echo ""
echo "🎉 TaskTreasure Setup Complete!"
echo "================================="
echo "✅ URL: https://tasktreasure-otp1.onrender.com"
echo "✅ Interval: 600 seconds (10 minutes)"
echo "✅ Timeout: 30 seconds"
echo "✅ Auto-start: Enabled"
echo ""
echo "📊 Monitor with:"
echo "   • Web GUI: http://router-ip/page-reloader/"
echo "   • Command: page-reloader status"
echo "   • Logs: page-reloader logs"
echo ""
echo "Your TaskTreasure app will be monitored every 10 minutes! 🎯"

# Show current status
echo ""
echo "📋 Current Status:"
page-reloader list-urls 2>/dev/null || echo "Status: Setting up..."
page-reloader status 2>/dev/null || echo "Service: Starting..."
