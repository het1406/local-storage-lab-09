import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// Reconstructed from the schema and API described in the activity guide.
class DatabaseHelper {
  static const table = 'my_table';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';
  late Database _db;

  Database get database => _db;

  Future<void> init({String? databasePath}) async {
    final path =
        databasePath ??
        join((await getApplicationDocumentsDirectory()).path, 'MyDatabase.db');
    _db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await createCatalogue(db);
      },
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY,
          $columnName TEXT NOT NULL,
          $columnAge INTEGER NOT NULL
        )
      ''');
        await createCatalogue(db);
      },
    );
  }

  // sqflite already wraps onCreate/onUpgrade in a transaction.
  static Future<void> createCatalogue(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE CHECK(length(trim(name)) > 0),
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        suit TEXT NOT NULL CHECK(suit IN ('Spades','Hearts','Diamonds','Clubs')),
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL REFERENCES folders(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_cards_folder_id ON cards(folder_id)');
  }

  Future<void> close() => _db.close();

  Future<int> insert(Map<String, dynamic> row) => _db.insert(table, row);
  Future<List<Map<String, dynamic>>> queryAllRows() =>
      _db.query(table, orderBy: '$columnId ASC');
  Future<int> queryRowCount() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM $table'),
      ) ??
      0;
  Future<int> update(Map<String, dynamic> row) => _db.update(
    table,
    row,
    where: '$columnId = ?',
    whereArgs: [row[columnId] as int],
  );
  Future<int> delete(int id) =>
      _db.delete(table, where: '$columnId = ?', whereArgs: [id]);
}
