#!/usr/bin/env python3
"""
Build properly signed APK with custom logo for Aether Empires
Fixes: signature files, app logo
"""

import os
import zipfile
import shutil
from PIL import Image
import subprocess
import tempfile

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE_APK = os.path.expanduser("~/.local/share/godot/export_templates/4.4.1.stable/android_debug.apk")
CUSTOM_ICON_512 = os.path.join(BASE_DIR, "assets/icons/app_icon_512.png")
CUSTOM_ICON_192 = os.path.join(BASE_DIR, "assets/icons/app_icon_192.png")
ICON_PNG = os.path.join(BASE_DIR, "icon.png")
OUTPUT_APK = os.path.join(BASE_DIR, "builds/AetherEmpires.apk")
KEYSTORE = os.path.join(BASE_DIR, "debug.keystore")
KEYSTORE_JKS = os.path.join(BASE_DIR, "debug.jks")

# Ensure builds dir
os.makedirs(os.path.join(BASE_DIR, "builds"), exist_ok=True)

print("=== Building Signed APK with Custom Logo ===")
print(f"Template: {TEMPLATE_APK}")
print(f"Custom Icon 512: {CUSTOM_ICON_512}")
print(f"Output: {OUTPUT_APK}")

# Check files exist
if not os.path.exists(TEMPLATE_APK):
    print(f"ERROR: Template APK not found: {TEMPLATE_APK}")
    exit(1)

if not os.path.exists(CUSTOM_ICON_512):
    print(f"ERROR: Custom icon not found: {CUSTOM_ICON_512}")
    exit(1)

