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
