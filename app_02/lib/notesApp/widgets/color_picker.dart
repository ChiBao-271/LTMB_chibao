import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  final String? selectedColor;
  final ValueChanged<String?> onColorChanged;

  const ColorPicker({
    Key? key,
    this.selectedColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  bool _showColorPicker = false;

  final List<Map<String, dynamic>> _colorOptions = const [
    {'hex': '#CFF4D2', 'name': 'Xanh Bạc Hà Nhạt'},
    {'hex': '#FFD1DC', 'name': 'Hồng Phấn Nhạt'},
    {'hex': '#E6D7F5', 'name': 'Tím Pastel Nhẹ'},
    {'hex': '#FFE8B5', 'name': 'Vàng Mơ Nhạt'},
    {'hex': '#C9E4F6', 'name': 'Xanh Lam Nhẹ'},
    {'hex': '#FFDAB9', 'name': 'Cam Đào Nhạt'},
    {'hex': '#E0F7E9', 'name': 'Xanh Lá Nhạt'},
    {'hex': '#E8DAEF', 'name': 'Tím Oải Hương Nhạt'},
    {'hex': '#D6EAF8', 'name': 'Xanh Ngọc Bích Nhạt'},
    {'hex': '#FFE4E1', 'name': 'Hồng Anh Đào Nhạt'},
    {'hex': '#D6E4E5', 'name': 'Xanh Phấn Nhạt'},
    {'hex': '#FFF5E4', 'name': 'Vàng Kem Nhạt'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showColorPicker = !_showColorPicker;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.selectedColor != null
                  ? Color(int.parse('0xFF${widget.selectedColor!.substring(1)}'))
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Màu Note của bạn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.selectedColor != null ? Colors.black87 : Colors.black54,
                  ),
                ),
                Icon(
                  _showColorPicker ? Icons.expand_less : Icons.expand_more,
                  color: widget.selectedColor != null ? Colors.black87 : Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_showColorPicker) ...[
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _colorOptions.length,
            itemBuilder: (context, index) {
              final colorOption = _colorOptions[index];
              final colorHex = colorOption['hex'] as String;
              final colorName = colorOption['name'] as String;
              final isSelected = widget.selectedColor == colorHex;

              return GestureDetector(
                onTap: () {
                  widget.onColorChanged(colorHex);
                  setState(() {
                    _showColorPicker = false;
                  });
                },
                child: Tooltip(
                  message: colorName,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        if (isSelected)
                          Center(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.black87,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}