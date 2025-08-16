# Page Reloader Tool for OpenWrt Router

একটি শক্তিশালী পেইজ রিলোডার টুল যা OpenWrt রাউটারে ইনস্টল করা যায় এবং GitHub এর মাধ্যমে ব্যবস্থাপনা করা যায়।

## 🌟 Features

- ✅ **Web GUI Interface**: Modern browser-based management panel
- ✅ **Automatic Page Monitoring**: কনফিগার করা URL গুলো নিয়মিত চেক করে
- ✅ **Per-URL Intervals**: আলাদা আলাদা website এর জন্য আলাদা timing
- ✅ **Smart Retry Logic**: ব্যর্থ হলে নির্দিষ্ট সংখ্যকবার পুনরায় চেষ্টা করে
- ✅ **OpenWrt Integration**: OpenWrt রাউটারের সাথে সম্পূর্ণভাবে সামঞ্জস্যপূর্ণ
- ✅ **Service Management**: systemd-style service control
- ✅ **Real-time Dashboard**: Live monitoring এবং status updates
- ✅ **Mobile Responsive**: Phone/tablet থেকেও ব্যবহার করা যায়
- ✅ **Configurable Settings**: সহজ কনফিগারেশন ফাইল
- ✅ **Logging Support**: বিস্তারিত লগিং এবং মনিটরিং
- ✅ **Easy Install/Uninstall**: One-click installation এবং removal
- ✅ **Minimal Resource Usage**: রাউটারে কম memory/CPU ব্যবহার
- ✅ **GitHub Ready**: GitHub repository এ প্রস্তুত

## 📋 Requirements

- OpenWrt router (any version)
- Root access
- `wget` বা `curl` (automatically installed)
- Minimum 1MB free space

## 🚀 Quick Installation

### Method 1: Direct Download and Install

```bash
# Download the installation script
wget https://raw.githubusercontent.com/your-username/page-reloader/main/install.sh

# Make it executable
chmod +x install.sh

# Run installation
./install.sh
```

### Method 2: Clone Repository

```bash
# Clone the repository
git clone https://github.com/your-username/page-reloader.git
cd page-reloader

# Run installation
./install.sh
```

### Method 3: OpenWrt Package Manager (if available)

```bash
# Add repository (if published)
opkg update
opkg install page-reloader
```

## ⚙️ Configuration

### 1. Edit Configuration File

```bash
# Edit configuration
page-reloader config

# Or manually edit
vi /etc/page-reloader/config
```

### 2. Example Configuration

```bash
# Basic settings
CHECK_INTERVAL=30          # Check every 30 seconds
TIMEOUT=10                 # 10 second timeout
RETRY_COUNT=3              # Retry 3 times on failure

# URLs to monitor (space-separated)
URLS="http://192.168.1.1 http://google.com https://github.com"

# Logging
ENABLE_LOG=1               # Enable logging
ENABLE_SYSLOG=0           # Disable syslog
```

### 3. Common Use Cases

#### Monitor Router Admin Interface
```bash
URLS="http://192.168.1.1/cgi-bin/luci"
CHECK_INTERVAL=60
```

#### Monitor External Connectivity
```bash
URLS="https://www.google.com https://1.1.1.1"
CHECK_INTERVAL=120
```

#### Monitor Multiple Services
```bash
URLS="http://192.168.1.1 http://192.168.1.2:8080 https://github.com"
CHECK_INTERVAL=30
```

## 🌐 Web GUI Interface

### Access Web Interface

রাউটার login করার পর browser এ:
```
http://router-ip/page-reloader/
```

### GUI Features

- **📊 Dashboard**: Real-time service status, URL monitoring
- **🔗 URL Management**: Add/remove URLs with custom intervals  
- **⏰ Timing Control**: Set intervals, timeouts, presets
- **📋 Logs**: View system logs in real-time
- **⚙️ Settings**: Service control, auto-start, export/import

