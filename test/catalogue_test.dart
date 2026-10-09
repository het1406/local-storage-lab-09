import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:local_storage_lab/database_helper.dart';
import 'package:local_storage_lab/catalogue_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Directory temp;
  late String path;
  late DatabaseHelper helper;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('catalogue_test_');
    path = '${temp.path}/MyDatabase.db';
    helper = DatabaseHelper();
  });
  tearDown(() async {
    await helper.close();
    await temp.delete(recursive: true);
  });
  test('T1 upgrade preserves every legacy row; fresh and upgraded schemas match', () async {
    final old = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE my_table (_id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER NOT NULL)',
        );
      },
    );
    await old.insert('my_table', {'_id': 7, 'name': 'River', 'age': 35});
    await old.insert('my_table', {'_id': 12, 'name': 'Oak', 'age': 130});
    final before = await old.query('my_table', orderBy: '_id');
    await old.close();
    await helper.init(databasePath: path);
    expect(await helper.queryAllRows(), before);
    expect(await helper.database.getVersion(), 2);
    expect(
      (await helper.database.rawQuery('PRAGMA foreign_keys'))
          .single
          .values
          .single,
      1,
    );
    final fresh = DatabaseHelper();
    await fresh.init(databasePath: '${temp.path}/fresh.db');
    const schema =
        "SELECT name, sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' ORDER BY name";
    expect(
      (await helper.database.rawQuery(schema))
          .map(
            (r) =>
                '${r['name']}:${(r['sql'] as String).replaceAll(RegExp(r'\s+'), '')}',
          )
          .toList(),
      (await fresh.database.rawQuery(schema))
          .map(
            (r) =>
                '${r['name']}:${(r['sql'] as String).replaceAll(RegExp(r'\s+'), '')}',
          )
          .toList(),
    );
    await fresh.close();
    debugPrint(
      'T1 PASS: legacy IDs 7,12 and values unchanged; v2 schema matches fresh.',
    );
  });
  test('T2–T5 identity, counts, restart, foreign keys and cascade', () async {
    await helper.init(databasePath: path);
    var repo = CatalogueRepository(helper.database);
    final a = await repo.insertFolder('Study');
    final b = await repo.insertFolder('Archive');
    final one = await repo.insertCard(
      CatalogueCard(title: 'Ace', suit: 'Spades', folderId: a),
    );
    final two = await repo.insertCard(
      CatalogueCard(title: 'King', suit: 'Hearts', folderId: a),
    );
    final three = await repo.insertCard(
      CatalogueCard(title: 'Queen', suit: 'Clubs', folderId: b),
    );
    expect({one, two, three}.length, 3);
    expect((await repo.getCards(a)).map((c) => c.id), [one, two]);
    expect((await repo.getFoldersWithCounts()).map((f) => f.count), [1, 2]);
    await repo.updateCard(
      CatalogueCard(
        id: one,
        title: 'Ace revised',
        suit: 'Spades',
        folderId: a,
        notes: 'Reviewed',
      ),
    );
    expect((await repo.getCards(a)).first.notes, 'Reviewed');
    expect((await repo.getCards(a)).last.title, 'King');
    await repo.updateFolder(a, 'Study revised');
    final before = await helper.database.query('cards', orderBy: 'id');
    await helper.close();
    helper = DatabaseHelper();
    await helper.init(databasePath: path);
    repo = CatalogueRepository(helper.database);
    expect(await helper.database.query('cards', orderBy: 'id'), before);
    await expectLater(
      repo.insertCard(
        CatalogueCard(title: 'Orphan', suit: 'Clubs', folderId: 99999),
      ),
      throwsA(isA<DatabaseException>()),
    );
    await repo.deleteFolder(a);
    expect(await repo.getCards(a), isEmpty);
    expect((await repo.getCards(b)).single.id, three);
    await repo.deleteCard(three);
    await expectLater(repo.deleteCard(three), throwsStateError);
    debugPrint(
      'T2/T3/T4/T5 repository PASS: folders $a,$b; cards $one,$two,$three; reopen unchanged; cascade isolated. UI cancel and force-stop require separate checks.',
    );
  });
  test('T6 invalid title/suit and duplicate folder leave records intact', () async {
    await helper.init(databasePath: path);
    final repo = CatalogueRepository(helper.database);
    final folder = await repo.insertFolder('Examples');
    expect(
      () => repo.insertCard(
        CatalogueCard(title: ' ', suit: 'Hearts', folderId: folder),
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.insertCard(
        CatalogueCard(title: 'Test', suit: 'Stars', folderId: folder),
      ),
      throwsArgumentError,
    );
    await expectLater(
      repo.insertFolder('Examples'),
      throwsA(isA<DatabaseException>()),
    );
    final id = await repo.insertCard(
      CatalogueCard(title: 'No image', suit: 'Diamonds', folderId: folder),
    );
    expect((await repo.getCards(folder)).single.imageRef, isNull);
    expect((await repo.getCards(folder)).single.id, id);
    debugPrint(
      'T6 repository PASS: invalid writes rejected; folder $folder, card $id intact.',
    );
  });
}
