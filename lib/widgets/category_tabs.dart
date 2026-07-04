import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryTabs extends StatefulWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();
}

class _CategoryTabsState extends State<CategoryTabs> {
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    for (final cat in widget.categories) {
      _focusNodes[cat] = FocusNode()..addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: widget.categories.map((cat) {
          final isSelected = cat == widget.selected;
          final hasFocus = _focusNodes[cat]?.hasFocus ?? false;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Focus(
              focusNode: _focusNodes[cat],
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
                  widget.onChanged(cat);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: GestureDetector(
                onTap: () => widget.onChanged(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE53935)
                        : hasFocus
                            ? Colors.white12
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected || hasFocus ? const Color(0xFFE53935) : Colors.white24,
                    ),
                  ),
                  child: Text(cat, style: TextStyle(fontSize: 18, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
