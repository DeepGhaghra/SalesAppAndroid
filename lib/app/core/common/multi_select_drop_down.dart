import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

// Define your custom color pool here
class MultiSelectItemModel {
  final String name;
  bool isSelected;

  MultiSelectItemModel({required this.name, this.isSelected = false});
}

class MultiSelectSearchDropdown extends StatefulWidget {
  final List<MultiSelectItemModel> items;
  final String labelText;
  final Function(List<MultiSelectItemModel> selectedItems) onSelectionChanged;
  List<MultiSelectItemModel> selectedItems;

  MultiSelectSearchDropdown({
    Key? key,
    required this.items,
    required this.onSelectionChanged,
    required this.selectedItems,
    this.labelText = "Select Multioptions",
  }) : super(key: key);

  @override
  _MultiSelectSearchDropdownState createState() =>
      _MultiSelectSearchDropdownState();
}

class _MultiSelectSearchDropdownState extends State<MultiSelectSearchDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  List<MultiSelectItemModel> filteredItems = [];
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  // AppColors pool
  final List<Color> colorPool = [
    AppColors.filterPendingColor,
    AppColors.filterFinalizedColor,
    AppColors.filterCheckedInColor,
    AppColors.filterInProgressColor,
    AppColors.filterPausedColor,
    AppColors.filterScheduleColor,
    AppColors.filterNotRecordedColor,
    AppColors.filterLateColor,
    AppColors.filterCancelledColor,
    AppColors.filterCanceledColor,
    AppColors.filterNoShowColor,
    AppColors.filterInsufficientInfoColor,
  ];

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlay();
      Overlay.of(context)!.insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: MediaQuery.of(context).size.width - 32,
            child: CompositedTransformFollower(
              offset: const Offset(0, 55),
              link: _layerLink,
              showWhenUnlinked: false,
              child: _DropdownPopup(
                allItems: widget.items,
                initiallySelected: widget.selectedItems,
                onSelectionChanged: (items) {
                  setState(() {
                    widget.selectedItems = items;
                  });
                  widget.onSelectionChanged(widget.selectedItems);
                },
                closeDropdown: _toggleDropdown,
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Moving label outside the container
        Text(
          widget.labelText,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.selectedItems.isEmpty
                      ? const Text(
                        "Select...",
                        style: TextStyle(color: Colors.black54),
                      )
                      : Wrap(
                        spacing: 8,
                        runSpacing: -8,
                        children:
                            widget.selectedItems.map((item) {
                              final randomColor =
                                  colorPool[Random().nextInt(colorPool.length)];
                              return Chip(
                                backgroundColor: randomColor.withOpacity(0.2),
                                label: Text(
                                  item.name,
                                  style: TextStyle(
                                    color: randomColor,
                                    fontSize: 12.0,
                                  ),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() {
                                    widget.selectedItems.remove(item);
                                  });
                                  widget.onSelectionChanged(
                                    widget.selectedItems,
                                  );
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              );
                            }).toList(),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownPopup extends StatefulWidget {
  final List<MultiSelectItemModel> allItems;
  final List<MultiSelectItemModel> initiallySelected;
  final Function(List<MultiSelectItemModel> selectedItems) onSelectionChanged;
  final VoidCallback closeDropdown;

  const _DropdownPopup({
    required this.allItems,
    required this.initiallySelected,
    required this.onSelectionChanged,
    required this.closeDropdown,
  });

  @override
  State<_DropdownPopup> createState() => _DropdownPopupState();
}

class _DropdownPopupState extends State<_DropdownPopup> {
  late List<MultiSelectItemModel> tempSelectedItems;
  List<MultiSelectItemModel> filteredItems = [];
  TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Ensure tempSelectedItems is initialized each time the dropdown is opened
    tempSelectedItems = [...widget.initiallySelected];
    filteredItems = widget.allItems;
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        filteredItems =
            widget.allItems
                .where(
                  (item) => item.name.toLowerCase().contains(
                    searchController.text.toLowerCase(),
                  ),
                )
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filteredItems.length,
                itemExtent: 50,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];

                  // Check if the current item's name is in the selected items' names
                  final isSelected = tempSelectedItems.any(
                    (selectedItem) => selectedItem.name == item.name,
                  );

                  return ListTile(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          tempSelectedItems.remove(item);
                        } else {
                          tempSelectedItems.add(item);
                        }
                      });
                    },
                    title: Text(item.name),
                    leading: Checkbox(
                      value: isSelected,
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            tempSelectedItems.add(item);
                          } else {
                            tempSelectedItems.remove(item);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
              ),
              onPressed: () {
                widget.onSelectionChanged(tempSelectedItems);
                widget.closeDropdown();
              },

              child: const Text(
                "Done",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
