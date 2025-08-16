# Page Reloader - Quick Start Guide

আপনার জন্য একটি সম্পূর্ণ পেইজ রিলোডার টুল তৈরি করা হয়েছে যা OpenWrt রাউটারে ইনস্টল করা যাবে।

## 📦 তৈরি করা ফাইলসমূহ

### 🔧 মূল স্ক্রিপ্ট
- **`page-reloader.sh`** - মূল পেইজ রিলোডার স্ক্রিপ্ট
- **`install.sh`** - ইনস্টলেশন স্ক্রিপ্ট
- **`uninstall.sh`** - আনইনস্টল স্ক্রিপ্ট

### ⚙️ কনফিগারেশন
- **`config.example`** - উদাহরণ কনফিগারেশন ফাইল
- **`page-reloader.init`** - OpenWrt init স্ক্রিপ্ট
- **`Makefile`** - বিল্ড কনফিগারেশন

### 📚 ডকুমেন্টেশন
- **`README.md`** - সম্পূর্ণ documentation
- **`LICENSE`** - MIT লাইসেন্স
- **`.gitignore`** - Git ignore rules

## 🚀 OpenWrt রাউটারে ইনস্টল করার নিয়ম

### ধাপ ১: ফাইল আপলোড
রাউটারে SSH করে ফাইলগুলো আপলোড করুন:

```bash
# সব ফাইল সহ আপলোড করুন (GUI সহ)
scp -r * root@192.168.1.1:/tmp/page-reloader/

# অথবা wget দিয়ে GitHub থেকে ডাউনলোড করুন
wget https://github.com/your-repo/page-reloader/archive/main.zip
unzip main.zip
```

### ধাপ ২: ইনস্টলেশন
```bash
# রাউটারে SSH করুন
ssh root@192.168.1.1

# ইনস্টল directory তে যান
cd /tmp/page-reloader

# ইনস্টল স্ক্রিপ্ট চালান
chmod +x install.sh
./install.sh
```

### ধাপ ২.৫: GUI Access
```bash
# Installation complete হলে browser এ যান:
http://192.168.1.1/page-reloader/
```

### ধাপ ৩: কনফিগারেশন

**🌐 Web GUI (সহজ):**
1. Browser এ `http://192.168.1.1/page-reloader/` যান
2. "URLs" tab এ গিয়ে URL add করুন
3. "Timing" tab এ interval set করুন
4. "Dashboard" এ service start করুন

**💻 Command Line:**
```bash
# কনফিগারেশন এডিট করুন
page-reloader config

# অথবা
vi /etc/page-reloader/config
```

### ধাপ ৪: সার্ভিস চালু করুন

**🌐 Web GUI:**
- Dashboard এ "Start Service" বাটন ক্লিক করুন

**💻 Command Line:**
```bash
# সার্ভিস স্টার্ট করুন
/etc/init.d/page-reloader start

# বুট টাইমে চালু করতে
/etc/init.d/page-reloader enable

# স্ট্যাটাস চেক করুন
page-reloader status
```

## 🎯 দ্রুত কনফিগারেশন উদাহরণ

### রাউটার অ্যাডমিন ইন্টারফেস মনিটর করতে:
```bash
# /etc/page-reloader/config ফাইলে
URLS="http://192.168.1.1/cgi-bin/luci"
CHECK_INTERVAL=60
RETRY_COUNT=3
```

### ইন্টারনেট কানেক্টিভিটি চেক করতে:
```bash
URLS="https://www.google.com https://1.1.1.1"
CHECK_INTERVAL=120
TIMEOUT=15
```

### একাধিক সার্ভিস মনিটর করতে:
```bash
URLS="http://192.168.1.1 http://192.168.1.2:8080 https://github.com"
CHECK_INTERVAL=30
RETRY_COUNT=5
```

## 🛠️ প্রয়োজনীয় কমান্ড

### মূল কমান্ড
```bash
# টেস্ট করুন
page-reloader test

# লগ দেখুন
page-reloader logs

# সার্ভিস রিস্টার্ট করুন
/etc/init.d/page-reloader restart

# হেল্প দেখুন
page-reloader help
```

