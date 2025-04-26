// import 'package:flutter/material.dart';
// import '../model/note.dart';
//
// class NoteItem extends StatelessWidget {
//   final Note note;
//   final VoidCallback onEdit;
//   final VoidCallback onDelete;
//   final Function(bool) onToggleComplete;
//
//   const NoteItem({
//     Key? key,
//     required this.note,
//     required this.onEdit,
//     required this.onDelete,
//     required this.onToggleComplete,
//   }) : super(key: key);
//
//   Color getPriorityColor(BuildContext context) {
//     final brightness = Theme.of(context).brightness;
//     switch (note.priority) {
//       case 1:
//         return brightness == Brightness.dark ? Colors.green[300]! : Colors.green;
//       case 2:
//         return brightness == Brightness.dark ? Colors.yellow[300]! : Colors.yellow;
//       case 3:
//         return brightness == Brightness.dark ? Colors.red[300]! : Colors.red;
//       default:
//         return brightness == Brightness.dark ? Colors.grey[400]! : Colors.grey;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       color: note.color != null
//           ? Color(int.parse('0xFF${note.color}'))
//           : Theme.of(context).cardColor,
//       child: ListTile(
//         title: Text(
//           note.title,
//           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//             decoration: note.isCompleted ? TextDecoration.lineThrough : null,
//           ),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               note.content.length > 50
//                   ? '${note.content.substring(0, 50)}...'
//                   : note.content,
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             Text(
//               'Priority: ${note.priority}',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//             Text(
//               'Last modified: ${note.modifiedAt.toString()}',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
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
//             if (note.imagePath != null)
//               Image.file(
//                 File(note.imagePath!),
//                 height: 50,
//                 width: 50,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
//               ),
//           ],
//         ),
//         leading: Checkbox(
//           value: note.isCompleted,
//           onChanged: (value) => onToggleComplete(value!),
//           activeColor: Theme.of(context).colorScheme.primary,
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
//               onPressed: onEdit,
//             ),
//             IconButton(
//               icon: Icon(Icons.delete, color: Colors.red),
//               onPressed: onDelete,
//             ),
//           ],
//         ),
//         tileColor: getPriorityColor(context).withOpacity(0.2),
//       ),
//     );
//   }
// }