### Mobile Support

GUI সম্পূর্ণভাবে mobile responsive - phone/tablet থেকে ব্যবহার করা যায়।

## 🎮 Usage

### Web Interface (Recommended)

Browser এ যান: `http://router-ip/page-reloader/`

### Command Line Interface

### Service Control

```bash
# Start the service
/etc/init.d/page-reloader start

# Stop the service
/etc/init.d/page-reloader stop

# Restart the service
/etc/init.d/page-reloader restart

# Check status
page-reloader status

# Enable auto-start on boot
/etc/init.d/page-reloader enable

# Disable auto-start
/etc/init.d/page-reloader disable
```

### 🔗 URL Management

```bash
# Add a single URL
page-reloader add-url "http://192.168.1.1"
page-reloader add-url "https://www.google.com"

# Remove a URL
page-reloader remove-url "http://192.168.1.1"

# List all URLs with status
page-reloader list-urls

# Clear all URLs (with confirmation)
page-reloader clear-urls

# Bulk add URLs from file
echo "http://192.168.1.1" > my-urls.txt
echo "https://github.com" >> my-urls.txt
echo "https://www.google.com" >> my-urls.txt
page-reloader bulk-add my-urls.txt
```

### ⏰ Timing Control

```bash
# Set default check interval (applies to all URLs)
page-reloader set-interval 30      # Every 30 seconds
page-reloader set-interval 300     # Every 5 minutes
page-reloader set-interval 1800    # Every 30 minutes

# Set custom interval for specific URLs (NEW!)
page-reloader set-url-interval "http://192.168.1.1" 30        # Router every 30s
page-reloader set-url-interval "https://www.google.com" 300   # Google every 5min
page-reloader set-url-interval "https://github.com" 600       # GitHub every 10min

# Remove custom interval (revert to default)
page-reloader remove-url-interval "http://192.168.1.1"

# Set connection timeout
page-reloader set-timeout 10       # 10 second timeout
page-reloader set-timeout 30       # 30 second timeout

# Use timing presets for quick setup
page-reloader set-preset fast      # 15s interval, 5s timeout
page-reloader set-preset normal    # 30s interval, 10s timeout  
page-reloader set-preset slow      # 60s interval, 15s timeout
page-reloader set-preset very-slow # 5min interval, 30s timeout

# Show current timing settings
page-reloader show-timing
```

### Testing and Monitoring

```bash
# Test all configured URLs once
page-reloader test

# View recent logs
page-reloader logs

# Edit configuration manually
page-reloader config

# Show help
page-reloader help
```

### Advanced Usage

```bash
# Manual start/stop (direct script control)
page-reloader start
page-reloader stop
page-reloader restart

# Monitor specific URL temporarily
URLS="http://example.com" CHECK_INTERVAL=10 page-reloader start
```

## 📊 Monitoring and Logs

### Log Locations

- **Main log**: `/var/log/page-reloader.log`
- **Configuration**: `/etc/page-reloader/config`
- **PID file**: `/var/run/page-reloader.pid`

### Log Examples

```
2024-01-15 10:30:15 - Starting page monitoring with interval: 30s
2024-01-15 10:30:45 - ✓ http://192.168.1.1 - Accessible
2024-01-15 10:31:15 - ✗ http://example.com - Not accessible
2024-01-15 10:31:17 - Attempting to reload: http://example.com
2024-01-15 10:31:19 - Successfully reloaded: http://example.com (attempt 1)
```

### Real-time Monitoring

```bash
# Watch logs in real-time
tail -f /var/log/page-reloader.log

# Monitor with timestamps
page-reloader logs | tail -20
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Service Won't Start
```bash
# Check configuration
page-reloader test

# Check if URLs are configured
cat /etc/page-reloader/config | grep URLS

# Check for permission issues
ls -la /usr/bin/page-reloader
```

#### 2. URLs Not Responding
```bash
# Test connectivity manually
wget -O /dev/null http://your-url.com

