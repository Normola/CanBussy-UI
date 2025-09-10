# Android WiFi "IP Configuration Failure" Fix Guide

## 🚨 **Problem: "Disconnected / IP configuration failure"**

This error occurs when your Android device can't obtain an IP address from the WiFi router's DHCP server or there's a network configuration conflict.

### 🔧 **Quick Fixes (Try First)**

#### **1. Forget and Reconnect:**
```
Settings → WiFi → Tap your network → Forget
Turn WiFi off and on
Reconnect to the network
```

#### **2. Restart Network Stack:**
```
Settings → WiFi → Turn off
Wait 10 seconds
Turn WiFi back on
Connect to network
```

#### **3. Restart Device:**
```
Hold power button → Restart
This clears Android's network cache
```

### 🛠️ **Advanced Fixes**

#### **Method 1: Use Static IP**

**When connecting to WiFi:**
1. **Tap network name** → **Connect**
2. **Tap "Advanced options"** (expand if collapsed)
3. **Change "IP settings"** from **"DHCP"** to **"Static"**
4. **Enter these values:**
   ```
   IP address: 192.168.1.100
   Gateway: 192.168.1.1
   Network prefix length: 24
   DNS 1: 8.8.8.8
   DNS 2: 1.1.1.1
   ```
5. **Connect**

#### **Method 2: Reset Network Settings**

**Android 10+:**
```
Settings → System → Reset options → Reset WiFi, mobile & Bluetooth
```

**Android 9 and below:**
```
Settings → General management → Reset → Reset network settings
```

#### **Method 3: Clear WiFi Data**

```
Settings → Apps → WiFi → Storage → Clear Data
Settings → Apps → WiFi → Storage → Clear Cache
Restart device
```

### 🔍 **Root Causes & Solutions**

#### **DHCP Server Issues:**
- **Problem:** Router's DHCP server not responding
- **Solution:** Use static IP or restart router

#### **IP Address Conflicts:**
- **Problem:** Another device using the same IP
- **Solution:** Static IP with different address (e.g., 192.168.1.150)

#### **Android WiFi Bug:**
- **Problem:** Known Android networking bugs
- **Solution:** Restart device, update Android

#### **Router Configuration:**
- **Problem:** Router blocking device or DHCP pool full
- **Solution:** Check router settings, increase DHCP range

#### **MAC Address Filtering:**
- **Problem:** Router only allows specific devices
- **Solution:** Add device MAC to router's allowed list

### 📱 **Network Information You Might Need**

#### **Common Router IP Addresses:**
```
192.168.1.1    (Most common)
192.168.0.1    (Alternative)
10.0.0.1       (Some routers)
192.168.1.254  (Some ISPs)
```

#### **Safe Static IP Ranges:**
```
192.168.1.100 - 192.168.1.199
192.168.0.100 - 192.168.0.199
10.0.0.100 - 10.0.0.199
```

#### **Reliable DNS Servers:**
```
8.8.8.8        (Google)
1.1.1.1        (Cloudflare)
8.8.4.4        (Google secondary)
1.0.0.1        (Cloudflare secondary)
```

### 🏠 **Router-Side Fixes**

#### **If You Have Router Access:**

1. **Restart Router:**
   - Unplug for 30 seconds
   - Plug back in, wait 2 minutes

2. **Check DHCP Settings:**
   - Ensure DHCP is enabled
   - IP range: 192.168.1.100-192.168.1.199
   - Lease time: 24 hours

3. **Update Router Firmware:**
   - Check manufacturer's website
   - Apply latest firmware updates

4. **Reset Router:**
   - Factory reset if all else fails
   - Reconfigure from scratch

### 📊 **Android Version Specific Issues**

#### **Android 12+:**
- More strict network permissions
- May require additional location permissions
- Try disabling "Private DNS" in network settings

#### **Android 10-11:**
- MAC randomization can cause issues
- Settings → WiFi → Privacy → Use device MAC

#### **Android 9 and below:**
- Generally fewer restrictions
- Standard troubleshooting usually works

### 🔧 **CanBussy UI App Integration**

The app now provides:

#### **Enhanced Troubleshooting:**
- **Automatic detection** of connection failures
- **Step-by-step guidance** for manual connection
- **Copy-paste network settings** for static IP
- **Real-time connection status** checking

#### **Usage in App:**
1. **Select WiFi network** from scan results
2. **Tap Connect** → Opens WiFi settings
3. **If connection fails** → Shows troubleshooting dialog
4. **Follow guided steps** → Resolve IP configuration issues
5. **Return to app** → Check connection status

### 🚀 **Prevention Tips**

#### **For Future Connections:**
- **Use 2.4GHz networks** when possible (more stable)
- **Avoid crowded channels** (1, 6, 11 are best)
- **Keep Android updated** (latest security patches)
- **Clear WiFi cache** monthly (Settings → Apps → WiFi)

#### **Router Maintenance:**
- **Restart monthly** (prevents DHCP issues)
- **Update firmware** annually
- **Monitor connected devices** (avoid overloading)
- **Use WPA3 security** if supported

### ✅ **Success Indicators**

**Connection Successful When:**
- ✅ **WiFi icon** shows connected (not exclamation mark)
- ✅ **IP address** assigned (check in WiFi settings)
- ✅ **Internet access** working (can browse web)
- ✅ **CanBussy app** can detect network and endpoint

**Still Having Issues?**
- Try different WiFi network to isolate problem
- Contact router manufacturer support
- Consider factory reset of Android device (last resort)

### 📞 **When to Seek Help**

**Contact Support If:**
- Multiple devices can't connect (router issue)
- Only your device has problems (Android issue)
- Static IP doesn't work (network configuration)
- Problem persists after all fixes (hardware issue)

This comprehensive approach should resolve most Android WiFi "IP configuration failure" issues! 🎯
