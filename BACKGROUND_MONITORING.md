# Background Monitoring - Page Reloader

## 🔄 Service Operation Mode

Page Reloader **automatic background service** হিসেবে কাজ করে। আপনার কোন console open রাখতে হবে না।

## ✅ Background Service Features

### **1. Daemon Mode**
- Service background এ চলে (daemon process)
- SSH session close করলেও service চলতে থাকে
- Router reboot হলে automatically start হয়

### **2. Auto-Start on Boot**
```bash
# Enable auto-start (one time setup)
/etc/init.d/page-reloader enable

# Check if enabled
/etc/init.d/page-reloader enabled && echo "Auto-start enabled" || echo "Auto-start disabled"
```

### **3. Service Management**
```bash
# Start service (runs in background)
page-reloader start

# Stop service
page-reloader stop

# Restart service
page-reloader restart

# Check if running
page-reloader status
```

## 🕒 How Background Monitoring Works

### **Process Flow:**
1. **Start**: `page-reloader start` command চালালে
2. **Background**: Service background এ চলে যায়
3. **Monitoring**: Configure করা URLs গুলো check করতে থাকে
4. **Automatic**: Connection fail হলে page reload করে
5. **Logging**: সব activity `/var/log/page-reloader.log` এ save হয়

### **Example Workflow:**
```bash
# Setup (one time)
page-reloader add-url "https://your-website.com"
page-reloader set-interval 600  # Check every 10 minutes
/etc/init.d/page-reloader enable  # Auto-start on boot

# Start monitoring
page-reloader start

# ✅ Done! Service now runs in background
# You can close SSH, router will keep monitoring
```

## 📊 Monitoring Without Console

### **No Console Required:**
- ❌ **Console open রাখতে হবে না**
- ❌ **SSH session active রাখতে হবে না**
- ❌ **Screen/tmux session এর দরকার নেই**
- ✅ **Complete background operation**

### **Check Status Anytime:**
```bash
# SSH to router anytime and check
ssh root@192.168.1.1

# Check if service running
page-reloader status

# View recent activity
page-reloader logs

# See current configuration
page-reloader list-urls
page-reloader show-timing
```

## 🔍 Process Details

### **Background Process:**
```bash
# Service creates PID file
/var/run/page-reloader.pid

# Check process is running
ps | grep page-reloader

# Process runs independently
# Parent process: init (PID 1)
```

### **Logging:**
```bash
# All activity logged automatically
tail -f /var/log/page-reloader.log

# Example log output:
# 2024-01-15 10:30:15 - Starting page monitoring with interval: 600s
# 2024-01-15 10:30:15 - Page accessible: https://your-site.com
# 2024-01-15 10:40:15 - Page accessible: https://your-site.com
```

## ⚡ Quick Setup Commands

### **For Your Website:**
```bash
# SSH to router
ssh root@192.168.1.1

# Add your URL and start background monitoring
page-reloader add-url "YOUR_WEBSITE_URL_HERE"
page-reloader set-interval 600  # 10 minutes
page-reloader set-timeout 30    # 30 second timeout
page-reloader start
/etc/init.d/page-reloader enable

# ✅ Done! Monitoring runs in background
# You can logout, service keeps running
exit
```

## 🔧 Troubleshooting

### **If Service Won't Start:**
```bash
# Kill any stuck processes
pkill -f page-reloader
rm -f /var/run/page-reloader.pid

# Start fresh
page-reloader start
```

### **Check Background Status:**
```bash
# Quick status check
page-reloader status

# Detailed process info
ps aux | grep page-reloader

# Recent logs
tail -20 /var/log/page-reloader.log
```

## 📝 Summary

- ✅ **Background Service**: Runs automatically without console
- ✅ **Auto-Start**: Starts on router boot
- ✅ **Persistent**: Survives SSH disconnection  
- ✅ **Logged**: All activity recorded in log file
- ✅ **Manageable**: Start/stop/status commands available
- ✅ **Reliable**: Uses OpenWrt init.d system

**You set it up once, and it runs forever in the background!** 🚀
