import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class SeedData {
  SeedData._();

  static Future<void> seed() async {
    final db = await DatabaseHelper.instance.database;

    // ── Seed admin account ────────────────────────────────────────────────────
    final adminCheck = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: ['admin@gmail.com'],
    );
    if (adminCheck.isEmpty) {
      await db.insert('users', {
        'name': 'Administrator',
        'email': 'admin@gmail.com',
        'password': 'admin123',
        'role': 'admin',
      });
    }

    // Check if menu_items already seeded
    final menuCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM menu_items'),
    );
    if ((menuCount ?? 0) == 0) {
      await _seedMenuItems(db);
    }

    final tableCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM tables'),
    );
    if ((tableCount ?? 0) == 0) {
      await _seedTables(db);
    }

    final farmCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM farm_packages'),
    );
    if ((farmCount ?? 0) == 0) {
      await _seedFarmPackages(db);
    }
  }

  static Future<void> _seedMenuItems(db) async {
    final menus = [
      {
        'name': 'Ayam Bakar Komars',
        'description':
            'Ayam kampung pilihan dari mitra tani Komars, dibakar dengan bumbu rempah khas Nusantara.',
        'price': 45000.0,
        'category': 'food',
        'image_path': '',
        'farm_source': 'Caringin Organic Coop',
        'is_available': 1,
      },
      {
        'name': 'Nasi Putih',
        'description': 'Nasi putih pulen dari beras organik pilihan.',
        'price': 8000.0,
        'category': 'food',
        'image_path': '',
        'farm_source': 'Sawah Organik Lembang',
        'is_available': 1,
      },
      {
        'name': 'Gado-Gado Segar',
        'description':
            'Sayuran segar dari kebun hidroponik Komars Farm, disajikan dengan saus kacang spesial.',
        'price': 32000.0,
        'category': 'food',
        'image_path': '',
        'farm_source': 'Komars Hydroponics Center',
        'is_available': 1,
      },
      {
        'name': 'Sate Lele Komars',
        'description':
            'Lele segar dari kolam budidaya mitra Komars, dibakar sempurna dengan bumbu kecap.',
        'price': 38000.0,
        'category': 'food',
        'image_path': '',
        'farm_source': 'Budidaya Lele Mitra Komars',
        'is_available': 1,
      },
      {
        'name': 'Tumis Kangkung Organik',
        'description': 'Kangkung organik segar tumis bumbu terasi pilihan.',
        'price': 22000.0,
        'category': 'food',
        'image_path': '',
        'farm_source': 'Komars Hydroponics Center',
        'is_available': 1,
      },
      {
        'name': 'Sup Jagung Manis',
        'description': 'Sup hangat dari jagung manis segar kebun mitra tani.',
        'price': 28000.0,
        'category': 'food',
        'image_path': '',
        'farm_source': 'Kebun Jagung Ciwidey',
        'is_available': 1,
      },
      {
        'name': 'Es Teh Manis',
        'description': 'Teh manis segar, disajikan dingin.',
        'price': 8000.0,
        'category': 'drink',
        'image_path': '',
        'farm_source': '',
        'is_available': 1,
      },
      {
        'name': 'Jus Alpukat',
        'description': 'Alpukat segar dari kebun mitra, diblender lembut.',
        'price': 22000.0,
        'category': 'drink',
        'image_path': '',
        'farm_source': 'Kebun Alpukat Pangalengan',
        'is_available': 1,
      },
      {
        'name': 'Es Jeruk Peras',
        'description': 'Jeruk segar diperas langsung, tanpa pemanis buatan.',
        'price': 15000.0,
        'category': 'drink',
        'image_path': '',
        'farm_source': 'Kebun Jeruk Garut',
        'is_available': 1,
      },
      {
        'name': 'Kopi Arabika Lokal',
        'description':
            'Kopi arabika single origin dari petani lokal Jawa Barat.',
        'price': 28000.0,
        'category': 'beverage',
        'image_path': '',
        'farm_source': 'Koperasi Kopi Gunung Manglayang',
        'is_available': 1,
      },
      {
        'name': 'Susu Murni Segar',
        'description': 'Susu murni langsung dari peternak sapi mitra Komars.',
        'price': 18000.0,
        'category': 'beverage',
        'image_path': '',
        'farm_source': 'Peternakan Sapi Komars',
        'is_available': 1,
      },
      {
        'name': 'Teh Herbal Rempah',
        'description':
            'Paduan jahe, sereh, dan kayu manis dari kebun herbal mitra.',
        'price': 20000.0,
        'category': 'beverage',
        'image_path': '',
        'farm_source': 'Kebun Herbal Cianjur',
        'is_available': 1,
      },
    ];

    for (final menu in menus) {
      await db.insert('menu_items', menu);
    }
  }

  static Future<void> _seedTables(db) async {
    final tables = [
      {
        'table_number': 'A1',
        'capacity': 2,
        'location': 'Indoor',
        'is_active': 1,
      },
      {
        'table_number': 'A2',
        'capacity': 2,
        'location': 'Indoor',
        'is_active': 1,
      },
      {
        'table_number': 'A3',
        'capacity': 4,
        'location': 'Indoor',
        'is_active': 1,
      },
      {
        'table_number': 'A4',
        'capacity': 4,
        'location': 'Indoor',
        'is_active': 1,
      },
      {
        'table_number': 'B1',
        'capacity': 4,
        'location': 'Outdoor',
        'is_active': 1,
      },
      {
        'table_number': 'B2',
        'capacity': 6,
        'location': 'Outdoor',
        'is_active': 1,
      },
      {
        'table_number': 'B3',
        'capacity': 6,
        'location': 'Outdoor',
        'is_active': 1,
      },
      {'table_number': 'V1', 'capacity': 8, 'location': 'VIP', 'is_active': 1},
      {'table_number': 'V2', 'capacity': 10, 'location': 'VIP', 'is_active': 1},
    ];
    for (final t in tables) {
      await db.insert('tables', t);
    }
  }

  static Future<void> _seedFarmPackages(db) async {
    final packages = [
      {
        'farm_type': 'ayam',
        'title': 'Starter Kit Ayam Kampung',
        'description':
            'Paket lengkap memulai usaha ternak ayam kampung organik dengan modal terjangkau.',
        'initial_capital_min': 5000000.0,
        'initial_capital_rec': 8000000.0,
        'harvest_time_days': 90,
        'roi_months': 6,
        'monthly_income_est': 2500000.0,
        'steps':
            '["Persiapan kandang 5x5m","Pembelian bibit DOC 100 ekor","Pemberian pakan organik","Vaksinasi rutin","Panen dan pemasaran"]',
        'equipment_list':
            '["Kandang kawat","Tempat pakan otomatis","Tempat minum nipple","Lampu pemanas","Timbangan digital"]',
      },
      {
        'farm_type': 'lele',
        'title': 'Starter Kit Budidaya Lele',
        'description':
            'Paket usaha budidaya lele dengan kolam terpal, cocok untuk lahan terbatas.',
        'initial_capital_min': 3000000.0,
        'initial_capital_rec': 5000000.0,
        'harvest_time_days': 60,
        'roi_months': 4,
        'monthly_income_est': 1800000.0,
        'steps':
            '["Pasang kolam terpal 4x6m","Isi air dan diamkan 7 hari","Tebar benih lele 2000 ekor","Pemberian pakan 3x sehari","Panen pada hari ke-60"]',
        'equipment_list':
            '["Kolam terpal","Pompa aerator","Jaring panen","Ember besar","Timbangan"]',
      },
      {
        'farm_type': 'hidroponik',
        'title': 'Starter Kit Hidroponik NFT',
        'description':
            'Paket bertani sayuran segar dengan sistem hidroponik NFT untuk rumahan atau bisnis kecil.',
        'initial_capital_min': 2000000.0,
        'initial_capital_rec': 4000000.0,
        'harvest_time_days': 30,
        'roi_months': 3,
        'monthly_income_est': 1500000.0,
        'steps':
            '["Rakit instalasi pipa NFT","Siapkan nutrisi AB Mix","Semai benih sayuran","Pindah tanam ke lubang NFT","Panen sayuran per 30 hari"]',
        'equipment_list':
            '["Pipa PVC 3 inch","Pompa air kecil","Nutrisi AB Mix","Net pot","Rockwool","Benih sayuran"]',
      },
    ];
    for (final p in packages) {
      await db.insert('farm_packages', p);
    }
  }
}
