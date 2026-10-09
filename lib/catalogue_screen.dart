import 'package:flutter/material.dart';

import 'catalogue_repository.dart';
import 'database_helper.dart';
import 'roster_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({
    super.key,
    required this.helper,
    required this.repository,
    this.folder,
  });
  final DatabaseHelper helper;
  final CatalogueRepository repository;
  final Folder? folder;
  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  List<Folder> _folders = [];
  List<CatalogueCard> _cards = [];
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final folders = await widget.repository.getFoldersWithCounts();
      final cards = widget.folder == null
          ? <CatalogueCard>[]
          : await widget.repository.getCards(widget.folder!.id!);
      if (mounted) {
        setState(() {
          _folders = folders;
          _cards = cards;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not refresh. Tap refresh to retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _folderForm([Folder? folder]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          FolderDialog(repository: widget.repository, folder: folder),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _cardForm([CatalogueCard? card]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CardForm(
          repository: widget.repository,
          folders: _folders,
          folderId: widget.folder!.id!,
          card: card,
        ),
      ),
    );
    if (saved == true && mounted) await _refresh();
  }

  Future<void> _delete(
    String name,
    Future<void> Function() action, {
    bool folder = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: Text(
          folder
              ? 'This folder and every card inside it will be permanently deleted.'
              : 'This card will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delete failed. Refresh and try again.'),
          ),
        );
      }
      return;
    }
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.folder?.name ?? 'Card Catalogue'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _busy ? null : _refresh,
          icon: const Icon(Icons.refresh),
        ),
        if (widget.folder == null)
          IconButton(
            tooltip: 'Part I guest roster',
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RosterScreen(helper: widget.helper),
              ),
            ),
          ),
      ],
    ),
    body: Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.folder == null
                ? '${_folders.length} folders · saved on this device'
                : 'Folder ID ${widget.folder!.id} · ${_cards.length} cards',
          ),
        ),
        Expanded(
          child: widget.folder == null
              ? _folders.isEmpty
                    ? const Center(
                        child: Text('No folders yet. Add your first folder.'),
                      )
                    : ListView.builder(
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          final f = _folders[index];
                          return ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(f.name),
                            subtitle: Text('ID ${f.id} · ${f.count} cards'),
                            onTap: _busy
                                ? null
                                : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CatalogueScreen(
                                          helper: widget.helper,
                                          repository: widget.repository,
                                          folder: f,
                                        ),
                                      ),
                                    );
                                    if (mounted) await _refresh();
                                  },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Rename ${f.name}',
                                  onPressed: _busy
                                      ? null
                                      : () => _folderForm(f),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete ${f.name}',
                                  onPressed: _busy
                                      ? null
                                      : () => _delete(
                                          f.name,
                                          () => widget.repository.deleteFolder(
                                            f.id!,
                                          ),
                                          folder: true,
                                        ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      )
              : _cards.isEmpty
              ? const Center(child: Text('This folder is empty. Add a card.'))
              : ListView.builder(
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final c = _cards[index];
                    return ListTile(
                      leading: CardImage(card: c),
                      title: Text(c.title),
                      subtitle: Text('${c.suit} · ID ${c.id}\n${c.notes}'),
                      isThreeLine: c.notes.isNotEmpty,
                      onTap: _busy ? null : () => _cardForm(c),
                      trailing: IconButton(
                        tooltip: 'Delete ${c.title}',
                        onPressed: _busy
                            ? null
                            : () => _delete(
                                c.title,
                                () => widget.repository.deleteCard(c.id!),
                              ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy
          ? null
          : () => widget.folder == null ? _folderForm() : _cardForm(),
      icon: const Icon(Icons.add),
      label: Text(widget.folder == null ? 'Add folder' : 'Add card'),
    ),
  );
}

class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.card});
  final CatalogueCard card;
  Widget get fallback => SizedBox(
    width: 48,
    height: 48,
    child: Center(
      child: Text(
        CatalogueCard.symbols[card.suit] ?? '?',
        style: TextStyle(
          fontSize: 32,
          color: ['Hearts', 'Diamonds'].contains(card.suit)
              ? Colors.red
              : Colors.black,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(card.imageRef ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return fallback;
    }
    return Image.network(
      uri.toString(),
      width: 48,
      height: 48,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => fallback,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

class FolderDialog extends StatefulWidget {
  const FolderDialog({super.key, required this.repository, this.folder});
  final CatalogueRepository repository;
  final Folder? folder;
  @override
  State<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends State<FolderDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.folder?.name,
  );
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter a folder name.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.folder == null) {
        await widget.repository.insertFolder(_name.text);
      } else {
        await widget.repository.updateFolder(widget.folder!.id!, _name.text);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save. Use a unique folder name and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(widget.folder == null ? 'Add folder' : 'Rename folder'),
      content: TextField(
        controller: _name,
        enabled: !_busy,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Folder name',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}

class CardForm extends StatefulWidget {
  const CardForm({
    super.key,
    required this.repository,
    required this.folders,
    required this.folderId,
    this.card,
  });
  final CatalogueRepository repository;
  final List<Folder> folders;
  final int folderId;
  final CatalogueCard? card;
  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.card?.title);
  late final _notes = TextEditingController(text: widget.card?.notes);
  late final _image = TextEditingController(text: widget.card?.imageRef);
  late int _folderId = widget.card?.folderId ?? widget.folderId;
  late String _suit = widget.card?.suit ?? CatalogueCard.suits.first;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final card = CatalogueCard(
      id: widget.card?.id,
      title: _title.text,
      suit: _suit,
      folderId: _folderId,
      notes: _notes.text,
      imageRef: _image.text,
    );
    try {
      if (widget.card == null) {
        await widget.repository.insertCard(card);
      } else {
        await widget.repository.updateCard(card);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save. The folder or card may have been removed. Your input is preserved.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.card == null ? 'Add card' : 'Edit card #${widget.card!.id}',
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a title.' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _suit,
              decoration: const InputDecoration(labelText: 'Suit'),
              items: CatalogueCard.suits
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text('${CatalogueCard.symbols[s]} $s'),
                    ),
                  )
                  .toList(),
              onChanged: _busy ? null : (v) => setState(() => _suit = v!),
            ),
            DropdownButtonFormField<int>(
              initialValue: _folderId,
              decoration: const InputDecoration(labelText: 'Folder'),
              items: widget.folders
                  .map(
                    (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                  )
                  .toList(),
              validator: (v) => widget.folders.any((f) => f.id == v)
                  ? null
                  : 'Choose a valid folder.',
              onChanged: _busy ? null : (v) => setState(() => _folderId = v!),
            ),
            TextFormField(
              controller: _notes,
              enabled: !_busy,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            TextFormField(
              controller: _image,
              enabled: !_busy,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                helperText:
                    'HTTPS images; missing or broken images show the suit.',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Save card'),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}
