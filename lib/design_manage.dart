import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'utils/sync_utils.dart';
import 'db_help.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StockManageScreen extends StatefulWidget {
  final bool isOnline;

  const StockManageScreen({super.key, required this.isOnline});

  @override
  _StockManageScreenState createState() => _StockManageScreenState();
}

class _StockManageScreenState extends State<StockManageScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<String> designs = [];
  List<String> filteredList = [];
  TextEditingController searchController = TextEditingController();
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadDesign();
    _subscribeToRealtimeUpdates(); // ✅ Listen for live updates
    Connectivity().onConnectivityChanged.listen((connectivityResult) async {
      setState(() {
        isOnline = connectivityResult != ConnectivityResult.none;
      });
      if (isOnline) _syncFromSupabase();
    });
  }

  Future<void> _loadDesign() async {
    if (kIsWeb) {
      // Web: Fetch directly from Supabase (no caching)
      await _syncFromSupabase();
      return;
    }
    await _loadCachedDesigns(); // ✅ Ensure it runs before fetching online
    if (isOnline) {
      await _syncFromSupabase();
    } else {}
  }

  void _subscribeToRealtimeUpdates() {
    if (!isOnline) return; // ✅ Only subscribe when online

    supabase
        .channel('public:products_design')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'products_design',
          callback: (payload) {
            // ✅ Re-fetch design when a change is detected
            _syncFromSupabase();
          },
        )
        .subscribe();
  }

  Future<void> _syncFromSupabase() async {
    try {
      final response = await supabase
          .from('products_design')
          .select('design_no, product_head_id');
      List<Map<String, dynamic>> cloudDesigns = List<Map<String, dynamic>>.from(
        response,
      );
      cloudDesigns.sort(
        (a, b) => (a['design_no'] as String).toLowerCase().compareTo(
          (b['design_no'] as String).toLowerCase(),
        ),
      );

      setState(() {
        designs = cloudDesigns.map((d) => d['design_no'] as String).toList();
        filteredList = List.from(designs);
      });

      if (!kIsWeb) {
        await DatabaseHelper.instance.cachedDesigns(cloudDesigns);
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> _loadCachedDesigns() async {
    if (kIsWeb) return; // Web fetches directly from Supabase

    List<Map<String, dynamic>> cachedDesigns =
        await DatabaseHelper.instance.getCachedDesigns();
    List<Map<String, dynamic>> mutableList = List<Map<String, dynamic>>.from(
      cachedDesigns,
    );

    mutableList.sort(
      (a, b) => (a['design_no'] as String).toLowerCase().compareTo(
        (b['design_no'] as String).toLowerCase(),
      ),
    );

    setState(() {
      designs = mutableList.map((d) => d['design_no'] as String).toList();
      filteredList = List.from(designs);
    });
  }

  Future<void> _addDesign(
    String newDesign,
    String productHeadId,
    BuildContext dialogContext,
  ) async {
    newDesign = newDesign.trim();
    if (newDesign.isEmpty || productHeadId.isEmpty) {
      Fluttertoast.showToast(
        msg: "⚠️ Please enter design and select a product!",
      );
      return;
    }
    String newDesignLower = newDesign.toLowerCase();
    List<String> lowerCaseDesign = designs.map((p) => p.toLowerCase()).toList();

    if (lowerCaseDesign.contains(newDesignLower)) {
      Fluttertoast.showToast(msg: "⚠️ Design '$newDesign' already exists!");
      return;
    }
    if (!widget.isOnline) {
      Fluttertoast.showToast(msg: "📶 No Internet! Cannot add design.");
      return;
    }

    try {
      await supabase.from('products_design').insert({
        'design_no': newDesign,
        'product_head_id': int.parse(productHeadId),
      });
      setState(() {
        designs.add(newDesign);
        filteredList.add(newDesign);
        designs.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      });

      Fluttertoast.showToast(msg: "✅ Design '$newDesign' added successfully!");
      Navigator.pop(dialogContext);
      await _syncFromSupabase();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error adding Design.");
    }
  }

  Future<void> _editDesign(int index) async {
    if (!widget.isOnline) {
      Fluttertoast.showToast(msg: "📶 No Internet! Cannot edit design.");
      return;
    }

    String oldName = filteredList[index];
    TextEditingController designController = TextEditingController(
      text: oldName,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Design"),
          content: TextField(controller: designController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedName = designController.text.trim();
                if (updatedName.isEmpty || updatedName == oldName) return;
                // ✅ Case-insensitive check
                String updatedNameLower = updatedName.toLowerCase();
                List<String> lowerCaseParties =
                    designs.map((p) => p.toLowerCase()).toList();

                if (lowerCaseParties.contains(updatedNameLower) &&
                    updatedNameLower != oldName.toLowerCase()) {
                  Fluttertoast.showToast(
                    msg: "⚠️ Design '$updatedName' already exists!",
                  );
                  return;
                }
                try {
                  await supabase
                      .from('products_design')
                      .update({'design_no': updatedName})
                      .eq('design_no', oldName);

                  setState(() {
                    designs[index] = updatedName;
                    filteredList[index] = updatedName;
                    designs.sort(
                      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
                    );
                  });

                  Fluttertoast.showToast(msg: "✅ Design updated successfully!");
                  await _syncFromSupabase();
                  Navigator.pop(context);
                } catch (e) {
                  Fluttertoast.showToast(msg: "Error updating design.");
                }
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _filterDesigns(String query) {
    setState(() {
      filteredList =
          designs
              .where(
                (design) => design.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _showAddDesignDialog() {
    TextEditingController designController = TextEditingController();
    String? selectedProductHeadId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Design"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: designController,
                decoration: InputDecoration(labelText: "Design Number"),
              ),
              SizedBox(height: 10),

              // 🔹 Use FutureBuilder to Load Product Heads
              FutureBuilder(
                future: supabase
                    .from('product_head')
                    .select('id, product_name'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    ); // Loading indicator
                  }
                  if (snapshot.hasError) {
                    return Text("Error loading products");
                  }
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      (snapshot.data as List).isEmpty) {
                    return Text("No products found.");
                  }

                  List<Map<String, dynamic>> productHeadList =
                      List<Map<String, dynamic>>.from(snapshot.data as List);

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: selectedProductHeadId,
                    hint: Text("Select Product Head"),
                    items:
                        productHeadList.map((product) {
                          return DropdownMenuItem<String>(
                            value: product['id'].toString(),
                            child: Text(product['product_name']),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => selectedProductHeadId = value);
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProductHeadId != null) {
                  _addDesign(
                    designController.text.trim(),
                    selectedProductHeadId!,
                    context,
                  );
                } else {
                  Fluttertoast.showToast(msg: "⚠️ Please select a product!");
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Designs List")),
      body: Column(
        children: [
          if (!isOnline) // 🔴 Show a message when offline
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.redAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "You are offline! Showing cached data.",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search Design....",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterDesigns,
            ),
          ),
          Expanded(
            child:
                (designs.isEmpty && !isOnline && !kIsWeb)
                    ? Center(
                      child: Text(
                        "You are offline. No cached data available.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final design = filteredList[index];
                        return FutureBuilder(
                          future:
                              supabase
                                  .from('products_design')
                                  .select('product_head_id')
                                  .eq('design_no', design)
                                  .maybeSingle(),
                          builder: (context, designSnapshot) {
                            if (!designSnapshot.hasData ||
                                designSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                child: ListTile(
                                  title: Text(design),
                                  leading: Icon(
                                    Icons.view_list,
                                    color: Colors.blue,
                                  ),
                                  trailing: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (designSnapshot.hasError) {
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                child: ListTile(
                                  title: Text(design),
                                  leading: Icon(
                                    Icons.view_list,
                                    color: Colors.blue,
                                  ),
                                  trailing: Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            }

                            final productHeadId =
                                designSnapshot.data?['product_head_id'];
                            if (productHeadId == null) {
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                child: ListTile(
                                  title: Text(design),
                                  leading: Icon(
                                    Icons.view_list,
                                    color: Colors.blue,
                                  ),
                                  trailing: Text("No Product"),
                                ),
                              );
                            }

                            return FutureBuilder(
                              future:
                                  supabase
                                      .from('product_head')
                                      .select('folder_id')
                                      .eq('id', productHeadId)
                                      .maybeSingle(),
                              builder: (context, productHeadSnapshot) {
                                if (!productHeadSnapshot.hasData ||
                                    productHeadSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2,
                                    ),
                                    child: ListTile(
                                      title: Text(design),
                                      leading: Icon(
                                        Icons.view_list,
                                        color: Colors.blue,
                                      ),
                                      trailing: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final folderId =
                                    productHeadSnapshot.data?['folder_id'];
                                if (folderId == null) {
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2,
                                    ),
                                    child: ListTile(
                                      title: Text(design),
                                      leading: Icon(
                                        Icons.view_list,
                                        color: Colors.blue,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("No Folder"),
                                          SizedBox(width: 8),
                                          if (widget.isOnline)
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: Colors.green,
                                              ),
                                              onPressed:
                                                  () => _editDesign(index),
                                            )
                                          else
                                            Icon(
                                              Icons.lock,
                                              color: Colors.grey,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return FutureBuilder(
                                  future:
                                      supabase
                                          .from('folders')
                                          .select('folder_name')
                                          .eq('id', folderId)
                                          .maybeSingle(),
                                  builder: (context, folderSnapshot) {
                                    final folderName =
                                        folderSnapshot.data?['folder_name'] ??
                                        "Unknown Folder";

                                    return Card(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 2,
                                      ),
                                      child: ListTile(
                                        title: Text(design),
                                        leading: Icon(
                                          Icons.view_list,
                                          color: Colors.blue,
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(folderName),
                                            SizedBox(width: 8),
                                            if (widget.isOnline)
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  color: Colors.green,
                                                ),
                                                onPressed:
                                                    () => _editDesign(index),
                                              )
                                            else
                                              Icon(
                                                Icons.lock,
                                                color: Colors.grey,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton:
          widget.isOnline
              ? FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: _showAddDesignDialog,
              )
              : null, // 🔒 Hide add button when offline
    );
  }
}
