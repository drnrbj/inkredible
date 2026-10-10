# Inkredible

**A mobile ordering and management system for printing shops**

CCE106 – Flutter Final Project
**Author:** Dranreb Jay Arzadon

---

## About the App

Many printing shops still take orders through walk-ins, chat messages, and handwritten slips. This causes long lines, mistakes in print specifications, and no clear way to track orders.

**Inkredible** lets customers order prints from their phone: upload a PDF, choose the print options, see the price, and track the order until pickup. The shop owner and staff manage every order from one dashboard, with sales analytics to help run the business.

## Features

### Customer
- Register and log in with email/password or Google
- Home screen with active orders, an order status tracker, and the shop's open/closed status
- New order with up to 3 PDFs (page count is read automatically) and a live price estimate
- Print options: paper size, color or B&W, single or double-sided, copies, binding or lamination
- Quick-order **Services** presets (e.g. thesis, color print, lamination)
- Order history with **Reorder**, and cancel an order while it is still Pending
- Notifications when an order is accepted or ready for pickup
- Profile page: edit name and profile photo

### Shop Owner / Staff
- Today's overview: new, accepted, ready, completed orders and today's sales
- Orders queue with filters, sorting, and one-tap Accept, Reject (with reason), and status update
- Order details: print specs, customer info, page-count override, internal notes
- Services and pricing: add, edit, or disable services, and pause new orders
- Sales analytics: daily, weekly, and monthly sales, busy hours, popular services, completed vs. cancelled orders, top customers

### Order Status Flow

`Pending` → `Accepted` (being printed) → `Ready` → `Done` (or `Rejected`)

## Built With

| Purpose | Technology |
|---|---|
| App | Flutter / Dart |
| Login | Firebase Authentication (email/password, Google) |
| Database | Cloud Firestore (users, orders) |
| Push notifications | Firebase Cloud Messaging, `flutter_local_notifications` |
| Profile photos | Cloudinary (free plan) |
| State management | Provider |
| Charts | `fl_chart` |
| PDF page count | `pdfx` |
| File picking | `file_picker` |

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── auth/        login, register, role routing, sign out
├── customer/    home, new order, history, services, profile
├── admin/       dashboard, orders queue, order details, services, analytics
├── services/    push notifications, Cloudinary upload
├── shared/      shared widgets, loading page
└── data/        models and ShopStore (orders, pricing, analytics)
tools/           scripts that create demo accounts and sample orders
```

## Getting Started

### Requirements
- Flutter SDK
- A Firebase project (Authentication and Firestore enabled)
- Node.js (only for the seed scripts)

### Setup

1. **Clone and install**
   ```bash
   git clone <repository-url>
   cd inkredible
   flutter pub get
   ```

2. **Connect Firebase**
   - In the Firebase console, enable **Email/Password** and **Google** sign-in, and create a **Firestore** database.
   - For Google sign-in on Android, add your SHA-1 fingerprint to the Android app.
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`.

3. **Push notifications**
   - Put a Firebase service account key at `assets/service_account.json`. This file is git-ignored and must not be committed.

4. **Profile photos**
   - Create a free Cloudinary account and an **unsigned upload preset**.
   - Set your cloud name and preset name in `lib/services/cloudinary_service.dart`.

5. **Create demo accounts and sample orders**
   ```bash
   cd tools
   npm install
   node seed_accounts.js
   node seed_orders.js --reset
   ```

6. **Run**
   ```bash
   flutter run
   ```

### Demo Accounts

| Role | Email | Password |
|---|---|---|
| Admin | admin@gmail.com | admin123 |
| Customer | customer@gmail.com | password123 |