### 🔗 URL ম্যানেজমেন্ট
```bash
# নতুন URL যোগ করুন
page-reloader add-url "http://192.168.1.1"
page-reloader add-url "https://www.google.com"

# URL মুছে ফেলুন
page-reloader remove-url "http://192.168.1.1"

# সব URL দেখুন (স্ট্যাটাস সহ)
page-reloader list-urls

# সব URL মুছে ফেলুন
page-reloader clear-urls

# ফাইল থেকে একসাথে অনেক URL যোগ করুন
echo "http://192.168.1.1" > my-urls.txt
echo "https://github.com" >> my-urls.txt
page-reloader bulk-add my-urls.txt
```

### ⏰ টাইমিং কন্ট্রোল
```bash
# ডিফল্ট চেক ইন্টারভাল সেট করুন (সব URL এর জন্য)
page-reloader set-interval 30      # ৩০ সেকেন্ড পর পর
page-reloader set-interval 300     # ৫ মিনিট পর পর  
page-reloader set-interval 1800    # ৩০ মিনিট পর পর

# নির্দিষ্ট URL এর জন্য আলাদা ইন্টারভাল সেট করুন (নতুন!)
page-reloader set-url-interval "http://192.168.1.1" 30        # রাউটার ৩০সে পর পর
page-reloader set-url-interval "https://www.google.com" 300   # গুগল ৫মিনিট পর পর
page-reloader set-url-interval "https://github.com" 600       # গিটহাব ১০মিনিট পর পর

# কাস্টম ইন্টারভাল মুছে ফেলুন (ডিফল্ট ব্যবহার করুন)
page-reloader remove-url-interval "http://192.168.1.1"

# কানেকশন টাইমআউট সেট করুন
page-reloader set-timeout 10       # ১০ সেকেন্ড টাইমআউট
page-reloader set-timeout 30       # ৩০ সেকেন্ড টাইমআউট

# দ্রুত সেটআপের জন্য প্রিসেট ব্যবহার করুন
page-reloader set-preset fast      # দ্রুত মনিটরিং (১৫সে)
page-reloader set-preset normal    # স্বাভাবিক (৩০সে)
page-reloader set-preset slow      # ধীর (১মিনিট)
page-reloader set-preset very-slow # খুব ধীর (৫মিনিট)

# বর্তমান টাইমিং সেটিংস দেখুন
page-reloader show-timing
```

## 🌐 GitHub Repository তৈরি করতে

### ধাপ ১: Repository তৈরি করুন
1. GitHub এ নতুন repository তৈরি করুন
2. নাম দিন: `page-reloader`

### ধাপ ২: ফাইল আপলোড করুন
```bash
git init
git add .
git commit -m "Initial commit: Page Reloader Tool for OpenWrt"
git branch -M main
git remote add origin https://github.com/your-username/page-reloader.git
git push -u origin main
```

### ধাপ ৩: Release তৈরি করুন
1. GitHub এ "Releases" সেকশনে যান
2. "Create a new release" ক্লিক করুন
3. Tag version: `v1.0.0`
4. Title: `Page Reloader v1.0.0`
5. Description এ features লিখুন

## 🔄 ব্যবহারের উদাহরণ

### মূল ব্যবহার:
```bash
# সার্ভিস শুরু
page-reloader start

# সার্ভিস বন্ধ
page-reloader stop

# স্ট্যাটাস চেক
page-reloader status

# কনফিগ এডিট
page-reloader config
```

### সমস্যা সমাধান:
```bash
# URL টেস্ট করুন
page-reloader test

# লগ দেখুন
tail -f /var/log/page-reloader.log

# ম্যানুয়াল চেক
wget -O /dev/null http://your-url.com
```

## 🗑️ আনইনস্টল করতে

```bash
# ইন্টারঅ্যাক্টিভ আনইনস্টল
./uninstall.sh

# সব কিছু মুছে দিতে
./uninstall.sh --force
```

## 📞 সাহায্য প্রয়োজন?

- **সম্পূর্ণ documentation**: `README.md` ফাইল পড়ুন
- **কনফিগারেশন উদাহরণ**: `config.example` ফাইল দেখুন
- **সমস্যা**: logs চেক করুন: `/var/log/page-reloader.log`

---

🎉 **আপনার পেইজ রিলোডার টুল প্রস্তুত!** এখন OpenWrt রাউটারে ইনস্টল করে ব্যবহার করতে পারেন।