# Check DNS resolution
nslookup google.com

# Test with curl
curl -I http://your-url.com
```

#### 3. High CPU Usage
```bash
# Increase check interval
# Edit config: CHECK_INTERVAL=120  # Check every 2 minutes

# Reduce retry count
# Edit config: RETRY_COUNT=1
```

#### 4. Log File Growing Too Large
```bash
# Rotate logs manually
mv /var/log/page-reloader.log /var/log/page-reloader.log.old
page-reloader restart
```

### Debug Mode

```bash
# Run in foreground with debug output
page-reloader stop
/usr/bin/page-reloader start
```

## 🗑️ Uninstallation

### Interactive Uninstall (Recommended)

```bash
./uninstall.sh
```

### Force Uninstall (Remove Everything)

```bash
./uninstall.sh --force
```

### Manual Uninstall

```bash
# Stop service
/etc/init.d/page-reloader stop
/etc/init.d/page-reloader disable

# Remove files
rm -f /usr/bin/page-reloader
rm -f /etc/init.d/page-reloader
rm -rf /etc/page-reloader
rm -f /var/log/page-reloader.log
rm -f /var/run/page-reloader.pid
```

## 📁 File Structure

```
/usr/bin/page-reloader              # Main script
/etc/page-reloader/config           # Configuration file
/etc/init.d/page-reloader          # Service script
/var/log/page-reloader.log         # Log file
/var/run/page-reloader.pid         # PID file
```

## 🔄 GitHub Integration

### Repository Structure

```
page-reloader/
├── README.md                      # This file
├── page-reloader.sh              # Main script
├── install.sh                    # Installation script
├── uninstall.sh                  # Uninstallation script
├── config.example                # Example configuration
├── page-reloader.init            # OpenWrt init script
├── Makefile                      # Build configuration
└── LICENSE                       # License file
```

### Release and Distribution

1. **Create Release**: Tag version and create GitHub release
2. **Package**: Use Makefile to create distribution package
3. **Deploy**: Use install script for easy deployment

```bash
# Create package
make package

# Install from package
tar -xzf page-reloader-1.0.0.tar.gz
cd page-reloader-1.0.0
./install.sh
```

## 🔒 Security Considerations

- স্ক্রিপ্ট root privileges দিয়ে চলে
- নেটওয়ার্ক connections monitor করে
- Log files sensitive information থাকতে পারে
- Configuration file এ URLs expose হয়

### Security Best Practices

```bash
# Secure configuration file
chmod 600 /etc/page-reloader/config

# Limit log file access
chmod 640 /var/log/page-reloader.log

# Regular log rotation
logrotate /var/log/page-reloader.log
```

## 📈 Performance Optimization

### Memory Usage
- Typical RAM usage: < 1MB
- Log file: Grows over time (rotate regularly)
- CPU usage: Minimal (only during checks)

### Network Impact
- Bandwidth per check: < 1KB per URL
- Configurable intervals to reduce load
- Smart retry logic prevents excessive requests

### Optimization Tips

```bash
# For many URLs, increase interval
CHECK_INTERVAL=300  # 5 minutes

# For critical services, decrease interval
CHECK_INTERVAL=15   # 15 seconds

# For slow connections, increase timeout
TIMEOUT=30          # 30 seconds
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

Created with ❤️ for OpenWrt community

## 🔗 Links

- [OpenWrt Documentation](https://openwrt.org/docs)
- [GitHub Repository](https://github.com/your-username/page-reloader)
- [Issue Tracker](https://github.com/your-username/page-reloader/issues)

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/your-username/page-reloader/issues)
- 💡 **Feature Requests**: [GitHub Issues](https://github.com/your-username/page-reloader/issues)
- 📖 **Documentation**: [Wiki](https://github.com/your-username/page-reloader/wiki)

---

**Happy Monitoring! 🚀**
