# UAE Wealth Builder - Personal Finance Flutter App
## Complete Developer Guide & Detailed Specification

*Privacy-First Android App for UAE Residents*  
*Maximize Savings | Auto-Parse SMS/Notifications | Local Storage Only*  
**Created: December 02, 2025** | **Target: Flutter Android (API 24+)**

---

## 📱 App Overview

**Core Value Proposition**: Passively track all UAE financial transactions from SMS/notifications, auto-categorize with local UAE merchant rules, allocate income to maximize wealth accumulation (40/20/40 split), provide aggressive optimization alerts, all while keeping 100% data privacy on-device with Google Drive encrypted backup.

**Target Users**: UAE professionals (Dubai/Abu Dhabi) wanting hands-off finance tracking without manual entry or privacy risks.

**MVP Timeline**: 4-6 weeks development.

---

## 🎨 Visual Design System

### Color Palette (UAE Theme)
```
Primary: #006400 (Deep UAE Green)
Secondary: #FFD700 (Gold Accent) 
Success: #28A745 (Savings Green)
Warning: #FFC107 (Budget Alert)
Danger: #DC3545 (Overspend Red)
Background: #FFFFFF (Clean White)
Surface: #F8F9FA (Light Gray)
Text Primary: #212529
Text Secondary: #6C757D
```

### Typography
```
Headings: Roboto Bold (24pt Dashboard, 20pt Cards, 16pt Labels)
Body: Roboto Regular (16pt data, 14pt secondary)
Numbers: Roboto Medium (20pt balances, 18pt amounts)
```

### UI Components
- **Cards**: Rounded 16px, subtle shadow (elevation 2)
- **Buttons**: Primary green fill, gold outline secondary
- **Progress**: Circular rings for budgets, linear for emergency fund
- **Charts**: fl_chart with smooth animations
- **Icons**: Material Icons with UAE flag/skyline motifs

---

## 🏗️ Complete Feature Specification

### 1. Onboarding Flow (3 Screens)

```
Screen 1: Splash + Google Sign-In
├── UAE Skyline animation (2s)
├── "Wealth Builder" title with tagline
├── Google Sign-In button (fetch name/email only)
└── Skip option (local anonymous mode)

Screen 2: Permissions Wizard
├── Notification access toggle + explanation
├── SMS read permission request
├── Google Drive backup permission
├── Progress dots (3/3 complete)
└── "All set! Data stays private on your phone"

Screen 3: Quick Setup
├── Monthly Salary input (AED 10k-50k validation)
├── Emergency Fund slider (6x salary default)
├── Currency selector (AED primary, USD secondary)
└── "Start Tracking" CTA
```

### 2. Data Capture Engine

**Background Service** (workmanager, every 5min):
```
Parse Patterns:
├── Amounts: "AED 150", "$75", "د.إ 200" 
├── Income: "credited", "salary", "refund", "transfer received"
├── Expense: "debit", "paid", "purchased", "withdrawn"
└── Merchants: Lulu, Carrefour, Talabat, DEWA, Etisalat, Salik, Emirates NBD

Transaction Schema:
```dart
class Transaction {
  String id;
  DateTime date;
  double amount;  // Positive=income, Negative=expense
  String description;
  String merchant;
  String rawText;
  Category category;  // Auto-assigned
  bool confirmed;    // User verified
  bool? isIncome;    // Null=uncertain
}
```
```

### 3. UAE-Specific Categorization Rules

**Regex Rule Engine** (100+ hardcoded UAE patterns):

```
NEEDS (40% CAP):
├── Housing: "rent|EMI|Bayut|Noor Bank|mortgage"
├── Groceries: "Lulu|Carrefour|Spinneys|Union Coop|Al Maya"
├── Utilities: "DEWA|Etisalat|du|ADDC|water|electricity"
├── Transport: "Salik|Careem|Uber|taxi|ADNOC|fuel|petrol"
├── Medical: "Thiqa|insurance|pharmacy|Medi|clinic|hospital"
└── Insurance: "AXA|Oman Insurance|home|car insurance"

WANTS (20% CAP):
├── Dining: "Talabat|Zomato|Noon Food|Deliveroo|restaurant"
├── Entertainment: "Vox|Reel|cinema|VOX Cinemas|IMG Worlds"
├── Shopping: "Noon|Amazon.ae|Mall of Emirates|Dubai Mall|Dragon Mart"
├── Subscriptions: "Netflix|Shahid|gym|ClassPass|OSN|beIN"
└── Travel: "flydubai|Emirates|AirArabia|hotel|resort"

SAVINGS/INVEST (40% MIN):
├── Income: "salary|credited|refund|bonus|transfer received"
└── Investments: "Sukuk|stocks|FAB saver|Mashreq|dividend"
```

**User Override UI**:
```
Transaction List Screen:
├── Swipe left: Edit category
├── Swipe right: Split transaction  
├── Long press: Bulk recategorize
└── "Add Rule" → Merchant → Category mapping
```

### 4. Dashboard Screens

```
HOME DASHBOARD (Main Screen):
┌─────────────────────────────┐
│ Net Worth: AED 45,230 ↑3.2% │  ← Largest metric (28pt)
├─────────────────────────────┤
│ Savings Rate: 38% ▓▓▓░░ 40% │  ← Progress ring (gold)
│ Emergency: AED 18k/60k     │
├─────────────────────────────┤
│ Charts: Pie (Spend) + Line │  ← Interactive fl_chart
│ (Monthly trend)             │
├─────────────────────────────┤
│ ALERTS: 3 cards            │
│ -  Groceries +15% over      │
│ -  Cancel Etisalat? +180/yr │
│ -  FAB saver 4.75% ready    │
└─────────────────────────────┘

BOTTOM NAV:
🏠 Dashboard | 📊 Reports | ⚙️ Settings
```

### 5. Allocation & Envelope System

```
Default 40/20/40 Split (User Adjustable Sliders):
Needs: 40% → Split across 6 sub-categories
Wants: 20% → Split across 5 sub-categories  
Savings: 40% → Emergency(25%) + Invest(15%)

Envelope UI:
┌─────────────┐  ┌─────────────┐
│ Groceries   │  │ Emergency   │
│ AED 1,200   │  │ AED 18k     │
│     /1,500  │  │   /60,000   │
│ ▓▓▓▓░░░ 80% │  │ ▓▓░░░░░░ 30%│
└───[Reallocate]──┘
```

### 6. Optimization Engine

**Weekly Scans & Alerts**:
```
1. Category Overspend: "Groceries +AED 300 vs UAE avg → Switch to Lulu"
2. Unused Subscriptions: "Netflix inactive 30d → Cancel +AED 50/m"
3. Investment Ready: "Unused Wants AED 500 → FAB saver 4.75%?"
4. Anomaly Detection: "Taxi spend 3x normal → Check Careem receipt"
5. Wealth Projection: "Save 35% → AED 1M in 18 years @7% compound"
```

**UAE Investment Benchmarks** (Static data):
```
FAB Saver: 4.75% | Mashreq: 4.5% | Sukuk: 6-7%
Avg Dubai 1BR: AED 90k/yr | Groceries: AED 18k/yr
```

---

## 💻 Technical Implementation Guide

### Core Packages
```yaml
dependencies:
  flutter:
  hive: ^2.2.3          # Local encrypted DB
  hive_flutter: ^1.1.0
  google_sign_in: ^6.2.1
  flutter_local_notifications: ^17.2.2
  workmanager: ^0.5.2    # Background service
  sms_advanced: ^0.2.0   # SMS parsing
  fl_chart: ^0.68.0      # Charts
  googleapis: ^13.1.0    # Drive backup
  googleapis_auth: ^1.6.0
  local_auth: ^2.3.0     # Biometric lock
  pdf: ^3.11.1           # Report generation
  printing: ^5.13.3      # PDF export
```

