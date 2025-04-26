// // lib/screens/note_detail_screen.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../model/note.dart';
// import 'note_form_screen.dart';
//
// class NoteDetailScreen extends StatelessWidget {
//   final Note note;
//
//   const NoteDetailScreen({Key? key, required this.note}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(note.title, style: Theme.of(context).appBarTheme.foregroundColor != null
//             ? TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)
//             : null),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.edit),
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => NoteFormScreen(note: note),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Tiêu đề: ${note.title}',
//               style: Theme.of(context).textTheme.titleLarge,
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Nội dung: ${note.content}',
//               style: Theme.of(context).textTheme.bodyLarge,
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Mức độ ưu tiên: ${note.priority}',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Ngày tạo: ${note.createdAt}',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Cập nhật lần cuối: ${note.modifiedAt}',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             SizedBox(height: 10),
//             if (note.tags != null && note.tags!.isNotEmpty)
//               Wrap(
//                 children: note.tags!
//                     .map((tag) => Chip(
//                   label: Text(tag),
//                   padding: EdgeInsets.all(2),
//                   backgroundColor: Theme.of(context).colorScheme.secondary,
//                   labelStyle: TextStyle(
//                     color: Theme.of(context).colorScheme.onSecondary,
//                   ),
//                 ))
//                     .toList(),
//               ),
//             SizedBox(height: 10),
//             Text(
//               'Hoàn thành: ${note.isCompleted ? "Có" : "Không"}',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             SizedBox(height: 10),
//             if (note.imagePath != null)
//               Image.file(
//                 File(note.imagePath!),
//                 height: 200,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }