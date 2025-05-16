import 'dart:async';
import 'package:flutter/material.dart';

class Item {
  final String id;
  final String name;
  bool isSelected;

  Item({required this.id, required this.name, this.isSelected = false});

  set value(Null value) {}
}

class SearchableDropdown extends StatefulWidget {
  final List<Item> items;
  Item? selectedItem;

  final void Function(Item selectedItem) onItemSelected;
  final String hintText;
  final String labelText; // <-- new label

  SearchableDropdown({
    Key? key,
    required this.items,
    this.selectedItem,
    required this.onItemSelected,
    this.hintText = "Please select an option",
    this.labelText = "Please select an option", // default label
  }) : super(key: key);

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  Item? selectedItem;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
    selectedItem = widget.selectedItem;
  }

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlay();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: MediaQuery.of(context).size.width - 30,
            child: CompositedTransformFollower(
              offset: const Offset(0, 55), // Adjusted to fit label + container
              link: _layerLink,
              showWhenUnlinked: false,
              child: _DropdownPopup(
                items: widget.items,
                onItemSelected: (item) {
                  setState(() {
                    selectedItem = item;
                  });
                  widget.onItemSelected(item);
                  _toggleDropdown();
                },
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // label start
      children: [
        Text(
          widget.labelText,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedItem?.name ?? widget.hintText,
                    style: TextStyle(
                      color: selectedItem != null ? Colors.black : Colors.grey,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
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
  final List<Item> items;
  final void Function(Item item) onItemSelected;

  const _DropdownPopup({required this.items, required this.onItemSelected});

  @override
  State<_DropdownPopup> createState() => _DropdownPopupState();
}

class _DropdownPopupState extends State<_DropdownPopup> {
  late List<Item> filteredItems;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        if (value.isEmpty) {
          filteredItems = widget.items;
        } else {
          filteredItems =
              widget.items
                  .where(
                    (item) =>
                        item.name.toLowerCase().contains(value.toLowerCase()),
                  )
                  .toList();
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filteredItems.length,
                itemExtent: 60, // <-- fixed height, makes huge list fast
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return Column(
                    children: [
                      ListTile(
                        title: Text(item.name, overflow: TextOverflow.ellipsis),
                        onTap: () => widget.onItemSelected(item),
                      ),
                      const Divider(height: 1),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
