# Shelly Caddy TLS - Reverse Proxy Solution

This repository documents the solution for serving Shelly Gen2/Gen3 device web UIs over HTTPS through Caddy reverse proxy.

## Problem

Shelly devices serve their web UI over HTTP only. When attempting to reverse proxy through HTTPS, the web UI fails because:

1. The device's JavaScript hardcodes `ws://` for WebSocket connections
2. Browsers block insecure WebSocket connections (`ws://`) from HTTPS pages
3. The device always serves gzip-compressed content, making on-the-fly replacement impossible
4. The device ignores `Accept-Encoding` headers

## Solution

Instead of trying to modify responses on-the-fly, we:

1. Download and decompress the web UI HTML from the device
2. Patch `ws://` to `wss://` in the downloaded file
3. Serve the patched HTML from Caddy
4. Proxy only the `/rpc` WebSocket endpoint to the device

### Step-by-Step Instructions

#### 1. Download and patch the Shelly web UI

```bash
# Create directory for the patched HTML
sudo mkdir -p /var/www/shelly-device

# Download and decompress the HTML from your Shelly device
curl -s http://YOUR_DEVICE_IP:80/ | gunzip | sudo tee /var/www/shelly-device/index.html > /dev/null

# Replace ws:// with wss://
sudo sed -i 's/ws:\/\//wss:\/\//g' /var/www/shelly-device/index.html

# Verify the replacement worked (should show 0)
grep -c 'ws://' /var/www/shelly-device/index.html
```

#### 2. Configure Caddy

Add this to your Caddyfile:

```
your-device.example.com {
    encode gzip

    # Proxy WebSocket endpoint to device
    reverse_proxy /rpc* YOUR_DEVICE_IP:80

    # Serve the patched HTML for everything else
    root * /var/www/shelly-device
    file_server
}
```

#### 3. Reload Caddy

```bash
sudo systemctl reload caddy
```

#### 4. Access your device

Navigate to `https://your-device.example.com` - the web UI should now work with secure WebSocket connections!

## Important Notes

- **Firmware updates**: If you update the Shelly firmware, you'll need to re-download and re-patch the HTML file, as the web UI may change
- **Multiple devices**: Repeat the process for each device, creating separate directories (e.g., `/var/www/device1`, `/var/www/device2`)
- **Certificate management**: Caddy automatically handles Let's Encrypt certificates for your domain

## Credit

Solution based on discussion in the [Shelly Community Forums](https://community.shelly.cloud/topic/8667-reverse-proxy-support/#findComment-37710).

## License

Apache License 2.0
