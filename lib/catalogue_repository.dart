import 'package:sqflite/sqflite.dart';

class Folder {
  const Folder({
    this.id,
    required this.name,
    required this.createdAt,
    this.count = 0,
  });
  final int? id;
  final String name;
  final String createdAt;
  final int count;
  factory Folder.fromMap(Map<String, Object?> row) => Folder(
    id: row['id'] as int,
    name: row['name'] as String,
    createdAt: row['created_at'] as String,
    count: row['card_count'] as int? ?? 0,
  );
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'created_at': createdAt,
  };
}

class CatalogueCard {
  const CatalogueCard({
    this.id,
    required this.title,
    required this.suit,
    required this.folderId,
    this.notes = '',
    this.imageRef,
  });
  static const suits = ['Spades', 'Hearts', 'Diamonds', 'Clubs'];
  static const symbols = {
    'Spades': '♠',
    'Hearts': '♥',
    'Diamonds': '♦',
    'Clubs': '♣',
  };
  final int? id;
  final String title, suit, notes;
  final int folderId;
  final String? imageRef;
  factory CatalogueCard.fromMap(Map<String, Object?> row) => CatalogueCard(
    id: row['id'] as int,
    title: row['title'] as String,
    suit: row['suit'] as String,
    folderId: row['folder_id'] as int,
    notes: row['notes'] as String,
    imageRef: row['image_ref'] as String?,
  );
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'title': title.trim(),
    'suit': suit,
    'folder_id': folderId,
    'notes': notes.trim(),
    'image_ref': imageRef == null || imageRef!.trim().isEmpty
        ? null
        : imageRef!.trim(),
  };
}

class CatalogueRepository {
  CatalogueRepository(this.db);
  final Database db;
  Future<List<Folder>> getFoldersWithCounts() async => (await db.rawQuery('''
    SELECT f.*, COUNT(c.id) AS card_count FROM folders f
    LEFT JOIN cards c ON c.folder_id = f.id GROUP BY f.id
    ORDER BY f.name COLLATE NOCASE, f.id
  ''')).map(Folder.fromMap).toList();
  Future<List<CatalogueCard>> getCards(int folderId) async => (await db.query(
    'cards',
    where: 'folder_id = ?',
    whereArgs: [folderId],
    orderBy: 'title COLLATE NOCASE, id',
  )).map(CatalogueCard.fromMap).toList();
  Future<int> insertFolder(String name) {
    if (name.trim().isEmpty) throw ArgumentError('Enter a folder name.');
    return db.insert(
      'folders',
      Folder(
        name: name.trim(),
        createdAt: DateTime.now().toUtc().toIso8601String(),
      ).toMap(),
    );
  }

  Future<void> updateFolder(int id, String name) async {
    if (name.trim().isEmpty) throw ArgumentError('Enter a folder name.');
    _requireRow(
      await db.update(
        'folders',
        {'name': name.trim()},
        where: 'id = ?',
        whereArgs: [id],
      ),
    );
  }

  Future<void> deleteFolder(int id) async =>
      _requireRow(await db.delete('folders', where: 'id = ?', whereArgs: [id]));
  void _validate(CatalogueCard card) {
    if (card.title.trim().isEmpty) throw ArgumentError('Enter a card title.');
    if (!CatalogueCard.suits.contains(card.suit)) {
      throw ArgumentError('Choose a supported suit.');
    }
  }

  Future<int> insertCard(CatalogueCard card) {
    _validate(card);
    return db.insert('cards', card.toMap()..remove('id'));
  }

  Future<void> updateCard(CatalogueCard card) async {
    _validate(card);
    if (card.id == null) throw ArgumentError('Missing card ID.');
    _requireRow(
      await db.update(
        'cards',
        card.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [card.id],
      ),
    );
  }

  Future<void> deleteCard(int id) async =>
      _requireRow(await db.delete('cards', where: 'id = ?', whereArgs: [id]));
  void _requireRow(int count) {
    if (count != 1) {
      throw StateError('This record no longer exists. Refresh the list.');
    }
  }
}
