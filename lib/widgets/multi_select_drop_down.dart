import 'package:flutter/material.dart';

class MultiSelectDropdown<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final List<T> selectedItems;
  final ValueChanged<List<T>> onChanged;
  final String Function(T) displayText;
  final InputDecoration? decoration;
  final String? Function(List<T>)? validator;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    required this.displayText,
    this.decoration,
    this.validator,
  });

  @override
  _MultiSelectDropdownState<T> createState() => _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<MultiSelectDropdown<T>> {
  late List<T> _tempSelectedItems;

  @override
  void initState() {
    super.initState();
    _tempSelectedItems = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMultiSelectDialog(context),
      child: InputDecorator(
        decoration:
            widget.decoration ??
            InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              errorText: widget.validator?.call(widget.selectedItems),
            ),
        child: Text(
          _getDisplayText(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color:
                widget.selectedItems.isEmpty
                    ? Theme.of(context).hintColor
                    : null,
          ),
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (widget.selectedItems.isEmpty) {
      return 'Select ${widget.label}';
    } else if (widget.selectedItems.length == 1) {
      return widget.displayText(widget.selectedItems.first);
    } else {
      return '${widget.selectedItems.length} selected';
    }
  }

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    final result = await showDialog<List<T>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select ${widget.label}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return CheckboxListTile(
                      title: Text(
                        widget.displayText(item),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      value: _tempSelectedItems.contains(item),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _tempSelectedItems.add(item);
                          } else {
                            _tempSelectedItems.remove(item);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _tempSelectedItems),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      widget.onChanged(List.from(result));
    }
  }
}