### Database Schema (Hive Boxes)
```dart
// transactions.hive
@HiveType(typeId: 0)
class Transaction {
  @HiveField(0) String id;
  @HiveField(1) DateTime date;
  @HiveField(2) double amount;
  @HiveField(3) String description;
  @HiveField(4) String merchant;
  @HiveField(5) String category;
  @HiveField(6) bool isIncome;
}

// settings.hive
@HiveType(typeId: 1)
class UserSettings {
  @HiveField(0) String name;
  @HiveField(1) String email;
  @HiveField(2) double monthlySalary;
  @HiveField(3) double emergencyFundGoal;
  @HiveField(4) Map<String, double> budgetAllocations;
}
```

---

## 🛡️ Privacy & Security

```
✅ 100% Local Storage (Encrypted Hive)
✅ Google Sign-In → Local name/email only
✅ No analytics tracking
✅ No crash reporting
✅ Encrypted Google Drive backup (AES-256)
✅ Biometric app lock
✅ No network calls except backup
✅ Transparent permission explanations
```

**Backup Flow**:
```
1. Serialize all Hive boxes to JSON
2. AES-256 encrypt with device key
3. ZIP + upload to /app_data/[device_id]/backup_[timestamp].zip
4. User-controlled restore with data wipe option
```

---

## 🔧 User Customization Features

### 1. Custom Rules Editor
```
Merchant → Category mapping UI
Regex patterns for advanced users
Bulk transaction recategorization
Export/import rule sets
```

### 2. Budget Allocation Sliders
```
Drag to adjust 40/20/40 ratios
Custom envelope creation
Carryover toggle per category
Auto-redirect unused funds
```

### 3. Data Editing
```
Transaction List → Swipe actions:
-  Edit amount/merchant/category
-  Split transaction (dinner + tip)
-  Merge duplicates
-  Delete with undo
-  Bulk select + actions
```

### 4. Settings Persistence
```
All user changes saved to settings.hive
Budget allocations persist across months
Custom rules survive app updates
Emergency fund goal updates automatically
```

---

## ⚠️ Edge Cases & Error Handling

```
1. SMS Permission Denied → Show manual entry fallback
2. Notification Parse Fail → "Uncertain" flag + manual review
3. Duplicate Transactions → Dedupe by amount+merchant+time
4. Multi-currency → Convert USD@3.67 AED fixed rate
5. Arabic SMS → RTL support + dual regex
6. Battery Optimization → Graceful background degradation
7. Low Storage → Prioritize recent 6 months data
8. App Restore → Detect device change + prompt backup restore
9. Salary Changes → Auto-adjust emergency fund goal
10. Negative Balance → High-priority alerts + debt tracking
```

---

## 📱 Screen-by-Screen Implementation Order

```
Week 1: Core
1. Splash + Google Sign-In ✅
2. Hive DB setup ✅
3. Basic transaction model ✅

Week 2: Data Engine
4. SMS/Notification parser ✅
5. Background service ✅
6. UAE categorization rules ✅

Week 3: Dashboard
7. Home screen metrics ✅
8. Pie + line charts ✅
9. Transaction list ✅

Week 4: Features
10. Budget allocation ✅
11. Alerts/optimization ✅
12. Settings + customization ✅

Week 5: Polish
13. Google Drive backup ✅
14. Biometric security ✅
15. PDF reports ✅
16. App store assets ✅
```

---

## 🚀 Launch Checklist

```
[ ] Test on 10 UAE users (real SMS patterns)
[ ] Battery optimization certification
[ ] Arabic RTL support validation
[ ] Play Store privacy policy
[ ] App icon + screenshots (UAE-themed)
[ ] Crashlytics (anonymized, opt-in only)
[ ] Beta testing (50 UAE users)
```

---

## 🔮 Future Enhancements (Phase 2)

```
- LLM-based categorization (local TFLite model)
- Bill reminders & auto-pay suggestions
- Multi-bank account aggregation
- Family shared budgets
- Investment portfolio tracking
- Zakat calculator with Islamic finance rules
- Arabic language full support
- iOS version
```

---

*Built for UAE residents by UAE residents. Privacy first, wealth always.*

**Repository**: [https://github.com/SachinSirohi/uae-wealth-builder](https://github.com/SachinSirohi/uae-wealth-builder)  
**License**: MIT  
**Contact**: er.sachinsirohi@gmail.com