# Create temp directory for APK manipulation
with tempfile.TemporaryDirectory() as tmpdir:
    print(f"Working in: {tmpdir}")
    
    # Unzip template APK
    print("Unzipping template APK...")
    with zipfile.ZipFile(TEMPLATE_APK, 'r') as z:
        z.extractall(tmpdir)
    
    # Generate icons for different densities
    # Android mipmap densities: mdpi 48x48, hdpi 72x72, xhdpi 96x96, xxhdpi 144x144, xxxhdpi 192x192
    densities = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192
    }
    
    # Load custom icon
    custom_img = Image.open(CUSTOM_ICON_512)
    
    for density, size in densities.items():
        # Find mipmap folders for this density
        import glob
        pattern = os.path.join(tmpdir, f"res/mipmap-{density}*/icon.png")
        files = glob.glob(pattern)
        if not files:
            # Try without v4
            pattern = os.path.join(tmpdir, f"res/mipmap-{density}/icon.png")
            files = glob.glob(pattern)
        
        for icon_path in files:
            print(f"Replacing {icon_path} with {size}x{size} custom icon")
            resized = custom_img.resize((size, size), Image.LANCZOS)
            resized.save(icon_path, "PNG")
        
        # Also check for other densities like hdpi-v4 etc
        # We'll replace all icon.png files we find
        all_icons = glob.glob(os.path.join(tmpdir, "res/mipmap-*/icon.png"))
        for icon_path in all_icons:
            # Determine size from folder name
            if density in icon_path:
                if os.path.exists(icon_path):
                    # Only replace if not already replaced
                    try:
                        resized = custom_img.resize((size, size), Image.LANCZOS)
                        resized.save(icon_path, "PNG")
                    except:
                        pass
    
    # Replace all mipmap icons with appropriate sizes
    # More comprehensive replacement
    for root, dirs, files in os.walk(os.path.join(tmpdir, "res")):
        for file in files:
            if file == "icon.png" and "mipmap" in root:
                full_path = os.path.join(root, file)
                # Determine density from path
                size = 96  # default
                if "mdpi" in root:
                    size = 48
                elif "hdpi" in root:
                    size = 72
                elif "xhdpi" in root:
                    size = 96
                elif "xxhdpi" in root:
                    size = 144
                elif "xxxhdpi" in root:
                    size = 192
                
                print(f"Replacing {full_path} -> {size}x{size}")
                try:
                    resized = custom_img.resize((size, size), Image.LANCZOS)
                    resized.save(full_path, "PNG")
                except Exception as e:
                    print(f"Failed to replace {full_path}: {e}")
    
    # Also add our custom icon as adaptive foreground if exists
    # For adaptive icon, we need to replace icon_background and foreground
    # We'll keep background but ensure foreground is our custom
    
    # Create new APK (unsigned)
    unsigned_apk = os.path.join(BASE_DIR, "builds/AetherEmpires_unsigned.apk")
    print(f"Creating unsigned APK: {unsigned_apk}")
    
    # Remove old signature files if any
    for sig_file in ["META-INF/MANIFEST.MF", "META-INF/CERT.SF", "META-INF/CERT.RSA", "META-INF/ANDROIDD.SF", "META-INF/ANDROIDD.RSA"]:
        sig_path = os.path.join(tmpdir, sig_file)
        if os.path.exists(sig_path):
            os.remove(sig_path)
            print(f"Removed old signature: {sig_file}")
    
    # Zip up
    with zipfile.ZipFile(unsigned_apk, 'w', zipfile.ZIP_DEFLATED) as z:
        for root, dirs, files in os.walk(tmpdir):
            for file in files:
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, tmpdir)
                z.write(full_path, rel_path)
    
    print(f"Unsigned APK created: {unsigned_apk} ({os.path.getsize(unsigned_apk)} bytes)")
    
    # Now sign the APK
    # Use Java 17 if available
    java_home = "/tmp/jdk-17.0.11+9"
    if os.path.exists(java_home):
        os.environ["JAVA_HOME"] = java_home
        os.environ["PATH"] = f"{java_home}/bin:{os.environ['PATH']}"
    
    android_home = os.path.expanduser("~/android-sdk")
    build_tools = os.path.join(android_home, "build-tools/34.0.0")
    apksigner = os.path.join(build_tools, "apksigner")
    
    if not os.path.exists(apksigner):
        # Try alternative path
        apksigner = os.path.join(android_home, "build-tools/33.0.2/apksigner")
    
    if not os.path.exists(apksigner):
        print(f"apksigner not found at {apksigner}, trying to find...")
        import glob
        found = glob.glob(os.path.expanduser("~/android-sdk/build-tools/*/apksigner"))
        if found:
            apksigner = found[0]
            print(f"Found apksigner: {apksigner}")
    
    # Determine keystore to use
    ks = KEYSTORE_JKS if os.path.exists(KEYSTORE_JKS) else KEYSTORE
    if not os.path.exists(ks):
        print(f"Keystore not found: {ks}, creating new JKS...")
        subprocess.run([
            "keytool", "-genkey", "-v",
            "-keystore", ks,
            "-storetype", "JKS",
            "-storepass", "android",
            "-alias", "androiddebugkey",
            "-keypass", "android",
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "10000",
            "-dname", "CN=Debug,O=Android,C=US"
        ], check=True)
    
    print(f"Signing APK with keystore: {ks}")
    print(f"Using apksigner: {apksigner}")
    
    # Sign
    cmd = [
        apksigner, "sign",
        "--ks", ks,
        "--ks-key-alias", "androiddebugkey",
        "--ks-pass", "pass:android",
        "--key-pass", "pass:android",
        "--v1-signing-enabled", "true",
        "--v2-signing-enabled", "true",
        "--v3-signing-enabled", "true",
        "--out", OUTPUT_APK,
        unsigned_apk
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    print("apksigner stdout:", result.stdout)
    print("apksigner stderr:", result.stderr)
    print(f"apksigner return code: {result.returncode}")
    
    if result.returncode != 0:
        print("Signing failed!")
        exit(1)
    
    # Verify
    print("Verifying APK signature...")
    verify_cmd = [apksigner, "verify", "--verbose", OUTPUT_APK]
    result = subprocess.run(verify_cmd, capture_output=True, text=True)
    print(result.stdout)
    print(result.stderr)
    
    # Check for signature files
    print("Checking signature files in signed APK...")
    with zipfile.ZipFile(OUTPUT_APK, 'r') as z:
        sig_files = [name for name in z.namelist() if "META-INF" in name and ("MANIFEST" in name or "CERT" in name or ".SF" in name or ".RSA" in name)]
        for f in sig_files[:20]:
            print(f"  {f}")
        if not sig_files:
            print("  No signature files found!")
        else:
            print(f"  Found {len(sig_files)} signature-related files")
    
    # Check icon files
    print("Checking icon files in signed APK...")
    with zipfile.ZipFile(OUTPUT_APK, 'r') as z:
        icon_files = [name for name in z.namelist() if "mipmap" in name and "icon.png" in name]
        for f in icon_files[:10]:
            print(f"  {f}")
    
    print(f"\n=== APK Build Complete ===")
    print(f"Output: {OUTPUT_APK}")
    print(f"Size: {os.path.getsize(OUTPUT_APK)} bytes")
    print(f"File type: {subprocess.run(['file', OUTPUT_APK], capture_output=True, text=True).stdout}")

if __name__ == "__main__":
    pass
