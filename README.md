# FinEz (সহজ আর্থিক ব্যবস্থাপনা)
**Lightweight Financial Management Application for Somiti (সমিতি)**

FinEz is a secure, responsive, lightweight Android application built with Flutter and Supabase PostgreSQL. It is specifically designed to manage financial contributions, monthly installments, payment histories, inter-account bank allocations, and automated financial statements for a Somiti (cooperative organization).

---

## 1. Project Overview

FinEz enables Somiti administrators to eliminate manual ledger paperwork while empowering members with real-time transparency into their financial records. The application strictly enforces database integrity, immutable audit logging, and member-to-member privacy isolation.

* **Primary Target:** Android APK distributable via Google Drive.
* **Architecture:** Offline-aware lightweight Flutter mobile client with hosted Supabase PostgreSQL backend.
* **Languages:** Bilingual support for **বাংলা (Bangla)** and **English**.
* **Visual Theme:** Spotify-inspired dark interface (`#121212`, `#181818`, `#242424`, `#1ED760`).

---

## 2. Key Features

### Role-Based Access Control
* **ADMIN:** Complete access to member records, installment generation, payment processing, ledger management, monthly/yearly reports, and Excel imports.
* **MEMBER:** Access restricted strictly to the user's personal financial record, payment history, and a permitted name-only member directory.

### Financial Operations
* **Idempotent Installment Generation:** Generates monthly installments for all active members with duplicate prevention on `(member_id, period_month)`.
* **Atomic Payment Recording:** Database RPC transactions record money received, automatically synchronize installment status (`due` -> `partial` -> `paid`), and update the bank ledger simultaneously.
* **Immutable Audit Trail & Controlled Corrections:** Payments cannot be silently altered or deleted. Corrections require mandatory documented reasons and preserve full historical audit logs.
* **Authoritative Bank Ledger & Reconciliation:** Balances are computed directly from opening balances and ledger movements (`inflow`, `outflow`, `transfers`). Funds can be transferred between accounts without inflating income.
* **Excel (.xlsx) Import:** Validates spreadsheets with duplicate phone/ID detection, previewing new, updated, unchanged, and rejected rows before applying changes in database transactions.

---

## 3. Technology Stack

* **Mobile Client:** Flutter 3.27.1 / Dart 3.6.0 (Null Safety).
* **Backend:** Supabase PostgreSQL with Row Level Security (RLS) & PL/pgSQL RPCs.
* **Authentication:** Supabase Auth (Email & Password).
* **Localization:** Flutter ARB localization (`app_en.arb`, `app_bn.arb`).
* **Charts:** `fl_chart` (Lightweight collection rate and status breakdown).
* **Spreadsheet Processing:** `excel` (pure Dart XLSX parsing).
* **State Management:** Flutter `ChangeNotifier` and `ListenableBuilder` (Zero overhead, lightweight).

---

## 4. Prerequisites

* **Operating System:** macOS (Apple Silicon M1/M2/M3 or Intel), Linux, or Windows.
* **Flutter SDK:** Version 3.27.x or later.
* **Java Development Kit (JDK):** JDK 17 or JDK 21.
* **Android SDK:** Command-line tools and Build-Tools (version 33.0.1 or higher).
* **Rosetta 2 (macOS Apple Silicon):** If running on Apple Silicon, ensure Rosetta 2 is available (`softwareupdate --install-rosetta --agree-to-license`).

---

## 5. Environment Configuration

Copy `.env.example` to configure your environment:

```bash
cp .env.example .env
```

### Critical Security Rule
* **NEVER** include the Supabase `service_role` or database admin secret keys in client-side code, Git commits, or APK bundles.
* Mobile clients only require the **Supabase URL** and the **Public Publishable Key** (`sb_publishable_...` or `anon` key).
* If an administrative secret key was ever exposed outside the secret management boundary, **revoke and rotate it immediately** in the Supabase Dashboard (`Settings -> API -> Secret Key`).

---

## 6. Supabase Project Configuration & Migrations

### Apply Migrations
The database schema, constraints, RLS policies, and RPC functions are located in `supabase/migrations/20261021000001_initial_schema.sql`.

