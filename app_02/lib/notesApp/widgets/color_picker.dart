import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String?> onColorChanged;

  const ColorPicker({
    Key? key,
    required this.selectedColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedColor,
      decoration: const InputDecoration(labelText: 'Màu Sắc'), // Đổi "Color"
      items: const [
        DropdownMenuItem(value: null, child: Text('Mặc Định')), // Đổi "Default"
        DropdownMenuItem(value: '#FF0000', child: Text('Đỏ')), // Đổi "Red"
        DropdownMenuItem(value: '#00FF00', child: Text('Xanh Lá')), // Đổi "Green"
        DropdownMenuItem(value: '#0000FF', child: Text('Xanh Dương')), // Đổi "Blue"
      ],
      onChanged: onColorChanged,
    );
  }
}