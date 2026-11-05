# ₱ Kinsenas

**Kinsenas** is an offline-first Philippine personal finance, utang manager, and paycheck splitter built with Flutter for Android.

Inspired by **Emil Kowalski's** micro-interaction design principles (tactile springs, clean typography, tabular figures, and purposeful motion), Kinsenas helps Filipinos take control of their finances between paydays (15th and 30th).

---

## ✨ Features

- **🗓️ Kinsenas Calendar Loading Screen:** A sleek December calendar animation where days 1–15 light up, clear, and then 16–31 light up to represent the 1st and 2nd pay cutoffs.
- **💸 Philippine Sahod & Tax Splitter:**
  - Supports both **Monthly Salary** and **Daily Wage ("Arawan")**.
  - Automatically calculates **SSS (2024–2026 table)**, **PhilHealth (5% premium / 2.5% share)**, **Pag-IBIG (₱200 cap)**, and **TRAIN Law Withholding Tax**.
  - Philippine Minimum Wage Exemption support (0% tax for statutory minimum wage earners).
  - Flexible deduction timing: 15th only, 30th only, or 50/50 split across both cutoffs.
- **🎯 Goals & Ipon Hub:**
  - Renameable goals (e.g. `FOR MOTOR ✏️`) with inline editing.
  - Tactile circular progress coin graphic.
- **🤝 Utang Hub with Switch & Backdated Payments:**
  - Unified toggle switch between **"Utang Ko" (Payables/BNPL)** and **"May Utang Sakin" (Receivables)**.
  - Custom past-date picker so you can log payments accurately even if you forgot to update on time.
- **🔒 Offline-First & Google Drive Backup:**
  - All data is saved on your device's local SQLite database.
  - Optional zero-server backup to your personal Google Drive (`appDataFolder`).

---

## 🚀 Getting Started

1. Ensure Flutter is installed on your machine (`flutter --version`).
2. Run `flutter pub get` to install dependencies.
3. Launch the app on an Android emulator or device:
   ```bash
   flutter run
   ```
