# Page Reloader Tool for OpenWrt Router

একটি শক্তিশালী পেইজ রিলোডার টুল যা OpenWrt রাউটারে ইনস্টল করা যায় এবং GitHub এর মাধ্যমে ব্যবস্থাপনা করা যায়।

## 🌟 Features

- ✅ **Simple Web Interface**: Direct SSH command generator (no CGI issues)
- ✅ **Background Service**: Console রাখার দরকার নেই, background এ চলে
- ✅ **Auto-Start on Boot**: Router restart হলে automatically শুরু হয়
- ✅ **Per-URL Intervals**: আলাদা আলাদা website এর জন্য আলাদা timing
- ✅ **Smart Retry Logic**: ব্যর্থ হলে নির্দিষ্ট সংখ্যকবার পুনরায় চেষ্টা করে
- ✅ **OpenWrt Integration**: OpenWrt রাউটারের সাথে সম্পূর্ণভাবে সামঞ্জস্যপূর্ণ
- ✅ **Service Management**: systemd-style service control
- ✅ **Configurable Settings**: সহজ কনফিগারেশন ফাইল
- ✅ **Logging Support**: বিস্তারিত লগিং এবং মনিটরিং
- ✅ **Easy Install/Uninstall**: One-click installation এবং removal
- ✅ **Minimal Resource Usage**: রাউটারে কম memory/CPU ব্যবহার
- ✅ **100% Reliable**: Direct script interaction, no web API dependencies

## 📋 Requirements

- OpenWrt router (any version)
- Root access
- `wget` বা `curl` (automatically installed)
- Minimum 1MB free space

## 🚀 Quick Installation

### Complete Installation (One Command)

```bash
# SSH to router and run one command
ssh root@router-ip
cd /tmp && wget https://github.com/roni791158/page-reloader/archive/refs/heads/main.zip && unzip main.zip && cd page-reloader-main && chmod +x install.sh && ./install.sh
```

### Step by Step Installation

```bash
# SSH to your router
ssh root@192.168.1.1

# Download and install
cd /tmp
wget https://github.com/roni791158/page-reloader/archive/refs/heads/main.zip
unzip main.zip
cd page-reloader-main
chmod +x install.sh
./install.sh
```

## 🌐 Web Interface

### Access Simple Interface

After installation, access web interface:
```
http://192.168.1.1/page-reloader/
```

### Interface Features

- **📋 Custom Command Generator**: Enter your URL, get ready-to-use SSH commands
- **📖 Complete Documentation**: All commands and examples in one place
- **🔧 Troubleshooting Guide**: Step-by-step problem solving
- **⚙️ Configuration Examples**: Common use cases and setups
- **📱 Mobile Friendly**: Works on phone/tablet
- **❌ No CGI Dependencies**: 100% reliable, no API issues

### How to Use Interface

1. **Open**: `http://192.168.1.1/page-reloader/` in browser
2. **Enter**: Your website URL in the input field
3. **Generate**: Click "Generate Commands" button
4. **Copy**: Generated SSH commands
5. **Execute**: SSH to router and run commands
6. **Done**: Service runs in background automatically

## 🎮 Usage

### Quick Setup Your Website

```bash
# SSH to router
ssh root@192.168.1.1

# Add your website URL
page-reloader add-url "https://your-website.com"

# Set monitoring interval (600 seconds = 10 minutes)
page-reloader set-interval 600

# Set connection timeout (30 seconds)
page-reloader set-timeout 30

# Start background monitoring
page-reloader start

# Enable auto-start on boot
/etc/init.d/page-reloader enable

# ✅ Done! Service runs in background
# You can logout, monitoring continues
exit
```

### Service Control

```bash
# Check status
page-reloader status

# Start service (runs in background)
page-reloader start

# Stop service
page-reloader stop

# Restart service
page-reloader restart

# View logs
page-reloader logs

# List configured URLs
page-reloader list-urls
```

### 🔗 URL Management

```bash
# Add URLs
page-reloader add-url "https://example.com"
page-reloader add-url "https://google.com"

# Remove URL
page-reloader remove-url "https://example.com"

# Clear all URLs
page-reloader clear-urls

# Set custom interval for specific URL
page-reloader set-url-interval "https://example.com" 300  # 5 minutes
```

### ⏰ Timing Control

