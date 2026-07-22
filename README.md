# Inventory Barcode Scanner (Envanter Tarayıcı) 📦

A simple, fast, and local-first Flutter application designed for small businesses (like stationary shops) to manage their inventory using their smartphone's camera.

## Features ✨
- **Barcode & QR Scanning:** Quickly scan products using the built-in device camera (`mobile_scanner`).
- **Local Storage:** All data is safely stored on your device offline using `shared_preferences`. No account or internet required!
- **Quantity Management:** Easily increment (+1) or decrement (-1) stock levels by scanning items.
- **Excel Export:** Export your entire inventory to an `.xlsx` file and share it instantly via WhatsApp, Email, or Telegram (`excel`, `share_plus`).

## How to Use 📱
1. Tap the **"Ürün Ekle" (Add Item)** button to open the camera and scan an incoming product. If it's new, it gets added. If it exists, the quantity increases.
2. Tap the **"Ürün Çıkart" (Remove Item)** button to scan a sold product and decrease its quantity.
3. Tap the **Download Icon** in the top right corner to export your inventory as an Excel file.

## Requirements 🛠️
- Flutter SDK (>=3.0.0)
- Android: `minSdkVersion 21` (Camera requirement)
- iOS: `iOS 11.0` or higher

## Building the App 🚀
To run the app on your connected device:
```bash
flutter pub get
flutter run
```

To build an APK for Android:
```bash
flutter build apk --release
```

## Privacy
This application does not collect, send, or store any data on external servers. Everything stays on your local device.
