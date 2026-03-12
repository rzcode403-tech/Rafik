import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/news_article.dart';

class AppDB {
  static Database? _db;
  static Future<Database> get db async { _db ??= await _init(); return _db!; }

  static Future<Database> _init() async {
    final path = p.join(await getDatabasesPath(), 'rafiq2.db');
    return openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS bookmarks('
        'id INTEGER PRIMARY KEY AUTOINCREMENT,'
        'title TEXT, url TEXT, source TEXT, savedAt TEXT)');
    });
  }

  static Future<void> save(NewsArticle a) async {
    await (await db).insert('bookmarks', {
      'title': a.title, 'url': a.url, 'source': a.source,
      'savedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getAll() async =>
      (await db).query('bookmarks', orderBy: 'savedAt DESC');
  static Future<void> delete(int id) async =>
      (await db).delete('bookmarks', where: 'id=?', whereArgs: [id]);
  static Future<void> deleteAll() async => (await db).delete('bookmarks');
}
