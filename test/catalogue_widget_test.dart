import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:local_storage_lab/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_lab/catalogue_repository.dart';
import 'package:local_storage_lab/catalogue_screen.dart';

class _UnusedDatabase implements Database {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryRepository extends CatalogueRepository {
  _MemoryRepository() : super(_UnusedDatabase());
  int writes = 0;
  final folders = [
    const Folder(id: 8, name: 'Disposable', createdAt: '2026-10-08', count: 1),
  ];
  @override
  Future<List<Folder>> getFoldersWithCounts() async => List.of(folders);
  @override
  Future<void> deleteFolder(int id) async {
    writes++;
    folders.removeWhere((f) => f.id == id);
  }

  @override
  Future<void> updateCard(CatalogueCard card) async {
    writes++;
  }

  @override
  Future<int> insertCard(CatalogueCard card) async {
    writes++;
    return 11;
  }
}

void main() {
  testWidgets('T3 cancel edit and T6 blank title write nothing', (
    tester,
  ) async {
    final repository = _MemoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Open editor'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CardForm(
                    repository: repository,
                    folders: repository.folders,
                    folderId: 8,
                    card: const CatalogueCard(
                      id: 11,
                      title: 'Original',
                      suit: 'Spades',
                      folderId: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.tap(find.text('Save card'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title.'), findsOneWidget);
    expect(repository.writes, 0);
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved edit');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
    expect(repository.writes, 0);
  });
  testWidgets('T5 cancel deletion preserves folder; confirm targets its ID', (
    tester,
  ) async {
    final repository = _MemoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: CatalogueScreen(helper: DatabaseHelper(), repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete Disposable'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "Disposable"?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.writes, 0);
    expect(repository.folders.single.id, 8);
    await tester.tap(find.byTooltip('Delete Disposable'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.writes, 1);
    expect(repository.folders, isEmpty);
  });
  testWidgets('T6 missing, malformed and unavailable image show the suit', (
    tester,
  ) async {
    for (final ref in [
      null,
      'not an image reference',
      'https://example.invalid/missing.png',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CardImage(
              card: CatalogueCard(
                title: 'Ace',
                suit: 'Hearts',
                folderId: 1,
                imageRef: ref,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('♥'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