To apply to your Supabase project:
1. Open the [Supabase Dashboard](https://supabase.com/dashboard).
2. Navigate to the **SQL Editor**.
3. Copy and run the contents of `supabase/migrations/20261021000001_initial_schema.sql`.

### Apply Synthetic Test Data (Optional for Development)
To load non-sensitive synthetic test records for members, bank accounts, and installments:
```sql
-- Execute supabase/seed.sql in the Supabase SQL Editor
```

### Initial Administrator Setup
To assign the first administrator securely:
```sql
-- Replace with the email address of the registered user
SELECT public.setup_initial_admin('admin@somiti.org');
```

---

## 7. Row Level Security (RLS) Architecture

Every table enforces PostgreSQL Row Level Security:

| Table | MEMBER Role Access | ADMIN Role Access |
|---|---|---|
| `profiles` | Read own profile (`id = auth.uid()`) | Full management (`ALL`) |
| `members` | Read own record (`id = current_member_id()`) | Full management (`ALL`) |
| `public_members_view` | Read active member names & codes | Read active member names & codes |
| `installments` | Read own installments only | Full management (`ALL`) |
| `payments` | Read own payments only | Full management (`ALL`) |
| `bank_accounts` | **DENIED** (no read or write) | Full management (`ALL`) |
| `financial_transactions` | **DENIED** (no read or write) | Full management (`ALL`) |
| `audit_logs` | **DENIED** (no read or write) | Read-only inspection (`SELECT`) |
| `import_batches` | **DENIED** | Full management (`ALL`) |

---

## 8. Excel Import Format

Administrators can import members using Microsoft Excel (`.xlsx`). An official template is located at `assets/templates/member_import_template.xlsx`.

### Required Columns (Row 1):
| Column | Name | Example | Required | Notes |
|---|---|---|---|---|
| A | Member ID | `FM-0001` | Yes | Unique Somiti identifier |
| B | Full Name | `Md. Abdul Karim` | Yes | Member's full name |
| C | Address | `Uttara, Dhaka` | No | Residential address |
| D | Mobile | `01711000000` | Yes | 11-digit Bangladeshi number |
| E | Monthly Installment | `2000` | Yes | Standard monthly commitment |

The import preview flags:
* Missing required fields.
* Duplicate IDs within spreadsheet or database.
* Repeated phone numbers across members.
* Field changes for existing members (`UPDATE` vs `CREATE` vs `NO CHANGE`).

---

## 9. Testing & Quality Assurance

### Run Unit and Widget Tests
```bash
flutter test
```
The test suite covers:
* Installment outstanding balance calculations (clamping to 0).
* Member serialization and Bangladeshi phone number normalization.
* Role-based authorization flags (`isAdmin`, `isMember`).
* Bank transaction classification (`inflow` vs `outflow`).
* Status badge theme rendering and metric cards.

### Run Database Integrity & Security SQL Tests
Execute `supabase/tests/security_and_integrity_test.sql` in the Supabase SQL Editor to verify:
* Duplicate `member_code` rejection.
* Negative financial amount rejection.
* Duplicate `(member_id, period_month)` constraint enforcement.
* Payment status synchronization trigger (`due` -> `partial` -> `paid`).

---

## 10. Building the Release Android APK

### Architecture-Specific APKs (Ultra-Lightweight, Recommended)
To build compact APKs optimized for specific device architectures:
```bash
flutter build apk --release --split-per-abi
```
**Output Artifacts & File Sizes:**
* `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~**6.1 MB**) — *Recommended for modern 64-bit Android devices.*
* `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~**5.3 MB**) — *For older 32-bit Android devices.*
* `build/app/outputs/flutter-apk/app-x86_64-release.apk` (~**6.2 MB**) — *For emulators and Intel-based Android hardware.*

### Universal APK (All-in-One)
```bash
flutter build apk --release
```
* `build/app/outputs/flutter-apk/app-release.apk` (~**24.6 MB**) — *Works on all Android devices.*

---

## 11. Google Drive Distribution Guide

1. **Upload Target:**
   * Upload `app-arm64-v8a-release.apk` (and `app-release.apk` as a fallback) to a dedicated Google Drive folder (e.g. `FinEz Releases`).
2. **Access Permissions:**
   * Set file sharing to *"Anyone with the link can view/download"*.
3. **Distribution Link:**
   * Share the direct download link with Somiti members via WhatsApp, SMS, or email.
4. **Member Installation Steps:**
   * Download the APK on the Android device.
   * If prompted, enable *"Install unknown apps"* for the browser or Drive app in Android Settings.
   * Tap Install and launch FinEz.
5. **Security Warnings:**
   * **NEVER** upload signing keystores, `.env` files, or database backups to public Google Drive folders.

---

## 12. Backup, Recovery & Maintenance

* **Database Backups:** Supabase projects include automated daily backups. For manual backups, download a SQL dump via the Supabase Dashboard (`Database -> Backups`).
* **Audit Trail:** In case of financial disputes, query `public.audit_logs` to review the exact administrator, timestamp, and previous values for any transaction.
* **Key Rotation:** If credentials are ever compromised, rotate the JWT secret in Supabase Dashboard and issue a new APK build with the rotated publishable key.

---

## 13. Free-Tier Operational Assumptions

* **Supabase Free Plan:** Includes 500 MB database storage, 50,000 monthly active users, and 5 GB bandwidth. For a Somiti with 50–500 members, this free tier supports multiple years of operation at zero monthly infrastructure cost.
* **SMS OTP:** Third-party SMS gateways (Twilio, etc.) charge per SMS. To maintain zero-cost operation, FinEz uses email-based authentication with local phone numbers stored for member records.

---

## License

Private and confidential for Somiti Financial Management.
