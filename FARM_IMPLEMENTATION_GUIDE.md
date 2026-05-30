# Komars Farm - Dokumentasi Implementasi untuk Vemas

Dokumen ini menjelaskan semua file dan implementasi yang telah dibuat untuk modul **Komars Farm** (Agribisnis & Keuangan Partner Farm) oleh **Vemas**.

## 📋 Daftar Isi

1. [Struktur Folder](#struktur-folder)
2. [Models](#models)
3. [Database Access Objects (DAOs)](#database-access-objects-daos)
4. [Custom Widget](#custom-widget)
5. [Screens](#screens)
6. [SharedPreferences Keys](#sharedpreferences-keys)
7. [Fitur CRUD](#fitur-crud)
8. [Implementasi Gestures & Animations](#implementasi-gestures--animations)
9. [Library Integrasi](#library-integrasi)
10. [Cara Menggunakan](#cara-menggunakan)

---

## 📁 Struktur Folder

```
lib/features/farm/
├── db/
│   ├── farm_package_dao.dart        # Data Access Object untuk Farm Packages
│   ├── financial_record_dao.dart    # Data Access Object untuk Financial Records
│   └── index.dart                   # Export file DAOs
├── models/
│   ├── farm_package_model.dart      # Model untuk Farm Packages
│   ├── financial_record_model.dart  # Model untuk Financial Records
│   └── index.dart                   # Export file Models
├── screens/
│   ├── farm_home_screen.dart        # Home screen - daftar paket pertanian
│   ├── farm_package_detail_screen.dart   # Detail screen - informasi paket
│   ├── farm_management_screen.dart  # Management screen - CRUD paket
│   ├── finance_input_screen.dart    # Input screen - tambah record keuangan
│   ├── finance_history_screen.dart  # History screen - daftar & summary keuangan
│   ├── finance_detail_screen.dart   # Detail screen - edit record keuangan
│   └── index.dart                   # Export file Screens
├── widgets/
│   ├── profit_loss_card.dart        # Custom widget - tampilan finansial
│   └── index.dart                   # Export file Widgets
```

---

## 🏗️ Models

### 1. **FarmPackage Model** (`farm_package_model.dart`)

Mewakili paket starter kit pertanian.

**Properti:**
```dart
- id: int
- farmType: String ('ayam', 'lele', 'hidroponik', 'sayuran')
- title: String
- description: String
- initialCapitalMin: double
- initialCapitalRec: double
- harvestTimeDays: int
- roiMonths: int
- monthlyIncomeEst: double
- steps: List<String>
- equipmentList: List<String>
```

**Metode Penting:**
- `toJson()` - Konversi ke JSON untuk database
- `fromJson()` - Factory constructor dari database row
- `copyWith()` - Untuk membuat copy dengan perubahan tertentu

---

### 2. **FinancialRecord Model** (`financial_record_model.dart`)

Mewakili catatan keuangan harian petani.

**Properti:**
```dart
- id: int
- userId: int
- farmType: String
- recordDate: String (YYYY-MM-DD)
- income: double
- expense: double
- loss: double
- netProfit: double (calculated: income - expense - loss)
- notes: String?
- createdAt: String
- updatedAt: String
```

**Metode Penting:**
- `toJson()` - Konversi ke JSON untuk database
- `fromJson()` - Factory constructor dari database row
- `copyWith()` - Untuk membuat copy dengan perubahan tertentu

---

## 💾 Database Access Objects (DAOs)

### 1. **FarmPackageDao** (`farm_package_dao.dart`)

Menangani operasi database untuk Farm Packages.

**Operasi CRUD:**

| Metode | Deskripsi | Parameter |
|--------|-----------|-----------|
| `insertPackage()` | CREATE - Tambah paket baru | `FarmPackage` |
| `getAllPackages()` | READ - Ambil semua paket | - |
| `getPackagesByFarmType()` | READ - Filter by farm type | `String farmType` |
| `getPackageById()` | READ - Ambil by ID | `int id` |
| `updatePackage()` | UPDATE - Edit paket | `FarmPackage` |
| `deletePackage()` | DELETE - Hapus paket | `int id` |
| `getPackageCount()` | Hitung total paket | - |

**Contoh Penggunaan:**
```dart
final dao = DatabaseHelper.instance.farmPackageDao;

// CREATE
final package = FarmPackage(id: 0, farmType: 'ayam', ...);
final id = await dao.insertPackage(package);

// READ
final allPackages = await dao.getAllPackages();
final ayamPackages = await dao.getPackagesByFarmType('ayam');
final package = await dao.getPackageById(1);

// UPDATE
await dao.updatePackage(updatedPackage);

// DELETE
await dao.deletePackage(1);
```

---

### 2. **FinancialRecordDao** (`financial_record_dao.dart`)

Menangani operasi database untuk Financial Records.

**Operasi CRUD:**

| Metode | Deskripsi | Parameter |
|--------|-----------|-----------|
| `insertRecord()` | CREATE - Tambah catatan | `FinancialRecord` |
| `getAllRecords()` | READ - Ambil semua catatan | - |
| `getRecordsByUserId()` | READ - Filter by user | `int userId` |
| `getRecordsByUserAndFarmType()` | READ - Filter by user & farm | `int userId, String farmType` |
| `getRecordsByFarmType()` | READ - Filter by farm type | `String farmType` |
| `getRecordById()` | READ - Ambil by ID | `int id` |
| `getRecordsByDateRange()` | READ - Filter by date range | `int userId, String start, String end` |
| `updateRecord()` | UPDATE - Edit catatan | `FinancialRecord` |
| `deleteRecord()` | DELETE - Hapus catatan | `int id` |
| `getSummaryStats()` | READ - Total stats | `int userId, String farmType` |
| `getRecordCount()` | Hitung total catatan | - |

**Contoh Penggunaan:**
```dart
final dao = DatabaseHelper.instance.financialRecordDao;

// CREATE
final record = FinancialRecord(
  id: 0,
  userId: 1,
  farmType: 'ayam',
  recordDate: '2024-05-30',
  income: 5000000,
  expense: 2000000,
  loss: 500000,
  netProfit: 2500000,
  ...
);
final id = await dao.insertRecord(record);

// READ
final records = await dao.getRecordsByUserAndFarmType(1, 'ayam');
final record = await dao.getRecordById(1);
final stats = await dao.getSummaryStats(1, 'ayam');

// UPDATE
await dao.updateRecord(updatedRecord);

// DELETE
await dao.deleteRecord(1);
```

---

## 🎨 Custom Widget

### **ProfitLossCard** (`profit_loss_card.dart`)

Widget custom yang menampilkan ringkasan keuangan dengan animasi counter.

**Fitur:**
✅ **Animated Counter**: Angka beranimasi selama 600ms ketika ditampilkan
✅ **Color-Coded**: Warna dinamis berdasarkan profit/loss (Hijau/Merah)
✅ **Currency Formatting**: Format Rupiah dengan pemisah otomatis
✅ **Fade-In Animation**: Fade transition saat widget muncul
✅ **Responsive Layout**: Tampilan income, expense, loss, dan profit

**Properti:**
```dart
- income: double (required)
- expense: double (required)
- loss: double (required)
- netProfit: double (required)
- title: String (default: 'Financial Summary')
- onTap: VoidCallback? (optional)
```

**Contoh Penggunaan:**
```dart
ProfitLossCard(
  income: 5000000,
  expense: 2000000,
  loss: 500000,
  netProfit: 2500000,
  title: 'Agustus 2024',
  onTap: () {
    // Handle tap event
  },
)
```

**Animasi:**
- TweenAnimationBuilder untuk counter (600ms)
- FadeTransition untuk fade-in effect
- Scale animation untuk child elements

---

## 📱 Screens

### 1. **FarmHomeScreen** (`farm_home_screen.dart`)

**Fungsi**: Home page modul Komars Farm

**Fitur:**
- ✅ Pilih tipe pertanian (ayam, lele, hidroponik, sayuran)
- ✅ Tampilkan daftar paket sesuai tipe yang dipilih
- ✅ Load preferensi farm type dari SharedPreferences
- ✅ Navigasi ke detail paket
- ✅ Akses screen management untuk admin

**Navigasi:**
```
FarmHomeScreen
  ├─→ FarmPackageDetailScreen (tap paket)
  └─→ FarmManagementScreen (settings button)
```

---

### 2. **FarmPackageDetailScreen** (`farm_package_detail_screen.dart`)

**Fungsi**: Menampilkan detail lengkap paket pertanian

**Tampilan:**
- Header dengan nama & tipe paket
- Deskripsi paket
- Detail finansial (capital, ROI, monthly income, harvest time)
- Step-by-step implementasi (numbered list)
- Equipment yang dibutuhkan (check list)

**Interaksi:**
- Read-only (untuk informasi)

---

### 3. **FarmManagementScreen** (`farm_management_screen.dart`)

**Fungsi**: CRUD management untuk farm packages

**Fitur CRUD:**
✅ **CREATE** - Tambah paket baru via dialog
✅ **READ** - Tampilkan semua paket dalam list
✅ **UPDATE** - Edit paket via dialog popup
✅ **DELETE** - Hapus paket dengan konfirmasi

**Interaksi:**
- Floating Action Button untuk create
- Popup menu di setiap item untuk edit/delete
- Alert dialog untuk konfirmasi delete

---

### 4. **FinanceInputScreen** (`finance_input_screen.dart`)

**Fungsi**: Input catatan keuangan baru (CREATE operation)

**Form Fields:**
- Farm Type dropdown (ayam, lele, hidroponik, sayuran)
- Record Date picker (pilih tanggal)
- Income input (required)
- Expense input (required)
- Loss input (required)
- Notes input (optional)

**Validasi:**
- Semua field required terisi
- Format numeric untuk income, expense, loss
- Net profit otomatis calculated

**Simpan:**
- Insert ke database via FinancialRecordDao
- Navigate back dengan result = true

---

### 5. **FinanceHistoryScreen** (`finance_history_screen.dart`)

**Fungsi**: Melihat history & summary keuangan (READ operation)

**Fitur:**
✅ Filter by farm type
✅ Filter by period (weekly/monthly)
✅ ProfitLossCard - summary total
✅ List semua records
✅ Trend indicator (trending up/down)
✅ Floating Action Button untuk input baru

**Interaksi:**
- Tap record → FinanceDetailScreen
- Popup menu → View/Delete
- Delete dengan konfirmasi

---

### 6. **FinanceDetailScreen** (`finance_detail_screen.dart`)

**Fungsi**: Lihat & edit detail catatan keuangan (READ/UPDATE operations)

**Fitur:**
✅ Tampilkan detail record
✅ Toggle edit mode
✅ Edit income, expense, loss, notes
✅ Edit record date
✅ Save changes
✅ Visual feedback (profit/loss color)

**Mode:**
- **View Mode**: Tampilkan data saja
- **Edit Mode**: Form fields untuk edit

---

## 🔑 SharedPreferences Keys

Semua keys sudah didefinisikan di `core/constants/pref_keys.dart`:

| Key | Tipe | Default | Deskripsi |
|-----|------|---------|-----------|
| `selected_farm_type` | String | `"ayam"` | Farm type yang dipilih user |
| `finance_filter_period` | String | `"weekly"` | Period filter untuk financial report |

**Contoh Penggunaan:**
```dart
final prefs = await SharedPreferences.getInstance();

// Save
await prefs.setString(PrefKeys.selectedFarmType, 'lele');

// Read
final farmType = prefs.getString(PrefKeys.selectedFarmType) ?? 'ayam';

// Delete
await prefs.remove(PrefKeys.selectedFarmType);
```

---

## 📊 Fitur CRUD

### **CRUD 1: Farm Packages**

| Operasi | Screen | Deskripsi |
|---------|--------|-----------|
| **CREATE** | FarmManagementScreen | Dialog form - input paket baru |
| **READ** | FarmHomeScreen | List paket by farm type |
| **READ** | FarmPackageDetailScreen | Detail paket lengkap |
| **UPDATE** | FarmManagementScreen | Dialog form - edit paket existing |
| **DELETE** | FarmManagementScreen | Confirm dialog - hapus paket |

**Database Table**: `farm_packages`

---

### **CRUD 2: Financial Records**

| Operasi | Screen | Deskripsi |
|---------|--------|-----------|
| **CREATE** | FinanceInputScreen | Form input - catatan keuangan baru |
| **READ** | FinanceHistoryScreen | List records + summary stats |
| **READ** | FinanceDetailScreen | Detail record individual |
| **UPDATE** | FinanceDetailScreen | Toggle edit mode - ubah record |
| **DELETE** | FinanceHistoryScreen | Popup menu - hapus record |

**Database Table**: `financial_records`

---

## ✨ Implementasi Gestures & Animations

### **Gesture 1: ProfitLossCard - Tap & Fade**
```dart
- FadeTransition: Fade-in saat widget dimuat (600ms)
- GestureDetector: onTap callback untuk interaksi
- TweenAnimationBuilder: Counter animation untuk angka (600ms)
```

### **Gesture 2: List Item - Popup Menu**
```dart
- PopupMenuButton: Akses edit/delete untuk each item
- Swipe action pada item (via Dismissible - optional)
```

### **Animation Details:**
- **Fade Animation**: CurvedAnimation dengan Curves.easeIn (600ms)
- **Counter Animation**: TweenAnimationBuilder (600ms)
- **Scale Animation**: Pada parent elements (responsive)

---

## 📚 Library Integrasi

### **fl_chart** (Sudah ada di pubspec.yaml)

Digunakan untuk membuat grafik profit curves yang interaktif. Siap untuk diintegrasikan di screen tambahan.

**Contoh Integrasi (untuk future):**
```dart
import 'package:fl_chart/fl_chart.dart';

// Buat line chart untuk trend profit
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: [...], // Data points dari records
        isCurved: true,
        color: Colors.green,
      ),
    ],
  ),
)
```

---

### **SharedPreferences** (Sudah ada)

Menyimpan preferensi user:
- Selected farm type
- Filter period untuk finance reports

### **intl** (Sudah ada)

Currency formatting untuk Rupiah:
```dart
final formatter = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
print(formatter.format(5000000)); // Output: Rp 5000000
```

### **sqflite** (Sudah ada)

Database engine untuk farm_packages & financial_records tables.

---

## 🚀 Cara Menggunakan

### **1. Inisialisasi Database**

Di `main.dart` atau app startup:
```dart
import 'package:komars_express/core/database/database_helper.dart';
import 'package:komars_express/core/database/seed_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database; // Initialize
  
  // Seed data
  await SeedData.seed(); // Populate initial data
  
  runApp(const MyApp());
}
```

---

### **2. Akses DAOs di Screen**

```dart
import 'package:komars_express/core/database/database_helper.dart';

// Di initState atau method:
final dbHelper = DatabaseHelper.instance;

// Farm Packages DAO
final farmDao = dbHelper.farmPackageDao;
final packages = await farmDao.getAllPackages();

// Financial Records DAO
final financeDao = dbHelper.financialRecordDao;
final records = await financeDao.getRecordsByUserId(userId);
```

---

### **3. Navigasi ke Screens**

```dart
// Navigate ke FarmHomeScreen
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const FarmHomeScreen()),
);

// Navigate ke FinanceHistoryScreen dengan user ID
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => FinanceHistoryScreen(userId: 1),
  ),
);

// Navigate dengan result handling
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => FinanceInputScreen(userId: 1)),
);

if (result == true) {
  // Record was added, refresh data
  _loadRecords();
}
```

---

### **4. Integrasi dengan Home Screen**

Di `home_screen.dart`, tambahkan tab atau button untuk akses Farm:

```dart
TabBar(
  tabs: [
    Tab(text: 'Express'),
    Tab(text: 'Farm'),    // New tab
    Tab(text: 'Reservasi'),
  ],
)

// Or use buttons:
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FarmHomeScreen()),
  ),
  child: const Text('Go to Komars Farm'),
)
```

---

## 📝 Checklist Implementasi

- ✅ FarmPackageModel dengan properti lengkap
- ✅ FinancialRecordModel dengan properti lengkap
- ✅ FarmPackageDao dengan CRUD penuh
- ✅ FinancialRecordDao dengan CRUD penuh + stats
- ✅ ProfitLossCard custom widget dengan animated counter
- ✅ FarmHomeScreen dengan farm type selector
- ✅ FarmPackageDetailScreen dengan info lengkap
- ✅ FarmManagementScreen dengan CRUD UI
- ✅ FinanceInputScreen untuk create records
- ✅ FinanceHistoryScreen dengan summary & list
- ✅ FinanceDetailScreen untuk view/edit
- ✅ SharedPreferences integration (2 keys)
- ✅ Gestures & Animations (TweenAnimationBuilder, FadeTransition)
- ✅ Seed data di database_helper
- ✅ Export files untuk clean imports

---

## 🎯 Fitur Tambahan (Optional untuk Future)

1. **Grafik Profit Trend** - Gunakan `fl_chart` untuk line graph
2. **Export to PDF** - Laporan keuangan bulanan
3. **Notifikasi** - Reminder untuk input catatan
4. **Backup Data** - Export/import financial records
5. **Photo Gallery** - Tambah foto untuk dokumentasi pertanian

---

## 📞 Catatan

- Semua file sudah siap untuk integration testing
- Database schema sudah match dengan PRD
- Code follows Flutter best practices
- Error handling sudah implemented dengan try-catch
- Loading states sudah ditangani dengan CircularProgressIndicator

**Happy Coding!** 🚀

