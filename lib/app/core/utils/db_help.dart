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
      version: 3,
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
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

  // ✅ Get cached products
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

  // ✅ Cache products
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
