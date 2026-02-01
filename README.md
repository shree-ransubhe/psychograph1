# PsychoGraph Check-in (iOS POC)

Daily state-of-mind check-in app with a daily 08:00 notification and a monthly graph.  
**Categories:** A (11), B (8), C (6), D (3) subcategories — labels are placeholders (A1…A11, etc.) until you add your final labels in `PsychoGraph/Models/Category.swift`.

---

## Run on your iPhone (real device)

1. **Open the project in Xcode**
   - Double-click `PsychoGraph.xcodeproj` in Finder, or in Xcode: **File → Open** and select the `PsychoGraph` folder.

2. **Connect your iPhone**
   - Use a USB cable and unlock the phone. If prompted, tap **Trust** on the device.

3. **Select your iPhone as the run destination**
   - In the Xcode toolbar, click the device dropdown (next to the scheme **PsychoGraph**).
   - Choose your iPhone (e.g. “Your Name’s iPhone”).  
   - If it doesn’t appear, wait a few seconds or unplug/replug the cable.

4. **Sign the app (required for a real device)**
   - In the project navigator (left), select the **PsychoGraph** project (blue icon).
   - Select the **PsychoGraph** target.
   - Open the **Signing & Capabilities** tab.
   - Check **Automatically manage signing**.
   - Choose your **Team** (your Apple ID).  
     - If none: **Add an Account…** and sign in with your Apple ID (free account is enough for running on your own device).

5. **Run the app**
   - Press **⌘R** or click the **Run** (play) button.
   - On first run, your iPhone may show **Untrusted Developer**.  
     - On the device: **Settings → General → VPN & Device Management** → your developer account → **Trust**.

6. **Allow notifications**
   - When the app asks for notification permission, tap **Allow** so the daily 08:00 reminder is scheduled.

---

## What’s in the POC

- **Check-in tab:** Toggle each subcategory (A1–A11, B1–B8, C1–C6, D1–D3) for today. Data is stored locally.
- **Graph tab:** Monthly grid: days 1–31 across the top, one row per subcategory; filled circle = checked, empty = not checked. Use the month/year picker to change month.
- **Settings tab:** Turn the daily reminder on/off and set hour/minute (default 08:00). “About” explains the category counts.

---

## Replacing placeholder labels

Edit `PsychoGraph/Models/Category.swift` and replace the `subcategoryLabels` arrays for A, B, C, and D with your real category names. The structure (11, 8, 6, 3) stays the same.

---

## Requirements

- **Xcode** (from the Mac App Store) — required to build and run on a device.
- **macOS** and **iPhone** with **iOS 17+**.
- **Apple ID** (free) for code signing when running on your own iPhone.
