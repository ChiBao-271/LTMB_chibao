import 'package:flutter/material.dart';
import '../db/note_database_helper.dart';
import '../models/note.dart';
import '../widgets/note_item.dart';
import 'note_form_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({Key? key}) : super(key: key);

  @override
  _NoteListScreenState createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final NoteDatabaseHelper dbHelper = NoteDatabaseHelper.instance;
  List<Note> notes = [];
  bool isGridView = false;
  int? filterPriority;
  String sortOption = 'Thời Gian';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  Future<void> _refreshNotes({String? query, int? priority}) async {
    List<Note> fetchedNotes;
    if (query != null && query.isNotEmpty) {
      fetchedNotes = await dbHelper.searchNotes(query);
    } else if (priority != null) {
      fetchedNotes = await dbHelper.getNotesByPriority(priority);
    } else {
      fetchedNotes = await dbHelper.getAllNotes();
    }

    if (sortOption == 'Ưu Tiên') {
      fetchedNotes.sort((a, b) => b.priority.compareTo(a.priority));
    } else {
      fetchedNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    setState(() {
      notes = fetchedNotes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi Chú của bạn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              setState(() {
                filterPriority = null;
              });
              _refreshNotes();
            },
            tooltip: 'Làm Mới Danh Sách',
          ),
          PopupMenuButton<int>(
            onSelected: (value) {
              setState(() {
                filterPriority = value == 0 ? null : value;
                _refreshNotes(
                  priority: filterPriority,
                  query: _searchController.text,
                );
              });
            },
            itemBuilder:
                (context) => [
              const PopupMenuItem(value: 0, child: Text('Tất Cả')),
              const PopupMenuItem(value: 1, child: Text('Thấp')),
              const PopupMenuItem(value: 2, child: Text('Trung Bình')),
              const PopupMenuItem(value: 3, child: Text('Cao')),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc Theo Ưu Tiên',
          ),
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                isGridView = !isGridView;
              });
            },
            tooltip: 'Chuyển Đổi Chế Độ Hiển Thị',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm Kiếm Ghi Chú',
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (value) =>
                  _refreshNotes(query: value, priority: filterPriority),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('Sắp Xếp: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: sortOption,
                  onChanged: (value) {
                    setState(() {
                      sortOption = value!;
                      _refreshNotes(
                        priority: filterPriority,
                        query: _searchController.text,
                      );
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'Thời Gian',
                      child: Text('Theo Thời Gian'),
                    ),
                    DropdownMenuItem(
                      value: 'Ưu Tiên',
                      child: Text('Theo Ưu Tiên'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
            notes.isEmpty
                ? const Center(child: Text('Không có ghi chú nào.'))
                : isGridView
                ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio:
                1.0, // Điều chỉnh tỷ lệ để ô vuông hơn, tránh overflow
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: notes.length,
              itemBuilder:
                  (context, index) => NoteItem(
                note: notes[index],
                onRefresh: _refreshNotes,
                isGridView: isGridView,
              ),
            )
                : ListView.builder(
              itemCount: notes.length,
              itemBuilder:
                  (context, index) => NoteItem(
                note: notes[index],
                onRefresh: _refreshNotes,
                isGridView: isGridView,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToNoteForm(BuildContext context, {Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteForm(note: note)),
    );
    _refreshNotes();
  }
}
