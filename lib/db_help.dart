import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (kIsWeb) return Future.value(null);
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'sales_app.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE parties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_name TEXT NOT NULL,
            product_rate INTEGER NOT NULL
          )
        ''');
        await db.execute('''
        CREATE TABLE pricelist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          party_id INTEGER NOT NULL,
          price INTEGER NOT NULL,
          UNIQUE (product_id, party_id),
          FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
          FOREIGN KEY (party_id) REFERENCES parties(id) ON DELETE CASCADE
        )
      ''');
        await db.execute('''
            CREATE TABLE product_head (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              product_name TEXT NOT NULL,
              product_rate INTEGER NOT NULL
            )
          ''');
        await db.execute('''
  CREATE TABLE IF NOT EXISTS folders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    folder_name TEXT NOT NULL UNIQUE
  )
''');

        await db.execute('''
  CREATE TABLE IF NOT EXISTS products_design (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    design_no TEXT NOT NULL UNIQUE,
    product_head_id INTEGER NOT NULL,
    folder_id INTEGER,
    FOREIGN KEY (product_head_id) REFERENCES product_head(id) ON DELETE CASCADE,
    FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
  )
''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 7) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            folder_name TEXT NOT NULL UNIQUE
          )
        ''');

        await db.execute('''
         CREATE TABLE IF NOT EXISTS products_design (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        design_no TEXT NOT NULL UNIQUE,
        product_head_id INTEGER NOT NULL,
        folder_id INTEGER,
        FOREIGN KEY (product_head_id) REFERENCES product_head(id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    ''');
        }
      },
    );
  }

  Future<List<String>> getCachedParties() async {
    if (kIsWeb) return []; // Web: Fetch from Supabase instead
    Database db = await instance.database;
    final result = await db.query('parties', orderBy: 'name ASC');
    return result.map((row) => row['name'] as String).toList();
  }

  Future<void> cacheParties(List<String> parties) async {
    if (kIsWeb) return; // Web: No caching
    Database db = await instance.database;
    await db.delete('parties');
    for (var name in parties) {
      await db.insert('parties', {'name': name});
    }
  }

  Future<List<Map<String, dynamic>>> getCachedDesigns() async {
    if (kIsWeb) return []; // Web: Fetch from Supabase instead
    Database db = await instance.database;
    return await db.query(
      'products_design',
      columns: ['design_no', 'product_head_id'],
      orderBy: 'design_no ASC',
    );
  }

  Future<void> cachedDesigns(List<Map<String, dynamic>> designs) async {
    if (kIsWeb) return; // Web: No caching
    Database db = await instance.database;
    await db.delete('products_design');

    for (var design in designs) {
      await db.insert('products_design', {
        'design_no': design['design_no'],
        'product_head_id': design['product_head_id'],
      });
    }
  }

  Future<List<Map<String, dynamic>>> getCachedProducts() async {
    if (kIsWeb) return []; // ✅ Web: No caching

    Database db = await instance.database;
    final result = await db.query('product_head', orderBy: 'product_name ASC');

    return result
        .map(
          (row) => {
            'product_name': row['product_name'],
            'product_rate': row['product_rate'] as int,
          },
        )
        .toList();
  }

  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    if (kIsWeb) return; // ✅ Web: No caching

    Database db = await instance.database;
    await db.delete('product_head');
    for (var product in products) {
      await db.insert('product_head', {
        'product_name': product['product_name'],
        'product_rate': int.parse(product['product_rate'].toString()),
      });
    }
  }
}
