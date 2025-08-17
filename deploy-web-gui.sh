#!/bin/bash
# Deploy Web GUI to Router
# Simple deployment script for updating web interface

echo "🚀 Deploying Web GUI to Router..."
echo "================================="

# Router configuration
ROUTER_IP="192.168.1.1"
ROUTER_USER="root"

# Check if we can reach the router
if ! ping -c 1 "$ROUTER_IP" >/dev/null 2>&1; then
    echo "❌ Cannot reach router at $ROUTER_IP"
    echo "Please check your network connection"
    exit 1
fi

echo "✅ Router reachable at $ROUTER_IP"

# Create deployment commands
cat > /tmp/deploy-commands.sh << 'EOF'
#!/bin/sh
echo "📥 Downloading web GUI updater..."
cd /tmp
wget -O update-web-gui.sh https://raw.githubusercontent.com/roni791158/page-reloader/main/update-web-gui.sh
chmod +x update-web-gui.sh

echo "🔄 Running web GUI update..."
./update-web-gui.sh

echo "✅ Web GUI deployment complete!"
EOF

echo "📤 Uploading and executing update script..."

# Copy and execute the deployment script
if command -v scp >/dev/null 2>&1; then
    # Using SCP method
    scp /tmp/deploy-commands.sh "$ROUTER_USER@$ROUTER_IP:/tmp/"
    ssh "$ROUTER_USER@$ROUTER_IP" "chmod +x /tmp/deploy-commands.sh && /tmp/deploy-commands.sh"
else
    # Direct SSH method
    ssh "$ROUTER_USER@$ROUTER_IP" << 'ENDSSH'
echo "📥 Downloading web GUI updater..."
cd /tmp
wget -O update-web-gui.sh https://raw.githubusercontent.com/roni791158/page-reloader/main/update-web-gui.sh
chmod +x update-web-gui.sh

echo "🔄 Running web GUI update..."
./update-web-gui.sh

echo "✅ Web GUI deployment complete!"
ENDSSH
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Deployment Successful!"
    echo "========================"
    echo "✅ Web GUI updated on router"
    echo "🌐 Access: http://$ROUTER_IP/page-reloader/"
    echo ""
    echo "🔍 New Features Available:"
    echo "  • Multiple URLs monitoring"
    echo "  • Per-URL interval settings"
    echo "  • Real-time status display"
    echo "  • Enhanced URL management"
    echo "  • Auto-restart functionality"
else
    echo ""
    echo "❌ Deployment Failed!"
    echo "===================="
    echo "Please run manually:"
    echo "ssh root@$ROUTER_IP"
    echo "cd /tmp"
    echo "wget https://raw.githubusercontent.com/roni791158/page-reloader/main/update-web-gui.sh"
    echo "chmod +x update-web-gui.sh"
    echo "./update-web-gui.sh"
fi

# Clean up
rm -f /tmp/deploy-commands.sh
