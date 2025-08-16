#!/bin/bash
# Deploy Simple GUI to Router
# This bypasses CGI completely and provides direct command interface

echo "🚀 Deploying Simple Page Reloader GUI"
echo "====================================="

# Router connection details
ROUTER_IP="192.168.1.1"
ROUTER_USER="root"

echo "📡 Connecting to router at $ROUTER_IP..."

# Create the deployment commands
cat > /tmp/router_deploy.sh << 'EOF'
#!/bin/sh
# Router deployment script

echo "🔧 Setting up Simple GUI..."

# Backup current GUI if exists
if [ -f "/www/page-reloader/index.html" ]; then
    cp /www/page-reloader/index.html /tmp/index.html.backup
    echo "✅ Backed up existing GUI"
fi

# Create directories
mkdir -p /www/page-reloader
mkdir -p /tmp/page-reloader

# Download simple GUI
cd /tmp
wget -O simple_gui.html https://raw.githubusercontent.com/roni791158/page-reloader/main/simple_gui.html

if [ $? -eq 0 ]; then
    # Install simple GUI
    cp simple_gui.html /www/page-reloader/index.html
    chmod 644 /www/page-reloader/index.html
    chown root:root /www/page-reloader/index.html
    
    echo "✅ Simple GUI installed successfully"
    
    # Remove problematic CGI script to prevent conflicts
    if [ -f "/www/cgi-bin/page-reloader-api" ]; then
        mv /www/cgi-bin/page-reloader-api /tmp/page-reloader-api.disabled
        echo "✅ Disabled problematic CGI script"
    fi
    
    # Restart web server
    /etc/init.d/uhttpd restart
    echo "✅ Web server restarted"
    
    # Test page-reloader script
    echo "🧪 Testing page-reloader script..."
    page-reloader status
    
    echo ""
    echo "🎉 DEPLOYMENT SUCCESSFUL!"
    echo "================================"
    echo "✅ Simple GUI is now available at:"
    echo "   http://192.168.1.1/page-reloader/"
    echo ""
    echo "✅ Features:"
    echo "   - Direct SSH command generator"
    echo "   - No CGI dependencies"  
    echo "   - 100% reliable operation"
    echo "   - Custom URL configuration"
    echo ""
    echo "✅ Usage:"
    echo "   1. Open http://192.168.1.1/page-reloader/ in browser"
    echo "   2. Enter your website URL"
    echo "   3. Copy generated commands"
    echo "   4. Run commands via SSH"
    echo ""
    
else
    echo "❌ Failed to download simple GUI"
    echo "Manual deployment required:"
    echo "1. Copy simple_gui.html to router"
    echo "2. Place it at /www/page-reloader/index.html"
    exit 1
fi
EOF

# Upload and execute deployment script
echo "📤 Uploading deployment script..."
scp /tmp/router_deploy.sh root@$ROUTER_IP:/tmp/

echo "🚀 Executing deployment on router..."
ssh root@$ROUTER_IP 'chmod +x /tmp/router_deploy.sh && /tmp/router_deploy.sh'

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo "=================================="
    echo ""
    echo "🌐 Access your new interface at:"
    echo "   http://$ROUTER_IP/page-reloader/"
    echo ""
    echo "✨ This new interface:"
    echo "   ✅ Works without CGI"
    echo "   ✅ Provides direct SSH commands"
    echo "   ✅ Generates custom configurations"
    echo "   ✅ 100% reliable operation"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Open the URL in your browser"
    echo "   2. Enter your website URL"
    echo "   3. Copy the generated commands"
    echo "   4. SSH to router and run commands"
    echo ""
else
    echo "❌ Deployment failed. Manual steps:"
    echo "1. SSH to router: ssh root@192.168.1.1"
    echo "2. Download: wget -O /www/page-reloader/index.html https://raw.githubusercontent.com/roni791158/page-reloader/main/simple_gui.html"
    echo "3. Restart: /etc/init.d/uhttpd restart"
fi

# Cleanup
rm -f /tmp/router_deploy.sh

echo ""
echo "🔧 Deployment script completed!"
