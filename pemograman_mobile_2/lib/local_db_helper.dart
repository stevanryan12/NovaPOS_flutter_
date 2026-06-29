import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbHelper {
  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite offline database is not supported on Web browser.');
    }
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'kasir_offline.db');

    return await openDatabase(
      pathString,
      version: 1,
      onCreate: (db, version) async {
        // Tabel barang lokal
        await db.execute('''
          CREATE TABLE barang_local (
            no_barcode TEXT PRIMARY KEY,
            nama TEXT NOT NULL,
            harga INTEGER NOT NULL,
            hpp INTEGER DEFAULT 0,
            stok INTEGER NOT NULL,
            kategori TEXT DEFAULT 'Umum'
          )
        ''');

        // Tabel pelanggan lokal
        await db.execute('''
          CREATE TABLE pelanggan_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nama TEXT NOT NULL,
            telepon TEXT,
            total_utang INTEGER DEFAULT 0
          )
        ''');

        // Antrean sinkronisasi (jika offline)
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            table_name TEXT NOT NULL,
            action_type TEXT NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
            row_data TEXT NOT NULL, -- JSON string dari data yang diubah
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  // --- CRUD BARANG LOKAL ---
  Future<int> insertBarangLocal(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert(
      'barang_local',
      {
        'no_barcode': item['no_barcode'],
        'nama': item['nama'],
        'harga': item['harga'],
        'hpp': item['hpp'] ?? 0,
        'stok': item['stok'],
        'kategori': item['kategori'] ?? 'Umum',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchBarangLocal() async {
    final db = await database;
    return await db.query('barang_local', orderBy: 'nama ASC');
  }

  // --- CRUD PELANGGAN LOKAL ---
  Future<int> insertPelangganLocal(Map<String, dynamic> client) async {
    final db = await database;
    return await db.insert(
      'pelanggan_local',
      {
        'id': client['id'],
        'nama': client['nama'],
        'telepon': client['telepon'],
        'total_utang': client['total_utang'] ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchPelangganLocal() async {
    final db = await database;
    return await db.query('pelanggan_local', orderBy: 'nama ASC');
  }

  // --- SYNC QUEUE MANAGEMENT ---
  Future<void> addToSyncQueue(String tableName, String action, String rowDataJson) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'action_type': action,
      'row_data': rowDataJson,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }
}
