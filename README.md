# Android-15-Build-Integrity-Verification

This repository contains a practical guide, a portable verification script, and a sample ADB output for verifying Android 15 build identity and system integrity (AVB/dm-verity/Play Integrity checks).

Files:
- `scripts/verify-android15.sh` — portable script that queries device properties and stores output.
- `.gitignore` — ignoring generated outputs by default.

Usage
1. Ensure adb is installed and that the device is connected and authorized!

Optional if you want you could:
3. Make the script executable:
   chmod +x scripts/verify-android15.sh
4. Run it (output will be saved to `outputs/adb-output-<timestamp>.txt` and printed to stdout):
   ./scripts/verify-android15.sh

Interpretation notes
- `ro.boot.verifiedbootstate` == green and `ro.boot.flash.locked` == 1 are good signals that the device bootloader is locked and verified boot is intact.
- `ro.boot.veritymode` == enforcing indicates dm-verity is active.
- If `avbctl` is missing on the device, AVB may still be enforced; lack of avbctl just means the binary is not present in the shell environment.
- Play Integrity / Play Protect certification must be checked for MEETS_DEVICE_INTEGRITY and MEETS_STRONG_INTEGRITY — see the main text file.


To verify an Android 15 build and its integrity, you need to check both the software identifiers (build numbers) and the hardware-backed security state of the device. Since you’ve done this before, I’ll focus on the specific technical details for Android 15.
1. Verifying the Android 15 Build Number
Android 15 (API 35) build numbers for official Google devices (Pixel) and Generic System Images (GSI) follow a specific naming convention.
    • Prefixes: Official Android 15 builds typically start with AP31, AP3A, or AW2A (for specific patches or hardware variations).
 
For Pixel or Nexus Verification: You should cross-reference your build number with the Official Google Factory Images list.



A legitimate fingerprint for a Pixel on Android 15 will look like: google/lynx/lynx:15/AP3A.241005.015/12345678:user/release-keys.
2. Verifying System Integrity
Integrity verification relies on Android Verified Boot (AVB) and dm-verity.1 To check if the system partition has been tampered with:

A. Check Bootloader & Verified Boot State
A truly "authentic" and "intact" version requires a locked bootloader.2 You can check the state with:

Bash
adb shell getprop ro.boot.verifiedbootstate

    • green: Locked bootloader, official keys (Authentic).
    • yellow: Unlocked/Custom bootloader, custom keys.
    • orange: Unlocked bootloader, no verification.
B. Check dm-verity Status
Android 15 uses dm-verity to ensure the system partition is bit-for-bit identical to the signed image. If a single bit is changed, the device will usually fail to boot or throw an EIO (I/O error).
    • You can check if verity is active using:
Bash
adb shell getprop partition.system.verified

(Note: This prop may return the hash tree value or status depending on the OEM).
3. Play Integrity API Success Criteria
To see if your device passes Google’s official checks, the Play Integrity API replaces the old SafetyNet.
Success Requirements:
    1. MEETS_BASIC_INTEGRITY: The device is running a version of Android that hasn't been obviously tampered with (basic root checks).
    2. MEETS_DEVICE_INTEGRITY: The device has a locked bootloader and is a Google-certified Android device.
    3. MEETS_STRONG_INTEGRITY: Requires hardware-backed attestation (TEE/StrongBox). This will fail if the bootloader is unlocked or if the kernel has been modified (even with Magisk/KernelSU).
How to Check:
    • On-Device: Go to Play Store > Settings > About > Play Protect certification. It should say "Device is certified."
    • Tool: Use a third-party app like "YASNAC" or "Play Integrity API Checker" from the Play Store to see the specific failure points.
4. How to Login as Root Debug over USB
To get root access via adb root, your build must be a userdebug or eng variant. Production (user) builds block this command by default.
A. If using a userdebug build (e.g., GSI or Custom ROM):
    1. Enable Developer Options (tap Build Number 7 times).3

    2. Toggle "Rooted debugging" (this is separate from "USB debugging" and only appears on debuggable builds).
    3. Run:
Bash
adb root
adb shell

B. If using a production (user) build:
You cannot use adb root. 
 ! You could root the device manually (e.g., via Magisk or KernelSU)  
but it is not recommended 
  =!  1. Run adb shell.
  =!  2. Type su to escalate privileges.
  =!  3. Grant the request on the device screen.
[!TIP]
Warning: If you root the device or enable adb root, your Play Integrity checks (specifically MEETS_DEVICE_INTEGRITY) will likely fail unless you use a "fingerprint spoofing" module to hide the bootloader state.
