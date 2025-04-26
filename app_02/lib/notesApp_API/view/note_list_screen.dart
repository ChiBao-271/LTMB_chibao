// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../db/note_database_helper.dart';
// import '../model/note.dart';
// import '../view/note_item.dart';
// import 'note_form_screen.dart';
// import 'note_detail_screen.dart';
// import '../mode/modeDark-Light.dart';
// import 'dart:io';
//
// class NoteListScreen extends StatefulWidget {
//   @override
//   _NoteListScreenState createState() => _NoteListScreenState();
// }
//
// class _NoteListScreenState extends State<NoteListScreen> {
//   final NoteDatabaseHelper dbHelper = NoteDatabaseHelper();
//   List<Note> notes = [];
//   List<Note> filteredNotes = [];
//   bool isGridView = false;
//   int? filterPriority;
//   TextEditingController searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _loadNotes();
//   }
//
//   Future<void> _loadNotes() async {
//     final loadedNotes = await dbHelper.getAllNotes();
//     setState(() {
//       notes = loadedNotes;
//       filteredNotes = notes;
//     });
//   }
//
//   void _filterNotes() {
//     setState(() {
//       filteredNotes = notes.where((note) {
//         final matchesSearch = note.title.toLowerCase().contains(searchController.text.toLowerCase()) ||
//             note.content.toLowerCase().contains(searchController.text.toLowerCase());
//         final matchesPriority = filterPriority == null || note.priority == filterPriority;
//         return matchesSearch && matchesPriority;
//       }).toList();
//     });
//   }
//
//   void _toggleComplete(Note note, bool value) async {
//     final updatedNote = note.copyWith(isCompleted: value, modifiedAt: DateTime.now());
//     await dbHelper.updateNote(updatedNote);
//     _loadNotes();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Danh sách Ghi chú', style: Theme.of(context).appBarTheme.foregroundColor != null
//             ? TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)
//             : null),
//         actions: [
//           IconButton(
//             icon: Icon(isGridView ? Icons.list : Icons.grid_view),
//             onPressed: () => setState(() => isGridView = !isGridView),
//           ),
//           PopupMenuButton<int>(
//             onSelected: (value) {
//               setState(() {
//                 filterPriority = value == 0 ? null : value;
//                 _filterNotes();
//               });
//             },
//             itemBuilder: (context) => [
//               PopupMenuItem(value: 0, child: Text('Tất cả mức độ ưu tiên')),
//               PopupMenuItem(value: 1, child: Text('Thấp')),
//               PopupMenuItem(value: 2, child: Text('Trung bình')),
//               PopupMenuItem(value: 3, child: Text('Cao')),
//             ],
//           ),
//           IconButton(
//             icon: Icon(Provider.of<ThemeProvider>(context).isDarkMode
//                 ? Icons.light_mode
//                 : Icons.dark_mode),
//             onPressed: () {
//               Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 labelText: 'Tìm kiếm Ghi chú',
//                 border: OutlineInputBorder(),
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.clear),
//                   onPressed: () {
//                     searchController.clear();
//                     _filterNotes();
//                   },
//                 ),
//               ),
//               onChanged: (value) => _filterNotes(),
//             ),
//           ),
//           Expanded(
//             child: filteredNotes.isEmpty
//                 ? Center(child: Text('Không tìm thấy ghi chú', style: Theme.of(context).textTheme.bodyLarge))
//                 : isGridView
//                 ? GridView.builder(
//               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 1,
//               ),
//               itemCount: filteredNotes.length,
//               itemBuilder: (context, index) {
//                 final note = filteredNotes[index];
//                 return NoteItem(
//                   note: note,
//                   onEdit: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => NoteFormScreen(note: note),
//                       ),
//                     ).then((_) => _loadNotes());
//                   },
//                   onDelete: () {
//                     showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         title: Text('Xóa Ghi chú'),
//                         content: Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: Text('Hủy'),
//                           ),
//                           TextButton(
//                             onPressed: () async {
//                               await dbHelper.deleteNote(note.id!);
//                               Navigator.pop(context);
//                               _loadNotes();
//                             },
//                             child: Text('Xóa'),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                   onToggleComplete: (value) => _toggleComplete(note, value),
//                 );
//               },
//             )
//                 : ListView.builder(
//               itemCount: filteredNotes.length,
//               itemBuilder: (context, index) {
//                 final note = filteredNotes[index];
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => NoteDetailScreen(note: note),
//                       ),
//                     ).then((_) => _loadNotes());
//                   },
//                   child: NoteItem(
//                     note: note,
//                     onEdit: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => NoteFormScreen(note: note),
//                         ),
//                       ).then((_) => _loadNotes());
//                     },
//                     onDelete: () {
//                       showDialog(
//                         context: context,
//                         builder: (context) => AlertDialog(
//                           title: Text('Xóa Ghi chú'),
//                           content: Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: Text('Hủy'),
//                             ),
//                             TextButton(
//                               onPressed: () async {
//                                 await dbHelper.deleteNote(note.id!);
//                                 Navigator.pop(context);
//                                 _loadNotes();
//                               },
//                               child: Text('Xóa'),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     onToggleComplete: (value) => _toggleComplete(note, value),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => NoteFormScreen()),
//           ).then((_) => _loadNotes());
//         },
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }