// lib/screens/note_list_screen.dart
import 'package:flutter/material.dart';
import '../db/note_database_helper.dart';
import '../model/note.dart';
import '../view/note_item.dart';
import 'note_form_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final NoteDatabaseHelper dbHelper = NoteDatabaseHelper();
  List<Note> notes = [];
  bool isGridView = false;
  int? filterPriority;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes({String? query}) async {
    List<Note> loadedNotes;
    if (query != null && query.isNotEmpty) {
      loadedNotes = await dbHelper.searchNotes(query);
    } else if (filterPriority != null) {
      loadedNotes = await dbHelper.getNotesByPriority(filterPriority!);
    } else {
      loadedNotes = await dbHelper.getAllNotes();
    }
    setState(() {
      notes = loadedNotes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách Ghi chú'),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
            tooltip: 'Chuyển đổi chế độ hiển thị',
          ),
          PopupMenuButton<int>(
            onSelected: (value) {
              setState(() {
                filterPriority = value == 0 ? null : value;
              });
              _loadNotes();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('Tất cả mức ưu tiên')),
              const PopupMenuItem(value: 1, child: Text('Ưu tiên Thấp')),
              const PopupMenuItem(value: 2, child: Text('Ưu tiên Trung bình')),
              const PopupMenuItem(value: 3, child: Text('Ưu tiên Cao')),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc theo mức ưu tiên',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadNotes(),
            tooltip: 'Làm mới danh sách',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm ghi chú',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadNotes();
                  },
                ),
              ),
              onChanged: (value) => _loadNotes(query: value),
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? const Center(child: Text('Không tìm thấy ghi chú nào.'))
                : isGridView
                ? GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return NoteItem(
                  note: notes[index],
                  onDelete: () async {
                    await dbHelper.deleteNote(notes[index].id!);
                    _loadNotes();
                  },
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteFormScreen(note: notes[index]),
                      ),
                    ).then((_) => _loadNotes());
                  },
                );
              },
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return NoteItem(
                  note: notes[index],
                  onDelete: () async {
                    await dbHelper.deleteNote(notes[index].id!);
                    _loadNotes();
                  },
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteFormScreen(note: notes[index]),
                      ),
                    ).then((_) => _loadNotes());
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteFormScreen()),
          ).then((_) => _loadNotes());
        },
        child: const Icon(Icons.add),
        tooltip: 'Thêm ghi chú mới',
      ),
    );
  }
}