```bash
# Set default check interval
page-reloader set-interval 600     # Every 10 minutes
page-reloader set-interval 300     # Every 5 minutes
page-reloader set-interval 60      # Every 1 minute

# Set connection timeout
page-reloader set-timeout 30       # 30 second timeout

# Use timing presets
page-reloader set-preset fast      # 15s interval, 5s timeout
page-reloader set-preset normal    # 30s interval, 10s timeout  
page-reloader set-preset slow      # 60s interval, 15s timeout
page-reloader set-preset very-slow # 5min interval, 30s timeout

# Show current settings
page-reloader show-timing
```

## 🔄 Background Monitoring

### ❌ Console রাখার দরকার নেই!

Page Reloader **automatic background service**:

- ✅ **Background এ চলে** (daemon process)
- ✅ **SSH close করলেও চলতে থাকে**
- ✅ **Router reboot হলে auto-start হয়**
- ✅ **কোন console/terminal open রাখতে হয় না**

### Service Management

```bash
# One-time setup
page-reloader add-url "https://your-site.com"
page-reloader set-interval 600
page-reloader start
/etc/init.d/page-reloader enable

# ✅ Done! Service runs forever in background
# Check status anytime:
page-reloader status
page-reloader logs
```

## 📊 Monitoring and Logs

### Log Locations

- **Main log**: `/var/log/page-reloader.log`
- **Configuration**: `/etc/page-reloader/config`
- **PID file**: `/var/run/page-reloader.pid`

### Real-time Monitoring

```bash
# Watch logs in real-time
tail -f /var/log/page-reloader.log

# View recent activity
page-reloader logs
```

## 🔧 Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Kill any stuck processes
pkill -f page-reloader
rm -f /var/run/page-reloader.pid

# Start fresh
page-reloader start
```

#### Check Configuration
```bash
# Verify URLs are configured
page-reloader list-urls

# Check timing settings
page-reloader show-timing

# Test URLs manually
page-reloader test
```

#### Clean Up Router
```bash
# Download and run cleanup script
cd /tmp
wget https://raw.githubusercontent.com/roni791158/page-reloader/main/cleanup_router.sh
chmod +x cleanup_router.sh
./cleanup_router.sh
```

## 🗑️ Uninstallation

### Safe Uninstall
```bash
# SSH to router
ssh root@192.168.1.1

# Download and run uninstaller
cd /tmp
wget https://raw.githubusercontent.com/roni791158/page-reloader/main/uninstall.sh
chmod +x uninstall.sh
./uninstall.sh
```

### Force Uninstall
```bash
./uninstall.sh --force
```

## 📁 File Structure

```
Essential Files:
├── page-reloader.sh              # Main script
├── install.sh                   # Installation script
├── uninstall.sh                 # Uninstallation script
├── simple_gui.html              # Simple web interface
├── cleanup_router.sh            # Router cleanup script
├── BACKGROUND_MONITORING.md     # Service documentation
├── README.md                    # This file
└── QUICKSTART.md               # Quick guide

Router Installation:
├── /usr/bin/page-reloader        # Main script
├── /etc/page-reloader/config     # Configuration file
├── /etc/init.d/page-reloader    # Service script
├── /www/page-reloader/          # Web interface
└── /var/log/page-reloader.log   # Log file
```

## 🔒 Security Considerations

- স্ক্রিপ্ট root privileges দিয়ে চলে
- নেটওয়ার্ক connections monitor করে
- Log files sensitive information থাকতে পারে

### Security Best Practices

```bash
# Secure configuration file
chmod 600 /etc/page-reloader/config

# Limit log file access
chmod 640 /var/log/page-reloader.log
```

## 📈 Performance

### Resource Usage
- **RAM**: < 1MB
- **CPU**: Minimal (only during checks)
- **Storage**: < 1MB total installation
- **Network**: < 1KB per URL check

### Optimization
```bash
# For many URLs, increase interval
page-reloader set-interval 300  # 5 minutes

# For critical services, decrease interval
page-reloader set-interval 60   # 1 minute
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Repository

- **GitHub**: [https://github.com/roni791158/page-reloader](https://github.com/roni791158/page-reloader)
- **Issues**: [Report bugs or request features](https://github.com/roni791158/page-reloader/issues)

## 📞 Support

- 🐛 **Bug Reports**: GitHub Issues
- 💡 **Feature Requests**: GitHub Issues
- 📖 **Documentation**: README.md এবং BACKGROUND_MONITORING.md

---

**Happy Monitoring! 🚀**

✅ **Set once, runs forever in background!**
✅ **Simple web interface for easy configuration!** 
✅ **100% reliable operation!**