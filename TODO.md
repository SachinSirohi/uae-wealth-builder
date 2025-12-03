# Personal Wealth Builder - TODO & Feature Roadmap

**Last Updated:** December 3, 2024  
**Repository:** [SachinSirohi/uae-wealth-builder](https://github.com/SachinSirohi/uae-wealth-builder)

---

## 🚨 Critical Issues (Priority 1)

### Issue #1: Google Login Not Working
**Status:** ❌ To Do  
**Priority:** Critical  
**Estimated Effort:** 2-3 days

**Problem:** Google Sign-In authentication flow is not functioning properly.

**Tasks:**
- [ ] Verify Google Sign-In configuration in `pubspec.yaml`
- [ ] Check Google Cloud Console project setup
  - [ ] Ensure OAuth 2.0 Client ID is created for Android
  - [ ] Add SHA-1 and SHA-256 fingerprints to Firebase/Google Cloud Console
  - [ ] Verify redirect URIs are configured correctly
- [ ] Update `android/app/build.gradle` with correct signing configuration
- [ ] Test Google Sign-In flow in `lib/screens/onboarding/google_signin_screen.dart`
- [ ] Add error logging and user-friendly error messages
- [ ] Test with different Google accounts
- [ ] Add fallback/retry mechanism for failed sign-ins

**Dependencies:**
- Google Cloud Console access
- Firebase project setup (if using Firebase)
- Android app signing certificate

**Files to Update:**
- `android/app/build.gradle`
- `android/app/google-services.json` (if using Firebase)
- `lib/screens/onboarding/google_signin_screen.dart`
- `lib/services/google_drive_service.dart`

---

### Issue #2: Biometric Lock Not Working
**Status:** ❌ To Do  
**Priority:** Critical  
**Estimated Effort:** 1-2 days

**Problem:** Biometric authentication (fingerprint/face recognition) is not functioning.

**Tasks:**
- [ ] Verify `local_auth` package implementation in `lib/screens/security/app_lock_screen.dart`
- [ ] Check Android permissions in `AndroidManifest.xml`
  - [ ] `USE_BIOMETRIC` or `USE_FINGERPRINT` permission
- [ ] Test biometric availability detection
- [ ] Implement proper error handling for biometric failures
- [ ] Add PIN fallback when biometrics unavailable
- [ ] Test on devices with different biometric types (fingerprint, face, iris)
- [ ] Handle edge cases:
  - [ ] No biometrics enrolled
  - [ ] Biometric hardware not available
  - [ ] Too many failed attempts
- [ ] Add settings toggle to enable/disable biometric lock

**Files to Update:**
- `android/app/src/main/AndroidManifest.xml`
- `lib/screens/security/app_lock_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/models/user_settings.dart`

---

### Issue #3: Setup Screen Appears Every Time App Restarts
**Status:** ❌ To Do  
**Priority:** Critical  
**Estimated Effort:** 1 day

**Problem:** Setup/onboarding screens are shown every time the app is closed and reopened instead of only on first launch or after data deletion.

**Tasks:**
- [ ] Implement persistent flag in `UserSettings` model to track if setup is completed
- [ ] Check setup completion status in `main.dart` or splash screen
- [ ] Route to Dashboard if setup is already completed
- [ ] Only show onboarding flow if:
  - [ ] First time launch (no settings saved)
  - [ ] User explicitly cleared all data
  - [ ] User logged out and removed account
- [ ] Add logic in `lib/screens/splash_screen.dart` to determine initial route
- [ ] Ensure Hive box persistence is working correctly
- [ ] Test app restart scenarios

**Files to Update:**
- `lib/models/user_settings.dart` (add `isSetupCompleted` field)
- `lib/screens/splash_screen.dart`
- `lib/main.dart`
- `lib/screens/onboarding/quick_setup_screen.dart` (set flag on completion)

---

### Issue #4: Receipt Scanner Not Adding Transactions
**Status:** ❌ To Do  
**Priority:** High  
**Estimated Effort:** 2-3 days

**Problem:** When scanning a receipt, the app shows AED amount but doesn't add it to transactions or prompt user for input.

**Tasks:**
- [ ] Review current implementation in `lib/services/invoice_scanner_service.dart`
- [ ] Create a new screen: `lib/screens/transactions/review_scanned_receipt_screen.dart`
- [ ] After successful OCR scan, navigate to review screen with:
  - [ ] Editable amount field (pre-filled from OCR)
  - [ ] Category selector dropdown
  - [ ] Merchant/description field (editable)
  - [ ] Date picker (default to today)
  - [ ] Transaction type (Income/Expense) toggle
  - [ ] Notes field
  - [ ] Scanned receipt image preview
- [ ] Add "Save Transaction" and "Cancel" buttons
- [ ] Validate all required fields before saving
- [ ] Add transaction to database on save
- [ ] Show success message and navigate to transaction list
- [ ] Improve OCR accuracy for AED amounts
- [ ] Handle multiple items on single receipt (optional: split transaction)

**Files to Update:**
- `lib/services/invoice_scanner_service.dart`
- Create: `lib/screens/transactions/review_scanned_receipt_screen.dart`
- `lib/screens/dashboard/transaction_list_screen.dart`
- `lib/services/database_service.dart`

---

## ✨ New Features (Priority 2)

### Feature #1: Google Drive Backup & Restore
**Status:** 🔄 Partially Implemented  
**Priority:** High  
**Estimated Effort:** 3-4 days

**Current State:** Google Drive service exists but needs full integration for backup/restore functionality.

#### Sub-feature 1.1: Google Login & Logout
**Tasks:**
- [ ] Fix Google Sign-In (see Issue #1)
- [ ] Add "Sign Out" option in Settings
- [ ] Clear Google Drive connection state on logout
- [ ] Show current logged-in Google account in Settings
- [ ] Add re-authentication flow if token expires
- [ ] Handle logout edge cases:
  - [ ] Pending backup operations
  - [ ] Auto-backup enabled
  - [ ] Restore in progress

**Files to Update:**
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/settings/google_drive_backup_screen.dart`
- `lib/services/google_drive_service.dart`

#### Sub-feature 1.2: Google Drive Backup
**Tasks:**
- [ ] Implement manual "Backup Now" button
- [ ] Show backup progress indicator
- [ ] Display last successful backup timestamp
- [ ] Show backup file size
- [ ] Add backup frequency settings (Daily, Weekly, Monthly, Manual)
- [ ] Implement auto-backup scheduler using WorkManager
- [ ] Backup content should include:
  - [ ] All transactions
  - [ ] User settings
  - [ ] Custom categorization rules
  - [ ] Budget allocations
- [ ] Encrypt backup data before upload (AES-256)
- [ ] Use user's Gmail ID as encryption key base
- [ ] Show success/failure notifications
- [ ] Handle backup errors gracefully
- [ ] Manage old backups (keep last 5, delete older)

**Files to Update:**
- `lib/screens/settings/google_drive_backup_screen.dart`
- `lib/services/google_drive_service.dart`
- `lib/services/backup_service.dart`
- `lib/services/auto_backup_scheduler.dart`

#### Sub-feature 1.3: Restore from Google Drive
**Tasks:**
- [ ] Add "Restore from Backup" button in Settings
- [ ] List available backups with metadata:
  - [ ] Backup date/time
  - [ ] File size
  - [ ] Number of transactions
  - [ ] Device name (if available)
- [ ] Allow user to select which backup to restore
- [ ] Show warning before restoring (will overwrite current data)
- [ ] Add option to merge with existing data vs. full replace
- [ ] Download and decrypt backup file
- [ ] Validate backup integrity
- [ ] Restore data to Hive boxes
- [ ] Show progress indicator during restore
- [ ] Handle restore errors with rollback capability
- [ ] Show success message with summary of restored data

**Files to Update:**
- `lib/screens/settings/google_drive_backup_screen.dart`
- `lib/services/google_drive_service.dart`
- `lib/services/backup_service.dart`
- Create: `lib/screens/settings/restore_backup_screen.dart`

#### Sub-feature 1.4: Data Encryption
**Tasks:**
- [ ] Implement encryption key generation from Gmail ID
- [ ] Add salt and hashing for key derivation (PBKDF2 or similar)
- [ ] Encrypt all data before Google Drive upload using AES-256
- [ ] Decrypt data after download before restore
- [ ] Store encryption metadata with backup (algorithm, salt, version)
- [ ] Ensure data can only be decrypted by same user account
- [ ] Add encryption status indicator in UI
- [ ] Test encryption/decryption with different Gmail accounts
- [ ] Handle encryption errors gracefully

**Files to Update:**
- `lib/services/backup_service.dart`
- `lib/services/google_drive_service.dart`
- Create: `lib/services/encryption_service.dart`

---

### Feature #2: Enhanced Setup Process
**Status:** 🔄 Partially Implemented  
**Priority:** Medium  
**Estimated Effort:** 2 days

**Current State:** Basic setup exists but missing account balance and investment portfolio screens.

#### Sub-feature 2.1: Total Account Balance Screen
**Tasks:**
- [ ] Create new screen: `lib/screens/onboarding/account_balance_screen.dart`
- [ ] Add screen to onboarding flow after quick setup
- [ ] Input fields:
  - [ ] Savings account balance (AED)
  - [ ] Current account balance (AED)
  - [ ] Cash on hand (AED)
  - [ ] Other liquid assets (AED)
  - [ ] Total calculation (auto-sum)
- [ ] Add validation for numeric inputs
- [ ] Store values in `UserSettings` model
- [ ] Update progress indicator in onboarding wizard
- [ ] Add "Skip" option for users who prefer to add later
- [ ] Show helpful tips about why this information is useful

**Files to Update:**
- Create: `lib/screens/onboarding/account_balance_screen.dart`
- `lib/models/user_settings.dart` (add balance fields)
- `lib/screens/onboarding/onboarding_wizard_screen.dart`

#### Sub-feature 2.2: Investment Portfolio Screen
**Tasks:**
- [ ] Create new screen: `lib/screens/onboarding/investment_portfolio_screen.dart`
- [ ] Add screen to onboarding flow after account balance
- [ ] Input fields:
  - [ ] Stocks/Equities value (AED)
  - [ ] Sukuk/Bonds value (AED)
  - [ ] Mutual Funds/ETFs value (AED)
  - [ ] Real Estate value (AED)
  - [ ] Cryptocurrency (AED)
  - [ ] Gold/Precious Metals (AED)
  - [ ] Other investments (AED)
  - [ ] Total portfolio value (auto-sum)
- [ ] Add validation for numeric inputs
- [ ] Store values in `UserSettings` model
- [ ] Update net worth calculation to include investments
- [ ] Add "Skip" option
- [ ] Show investment allocation pie chart preview

**Files to Update:**
- Create: `lib/screens/onboarding/investment_portfolio_screen.dart`
- `lib/models/user_settings.dart` (add investment fields)
- `lib/screens/onboarding/onboarding_wizard_screen.dart`
- `lib/services/database_service.dart` (update net worth calculation)

---

### Feature #3: Clickable Dashboard Cards with Detailed Views
**Status:** ❌ To Do  
**Priority:** High  
**Estimated Effort:** 5-7 days

**Description:** Make all dashboard cards interactive with detailed drill-down views and analysis.

#### Sub-feature 3.1: Net Worth Detail Screen
**Tasks:**
- [ ] Create screen: `lib/screens/analytics/net_worth_detail_screen.dart`
- [ ] Display features:
  - [ ] Month-over-month net worth trend (line chart)
  - [ ] Year-over-year comparison
  - [ ] Net worth breakdown (Assets vs Liabilities)
  - [ ] Main sources of increase/decrease
  - [ ] Categorized contribution to net worth:
    - [ ] Salary/Income
    - [ ] Investment gains/losses
    - [ ] Savings accumulation
    - [ ] Expense reduction
  - [ ] Actionable insights:
    - [ ] "Increase savings rate by 5% to reach AED 1M in X years"
    - [ ] "Pay off high-interest debt to improve net worth"
    - [ ] "Investment portfolio grew by X% this month"
  - [ ] Industry-standard metrics:
    - [ ] Net Worth Growth Rate (%)
    - [ ] Net Worth to Income Ratio
    - [ ] Asset to Liability Ratio
    - [ ] Liquid Net Worth (excluding real estate)
  - [ ] Projections:
    - [ ] Net worth forecast for next 6/12/24 months
    - [ ] Goal tracking (e.g., "65% to AED 1M goal")
- [ ] Make Net Worth card on dashboard clickable
- [ ] Add period selector (1M, 3M, 6M, 1Y, All Time)
- [ ] Export capability (PDF report)

**Files to Update:**
- Create: `lib/screens/analytics/net_worth_detail_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart` (add onTap to Net Worth card)
- `lib/services/database_service.dart` (add historical net worth queries)

#### Sub-feature 3.2: Savings Rate Detail Screen
**Tasks:**
- [ ] Create screen: `lib/screens/analytics/savings_rate_detail_screen.dart`
- [ ] Display features:
  - [ ] Monthly savings rate trend (bar chart)
  - [ ] Comparison to 40% target
  - [ ] Savings breakdown by category
  - [ ] Factors affecting savings rate:
    - [ ] Income changes
    - [ ] Expense changes
    - [ ] One-time expenses
  - [ ] Actionable recommendations:
    - [ ] "Reduce dining out by AED 500 to reach 40% target"
    - [ ] "You're saving 5% above target - invest the surplus"
  - [ ] Industry benchmarks:
    - [ ] UAE average savings rate
    - [ ] Global best practices
    - [ ] Recommended rate by income level
  - [ ] Savings allocation analysis
  - [ ] Emergency fund progress
- [ ] Make Savings Rate card clickable
- [ ] Add comparison to previous periods
- [ ] Show peer comparisons (optional, if data available)

**Files to Update:**
- Create: `lib/screens/analytics/savings_rate_detail_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`

#### Sub-feature 3.3: Emergency Fund Detail Screen
**Tasks:**
- [ ] Create screen: `lib/screens/analytics/emergency_fund_detail_screen.dart`
- [ ] Display features:
  - [ ] Progress to goal (visual ring/bar)
  - [ ] Monthly contribution tracking
  - [ ] Time to reach goal (at current rate)
  - [ ] Recommended monthly contribution
  - [ ] Fund adequacy analysis:
    - [ ] Months of expenses covered
    - [ ] Comparison to recommended 6 months
  - [ ] Actionable insights:
    - [ ] "Increase monthly contribution by AED X to reach goal in Y months"
    - [ ] "Your emergency fund can cover Z months of expenses"
  - [ ] What-if scenarios:
    - [ ] Impact of income loss
    - [ ] Major emergency expense simulation
  - [ ] Recommendations for fund placement:
    - [ ] High-yield savings accounts in UAE
    - [ ] Liquid investment options
- [ ] Make Emergency Fund card clickable
- [ ] Add ability to adjust goal directly from this screen

**Files to Update:**
- Create: `lib/screens/analytics/emergency_fund_detail_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`

#### Sub-feature 3.4: Budget Category Detail Screens
**Tasks:**
- [ ] Create screen: `lib/screens/analytics/category_detail_screen.dart`
- [ ] Make each budget category card clickable (Needs, Wants, Savings)
- [ ] Display features for each category:
  - [ ] Spending trend over time
  - [ ] Sub-category breakdown
  - [ ] Comparison to budget
  - [ ] Top merchants in category
  - [ ] Unusual spending patterns
  - [ ] Recommendations:
    - [ ] "Switch to Lulu for groceries to save AED X/month"
    - [ ] "Cancel Netflix subscription - not used in 30 days"
    - [ ] "Dining out 2x over budget - reduce by AED X"
  - [ ] Industry benchmarks:
    - [ ] UAE average spending by category
    - [ ] Recommended % of income
  - [ ] Cost-saving opportunities
  - [ ] Transaction list filtered by category
- [ ] Add drill-down to sub-categories
- [ ] Export category report

**Files to Update:**
- Create: `lib/screens/analytics/category_detail_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/screens/budget/budget_screen.dart`

#### Sub-feature 3.5: Recent Transactions Detail
**Tasks:**
- [ ] Make "View All" clickable on Recent Transactions section
- [ ] Enhance existing `transaction_list_screen.dart` with:
  - [ ] Advanced filtering (by category, date range, amount range)
  - [ ] Sorting options (date, amount, merchant)
  - [ ] Search functionality
  - [ ] Grouped views (by day, week, month, category)
  - [ ] Transaction analytics summary at top
  - [ ] Bulk actions (select multiple, categorize, delete)
- [ ] Add swipe actions for quick edit/delete

**Files to Update:**
- `lib/screens/dashboard/transaction_list_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`

---

### Feature #4: Spending Breakdown Analysis
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 2-3 days

**Description:** Add comprehensive spending breakdown similar to budget breakdown showing where money is being spent.

**Tasks:**
- [ ] Create screen: `lib/screens/analytics/spending_breakdown_screen.dart`
- [ ] Add navigation from Dashboard (new card or menu item)
- [ ] Display features:
  - [ ] Pie chart of spending by category
  - [ ] Bar chart of spending by merchant
  - [ ] Timeline view of spending patterns
  - [ ] Top spending categories (ranked)
  - [ ] Top merchants (ranked)
  - [ ] Spending heatmap (day of week / time of day)
  - [ ] Unusual spending alerts
  - [ ] Comparison to previous periods:
    - [ ] This month vs last month
    - [ ] This month vs same month last year
  - [ ] Spending trends:
    - [ ] Increasing categories
    - [ ] Decreasing categories
    - [ ] New spending categories
  - [ ] Average transaction size by category
  - [ ] Payment method breakdown (if data available)
  - [ ] Fixed vs. variable expenses
- [ ] Add filters:
  - [ ] Date range selector
  - [ ] Category filter
  - [ ] Merchant filter
  - [ ] Amount range
- [ ] Export spending report (PDF/CSV)
- [ ] Share spending insights

**Files to Update:**
- Create: `lib/screens/analytics/spending_breakdown_screen.dart`
- `lib/screens/dashboard/dashboard_screen.dart`
- `lib/services/database_service.dart` (add spending analysis queries)

---

### Feature #5: Notification-Based Transaction Capture
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 4-5 days

**Description:** Read notifications from all apps and categorize them into transactions with type and amount.

**Tasks:**
- [ ] Request notification listener permission
- [ ] Create `lib/services/notification_listener_service.dart`
- [ ] Implement NotificationListenerService (Android)
- [ ] Parse notifications from banking apps:
  - [ ] Emirates NBD
  - [ ] ADCB
  - [ ] Mashreq Bank
  - [ ] FAB (First Abu Dhabi Bank)
  - [ ] DIB (Dubai Islamic Bank)
  - [ ] RAKBANK
  - [ ] ENBD (Emirates Islamic)
  - [ ] Others (extensible)
- [ ] Parse notifications from payment apps:
  - [ ] Apple Pay
  - [ ] Google Pay
  - [ ] Samsung Pay
  - [ ] PayPal
  - [ ] Beam Wallet
- [ ] Parse notifications from e-commerce/service apps:
  - [ ] Noon
  - [ ] Amazon.ae
  - [ ] Talabat
  - [ ] Careem
  - [ ] Deliveroo
- [ ] Extract transaction details:
  - [ ] Amount (with currency)
  - [ ] Merchant name
  - [ ] Transaction type (debit/credit)
  - [ ] Timestamp
  - [ ] Transaction reference/ID
  - [ ] Account/card used (last 4 digits)
- [ ] Auto-categorize based on notification source and content
- [ ] Store raw notification text for reference
- [ ] Mark as unconfirmed for user review
- [ ] Filter out non-financial notifications
- [ ] Handle notification parsing errors gracefully
- [ ] Add settings to enable/disable notification parsing per app
- [ ] Test with real UAE banking apps

**Files to Update:**
- Create: `lib/services/notification_listener_service.dart`
- `android/app/src/main/AndroidManifest.xml` (add notification listener permission)
- Create: `android/app/src/main/kotlin/com/example/personal_finance_uae/NotificationListener.kt`
- `lib/screens/settings/settings_screen.dart` (add notification settings)
- `lib/services/database_service.dart`

---

### Feature #6: SMS-Based Transaction Extraction
**Status:** 🔄 Partially Implemented  
**Priority:** Medium  
**Estimated Effort:** 2-3 days

**Description:** Enhanced SMS reading to extract all transaction details automatically.

**Tasks:**
- [ ] Expand SMS parsing patterns in `sms_parser_service.dart`
- [ ] Extract additional details:
  - [ ] Transaction reference number
  - [ ] Account number (masked)
  - [ ] Available balance (if mentioned)
  - [ ] Card type (debit/credit)
  - [ ] Transaction timestamp (if different from SMS time)
  - [ ] Location/merchant address
- [ ] Improve accuracy for different SMS formats:
  - [ ] Arabic SMS messages
  - [ ] Multi-language SMS (English + Arabic)
  - [ ] Different bank SMS templates
- [ ] Add SMS templates for new UAE banks
- [ ] Parse OTP vs. transaction SMS (filter OTPs)
- [ ] Handle SMS with multiple transactions
- [ ] Extract promotional/cashback information
- [ ] Test with real SMS from different UAE banks
- [ ] Add user feedback mechanism for incorrect parsing
- [ ] Learn from user corrections (optional ML/rules)

**Files to Update:**
- `lib/services/sms_parser_service.dart`
- `lib/services/background_service.dart`

---

### Feature #7: Duplicate Transaction Management
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 3-4 days

**Description:** Detect and manage duplicate transactions from multiple sources (bank app notification, email, SMS).

**Tasks:**
- [ ] Create duplicate detection algorithm:
  - [ ] Match by amount + date (within 1 minute)
  - [ ] Match by amount + merchant
  - [ ] Match by transaction reference ID
  - [ ] Fuzzy matching for merchant names
  - [ ] Consider currency for multi-currency transactions
- [ ] Create duplicate resolution screen: `lib/screens/transactions/duplicate_resolution_screen.dart`
- [ ] Flag potential duplicates with confidence score:
  - [ ] High confidence (exact match)
  - [ ] Medium confidence (likely duplicate)
  - [ ] Low confidence (possible duplicate)
- [ ] User actions for duplicates:
  - [ ] Mark as duplicate and delete
  - [ ] Keep both (not duplicates)
  - [ ] Merge transactions (combine details)
  - [ ] Auto-resolve future similar cases (create rule)
- [ ] Show duplicate indicator on transaction list
- [ ] Add notification when duplicates are detected
- [ ] Settings for duplicate detection sensitivity
- [ ] Automatic duplicate suppression for high-confidence matches
- [ ] Manual duplicate linking/unlinking
- [ ] Duplicate resolution history/audit log

**Files to Update:**
- Create: `lib/services/duplicate_detection_service.dart`
- Create: `lib/screens/transactions/duplicate_resolution_screen.dart`
- `lib/screens/dashboard/transaction_list_screen.dart`
- `lib/services/database_service.dart`
- `lib/models/transaction.dart` (add duplicate-related fields)

---

### Feature #8: Transaction Editing Capabilities
**Status:** 🔄 Partially Implemented  
**Priority:** High  
**Estimated Effort:** 2-3 days

**Description:** Allow users to click on any transaction and edit category, amount, or remove it.

**Tasks:**
- [ ] Create transaction edit screen: `lib/screens/transactions/edit_transaction_screen.dart`
- [ ] Editable fields:
  - [ ] Amount (with validation)
  - [ ] Merchant/Description
  - [ ] Category (dropdown with all categories)
  - [ ] Date and time
  - [ ] Transaction type (Income/Expense)
  - [ ] Notes/Tags
  - [ ] Confirmed/Unconfirmed status
- [ ] Add "Delete Transaction" button with confirmation
- [ ] Add "Split Transaction" option:
  - [ ] Split amount into multiple categories
  - [ ] Keep original transaction for reference
  - [ ] Create linked sub-transactions
- [ ] Make transaction items clickable in list
- [ ] Show edit history (optional: track changes)
- [ ] Add undo option after deletion
- [ ] Validation before saving:
  - [ ] Amount > 0
  - [ ] Category selected
  - [ ] Valid date
- [ ] Update dashboard metrics after edit
- [ ] Sync changes to Google Drive backup (if enabled)

**Files to Update:**
- Create: `lib/screens/transactions/edit_transaction_screen.dart`
- `lib/screens/dashboard/transaction_list_screen.dart` (make items clickable)
- `lib/services/database_service.dart`
- `lib/models/transaction.dart` (add edit history fields)

---

### Feature #9: Enhanced Reports Section
**Status:** 🔄 Partially Implemented  
**Priority:** High  
**Estimated Effort:** 5-7 days

**Description:** Major overhaul of reports section with deep-dive financial analysis.

**Tasks:**
- [ ] Restructure reports screen with multiple tabs/sections
- [ ] Add new report types:
  
  **9.1 Cash Flow Analysis**
  - [ ] Create `lib/screens/reports/cash_flow_report_screen.dart`
  - [ ] Monthly cash flow statement
  - [ ] Income sources breakdown
  - [ ] Expense categories breakdown
  - [ ] Net cash flow trend
  - [ ] Cash flow forecast
  - [ ] Positive/negative cash flow months
  
  **9.2 Net Worth Report**
  - [ ] Create `lib/screens/reports/net_worth_report_screen.dart`
  - [ ] Net worth progression chart
  - [ ] Asset allocation pie chart
  - [ ] Liability breakdown
  - [ ] Net worth growth rate
  - [ ] Milestone tracking (e.g., AED 100K, 500K, 1M)
  
  **9.3 Budget Performance Report**
  - [ ] Create `lib/screens/reports/budget_performance_report_screen.dart`
  - [ ] Budget vs. actual comparison
  - [ ] Over/under budget analysis
  - [ ] Budget adherence score
  - [ ] Category-wise performance
  - [ ] Recommendations for budget adjustments
  
  **9.4 Spending Patterns Report**
  - [ ] Create `lib/screens/reports/spending_patterns_report_screen.dart`
  - [ ] Day of week spending pattern
  - [ ] Time of day spending pattern
  - [ ] Seasonal spending trends
  - [ ] Recurring expense identification
  - [ ] Impulse purchase detection
  
  **9.5 Investment Performance** (if tracking investments)
  - [ ] Create `lib/screens/reports/investment_performance_screen.dart`
  - [ ] Portfolio value over time
  - [ ] Returns by asset class
  - [ ] Dividend/profit tracking
  - [ ] Investment allocation chart
  
  **9.6 Financial Health Score**
  - [ ] Create `lib/screens/reports/financial_health_screen.dart`
  - [ ] Overall financial health score (0-100)
  - [ ] Component scores:
    - [ ] Emergency fund adequacy
    - [ ] Debt-to-income ratio
    - [ ] Savings rate
    - [ ] Budget adherence
    - [ ] Spending control
  - [ ] Recommendations for improvement
  - [ ] Comparison to benchmarks
  
  **9.7 Year-End Summary Report**
  - [ ] Create `lib/screens/reports/year_end_summary_screen.dart`
  - [ ] Total income for year
  - [ ] Total expenses for year
  - [ ] Total savings
  - [ ] Net worth change
  - [ ] Top spending categories
  - [ ] Largest transactions
  - [ ] Financial achievements
  - [ ] Goals for next year

- [ ] Add export options for all reports:
  - [ ] PDF export
  - [ ] CSV export
  - [ ] Excel export (optional)
  - [ ] Share via email/WhatsApp
  
- [ ] Add date range selectors:
  - [ ] This month
  - [ ] Last month
  - [ ] Quarter (Q1, Q2, Q3, Q4)
  - [ ] Year-to-date
  - [ ] Last year
  - [ ] Custom date range
  
- [ ] Add comparison features:
  - [ ] Period over period
  - [ ] Year over year
  - [ ] Benchmark comparisons

**Files to Update:**
- `lib/screens/reports/reports_screen.dart` (restructure with tabs)
- Create multiple new report screens as listed above
- `lib/services/database_service.dart` (add complex queries)
- Create: `lib/services/report_generator_service.dart`
- Create: `lib/services/pdf_export_service.dart`

---

### Feature #10: Legal & Support Pages
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 2-3 days

**Description:** Add Terms & Conditions and Privacy Policy pages, plus enhanced support options.

**Tasks:**
- [ ] Create Terms & Conditions screen: `lib/screens/legal/terms_conditions_screen.dart`
  - [ ] Write comprehensive terms of service
  - [ ] Include:
    - [ ] App usage terms
    - [ ] User responsibilities
    - [ ] Data handling practices
    - [ ] Limitation of liability
    - [ ] Governing law (UAE)
    - [ ] Contact information
  - [ ] Make scrollable with "Accept" option on first use
  - [ ] Version tracking for T&C updates
  - [ ] Add to onboarding flow (user must accept)
  
- [ ] Create Privacy Policy screen: `lib/screens/legal/privacy_policy_screen.dart`
  - [ ] Write detailed privacy policy
  - [ ] Include:
    - [ ] What data is collected (SMS, notifications, user input)
    - [ ] How data is stored (local only, encrypted)
    - [ ] Google Drive backup explanation
    - [ ] No data sharing/selling policy
    - [ ] User rights (access, deletion)
    - [ ] Data retention policy
    - [ ] Security measures
    - [ ] Contact for privacy concerns
  - [ ] GDPR compliance considerations
  - [ ] Make accessible from Settings
  
- [ ] Enhance Contact/Support section in Settings:
  - [ ] Add GitHub repository link
  - [ ] "Report a Bug" button that:
    - [ ] Opens GitHub Issues page
    - [ ] Or opens email with pre-filled template
    - [ ] Includes app version and device info
  - [ ] "Feature Request" option
  - [ ] "Rate on Play Store" link
  - [ ] FAQ section (optional)
  - [ ] Email support: er.sachinsirohi@gmail.com
  
- [ ] Add links to legal pages:
  - [ ] In Settings screen
  - [ ] In onboarding flow
  - [ ] In About section
  
- [ ] Create changelog/release notes screen (optional)

**Files to Update:**
- Create: `lib/screens/legal/terms_conditions_screen.dart`
- Create: `lib/screens/legal/privacy_policy_screen.dart`
- Create: `lib/screens/support/contact_support_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/onboarding/onboarding_wizard_screen.dart`
- Create text assets or markdown files for legal content

---

## 🎨 UI/UX Enhancements (Priority 3)

### Enhancement #1: Dashboard Card Interactivity
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 2 days

**Tasks:**
- [ ] Add onTap handlers to all dashboard cards
- [ ] Add visual feedback (ripple effect, scale animation)
- [ ] Add navigation arrows/chevrons to indicate clickability
- [ ] Implement smooth page transitions
- [ ] Add hero animations for cards when navigating to detail screens
- [ ] Consistent navigation patterns across all cards

---

### Enhancement #2: Onboarding Improvements
**Status:** ❌ To Do  
**Priority:** Low  
**Estimated Effort:** 2 days

**Tasks:**
- [ ] Add animations between onboarding steps
- [ ] Add progress stepper at top of each screen
- [ ] Add "Back" button to navigate to previous step
- [ ] Add tutorial/hints for first-time users
- [ ] Add skip option for optional steps
- [ ] Save partial progress if user exits mid-onboarding

---

### Enhancement #3: Dark Mode Support
**Status:** ❌ To Do  
**Priority:** Low  
**Estimated Effort:** 2-3 days

**Tasks:**
- [ ] Create dark theme color scheme
- [ ] Update `app_constants.dart` with dark mode colors
- [ ] Add theme toggle in Settings
- [ ] Save theme preference in UserSettings
- [ ] Test all screens in dark mode
- [ ] Ensure chart colors work in both themes
- [ ] Handle system theme setting (auto-detect)

---

### Enhancement #4: Localization (Arabic Support)
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 5-7 days

**Tasks:**
- [ ] Add `flutter_localizations` package
- [ ] Create `l10n` directory with translations
- [ ] Translate all UI strings to Arabic
- [ ] Support RTL (Right-to-Left) layout
- [ ] Update Arabic SMS parsing patterns
- [ ] Add language selector in Settings
- [ ] Test all screens in Arabic
- [ ] Ensure charts and numbers display correctly
- [ ] Handle mixed language content

---

## 🔧 Technical Improvements (Priority 4)

### Improvement #1: Error Handling & Logging
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 2-3 days

**Tasks:**
- [ ] Implement centralized error handling service
- [ ] Add logging framework (e.g., logger package)
- [ ] Log important events and errors
- [ ] Add error boundary widgets
- [ ] Show user-friendly error messages
- [ ] Add retry mechanisms for network operations
- [ ] Create crash report system (optional, with user consent)
- [ ] Add debug mode with verbose logging

---

### Improvement #2: Performance Optimization
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 3-4 days

**Tasks:**
- [ ] Optimize database queries (add indexes)
- [ ] Implement lazy loading for transaction lists
- [ ] Optimize chart rendering for large datasets
- [ ] Reduce app startup time
- [ ] Optimize image loading (receipt scans)
- [ ] Profile and optimize memory usage
- [ ] Implement data pagination
- [ ] Cache frequently accessed data
- [ ] Optimize background service battery usage

---

### Improvement #3: Testing
**Status:** ❌ To Do  
**Priority:** High  
**Estimated Effort:** 5-7 days

**Tasks:**
- [ ] Write unit tests for services:
  - [ ] SMSParserService
  - [ ] DatabaseService
  - [ ] OptimizationService
  - [ ] BackupService
  - [ ] DuplicateDetectionService
- [ ] Write widget tests for screens:
  - [ ] Dashboard
  - [ ] Transaction list
  - [ ] Budget screen
  - [ ] Settings
- [ ] Write integration tests:
  - [ ] Onboarding flow
  - [ ] Transaction creation flow
  - [ ] Backup and restore flow
- [ ] Test with real UAE SMS data (at least 100 samples)
- [ ] Test on multiple devices (different Android versions)
- [ ] Test with different screen sizes
- [ ] Performance testing with large datasets (10k+ transactions)
- [ ] Test offline functionality
- [ ] Test backup encryption/decryption

---

### Improvement #4: Data Migration & Versioning
**Status:** ❌ To Do  
**Priority:** Medium  
**Estimated Effort:** 2 days

**Tasks:**
- [ ] Implement database version tracking
- [ ] Create migration scripts for schema changes
- [ ] Test upgrade path from old versions
- [ ] Add data validation after migration
- [ ] Backup data before migrations
- [ ] Handle migration failures gracefully

---

## 📱 App Store & Distribution (Priority 5)

### Distribution #1: Google Play Store Preparation
**Status:** ❌ To Do  
**Priority:** High (for launch)  
**Estimated Effort:** 3-5 days

**Tasks:**
- [ ] Design app icon (UAE-themed)
- [ ] Create feature graphic
- [ ] Take screenshots for Play Store (6-8 screenshots)
- [ ] Write app description (short & long)
- [ ] Create promotional video (optional)
- [ ] Set up Google Play Console account
- [ ] Create signed release APK/AAB
- [ ] Complete Play Store listing:
  - [ ] App title
  - [ ] Short description
  - [ ] Full description
  - [ ] Screenshots
  - [ ] App icon
  - [ ] Feature graphic
  - [ ] Category (Finance)
  - [ ] Content rating
  - [ ] Target audience
  - [ ] Privacy policy URL
- [ ] Set up app signing
- [ ] Configure in-app updates (optional)
- [ ] Set up closed/open testing tracks
- [ ] Beta test with 20-50 UAE users
- [ ] Address beta tester feedback
- [ ] Submit for review

---

### Distribution #2: Marketing Materials
**Status:** ❌ To Do  
**Priority:** Low  
**Estimated Effort:** 2-3 days

**Tasks:**
- [ ] Create landing page/website
- [ ] Write user guide/help documentation
- [ ] Create tutorial videos
- [ ] Design social media graphics
- [ ] Write blog post announcing launch
- [ ] Prepare press release
- [ ] Create demo account/walkthrough

---

## 🚀 Future Enhancements (Phase 2 - Long Term)

### Future #1: Advanced Features
- [ ] Multi-user/family budget sharing
- [ ] Bill payment reminders
- [ ] Subscription management and cancellation alerts
- [ ] Financial goals with milestones
- [ ] Debt payoff calculator
- [ ] Retirement planning calculator
- [ ] Zakat calculator (Islamic finance)
- [ ] Expense forecasting using ML
- [ ] Smart budget recommendations
- [ ] Voice commands for adding transactions
- [ ] Widget for home screen
- [ ] Wear OS support

### Future #2: Integration Features
- [ ] Direct bank account integration (Open Banking API)
- [ ] Stock market data integration for investments
- [ ] Cryptocurrency price tracking
- [ ] Currency exchange rate updates
- [ ] Bill payment integration
- [ ] Export to accounting software
- [ ] Calendar integration for bill reminders

### Future #3: Social Features
- [ ] Anonymous spending benchmarks (opt-in)
- [ ] Financial challenges/competitions
- [ ] Community tips and insights
- [ ] Shared budgets with spouse/family
- [ ] Financial advisor connection (optional)

### Future #4: iOS Version
- [ ] Port to iOS
- [ ] iOS-specific features (Face ID, iMessage, etc.)
- [ ] App Store submission
- [ ] Cross-platform data sync

---

## 📝 Development Notes

### Setup Requirements
- Flutter SDK 3.x
- Android Studio / VS Code
- Android SDK (API 24+)
- Google Cloud Console account (for Google Sign-In & Drive API)
- Firebase project (optional, for auth)

### Key Dependencies
- `hive` & `hive_flutter` - Local encrypted database
- `google_sign_in` - Google authentication
- `googleapis` - Google Drive API
- `telephony` - SMS reading
- `flutter_local_notifications` - Notification handling
- `workmanager` - Background tasks
- `fl_chart` - Charts and graphs
- `local_auth` - Biometric authentication
- `encrypt` - Data encryption
- `google_mlkit_text_recognition` - OCR for receipt scanning
- `pdf` & `printing` - Report generation

### Development Workflow
1. Create feature branch from main
2. Implement feature with tests
3. Test on physical Android device (required for SMS, notifications, biometrics)
4. Update documentation
5. Create pull request
6. Code review
7. Merge to main
8. Tag release version

### Testing Strategy
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows
- Manual testing on real devices
- Beta testing with UAE users before each release

---

## 📊 Progress Tracking

**Overall Completion:** ~40% (MVP features implemented)

**Completed:**
- ✅ Basic project setup
- ✅ Hive database integration
- ✅ SMS parsing service (basic)
- ✅ Onboarding flow (partial)
- ✅ Dashboard with home/reports/settings tabs
- ✅ Budget management
- ✅ Basic charts and reports
- ✅ Google Drive service (partial)
- ✅ Biometric screen (needs fixing)

**In Progress:**
- 🔄 Google Sign-In (needs fixing)
- 🔄 Google Drive backup/restore (partial)
- 🔄 Receipt scanning (needs review screen)
- 🔄 Setup completion persistence (needs fixing)

**Next Up (Priority Order):**
1. Fix critical issues (#1-#4)
2. Complete Google Drive backup/restore
3. Add clickable dashboard cards with detail views
4. Implement transaction editing
5. Add duplicate detection
6. Enhance reports section
7. Add legal pages and support links

---

## 🤝 Contributing

This is a personal project, but suggestions and bug reports are welcome!

1. Check existing issues/features in this TODO
2. Open a GitHub issue for discussion
3. Fork the repository
4. Create your feature branch
5. Make changes with tests
6. Submit a pull request

---

## 📞 Contact & Support

- **Developer:** Sachin Sirohi
- **Email:** er.sachinsirohi@gmail.com
- **GitHub:** https://github.com/SachinSirohi/uae-wealth-builder
- **Issues:** https://github.com/SachinSirohi/uae-wealth-builder/issues

---

*Last Updated: December 3, 2024*  
*This TODO list will be regularly updated as features are completed and new requirements emerge.*
