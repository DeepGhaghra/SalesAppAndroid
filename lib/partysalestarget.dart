import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drop_down_list/model/selected_list_item.dart';
import 'package:drop_down_list/drop_down_list.dart';

class PartySalesTargetScreen extends StatefulWidget {
  const PartySalesTargetScreen({super.key});

  @override
  _PartySalesTargetScreenState createState() => _PartySalesTargetScreenState();
}

class _PartySalesTargetScreenState extends State<PartySalesTargetScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();

  String? _selectedPartyId;
  String? _selectedPartyName;
  int? _editingYear;
  bool _isLoading = true;
  List<Map<String, dynamic>> _parties = [];
  List<Map<String, dynamic>> _targets = [];
  Map<String, String> partyMap = {}; // partyName -> partyID

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final parties = await supabase.from('parties').select('id, partyname');
      final targets = await supabase
          .from('sales_targets')
          .select('*, parties(partyname)')
          .order('year', ascending: false);

      setState(() {
        _parties = parties;
        _targets = targets;
        partyMap = {};
        for (var party in _parties) {
          partyMap[party['partyname']] = party['id'].toString();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  void _showPartyDropDown(BuildContext context) {
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loading parties, please wait...")),
      );
      return;
    }
    if (_parties.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No parties available")));
      return;
    }

    List<SelectedListItem<String>> partyItems =
        _parties.map((party) {
          return SelectedListItem<String>(data: party['partyname']);
        }).toList();

    DropDownState(
      dropDown: DropDown(
        data: partyItems,
        bottomSheetTitle: const Text(
          "Select Party",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        isDismissible: true,
        searchHintText: "Search Party...",
        onSelected: (List<SelectedListItem<String>> selectedList) {
          if (selectedList.isNotEmpty) {
            String selectedName = selectedList.first.data;
            String selectedID = partyMap[selectedName] ?? "0";

            setState(() {
              _selectedPartyId = selectedID;
              _selectedPartyName = selectedName;
            });

            Future.microtask(() {
              setState(() {}); // Ensures UI rebuilds
            });
          }
        },
      ),
    ).showModal(context);
  }

  Future<void> addOrUpdateTarget(
    String partyId,
    int year,
    double targetAmount,
  ) async {
    try {
      // Check if target already exists
      final existing = await supabase
          .from('sales_targets')
          .select()
          .eq('party_id', partyId)
          .eq('year', year);

      if (existing.isEmpty) {
        await supabase.from('sales_targets').insert({
          'party_id': partyId,
          'year': year,
          'target_amount': targetAmount,
        });
      } else {
        await supabase
            .from('sales_targets')
            .update({'target_amount': targetAmount})
            .eq('party_id', partyId)
            .eq('year', year);
      }
      await _loadData(); // Refresh data after update
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving target: $e')));
    }
  }

  Future<double> fetchSalesProgress(String partyId, int year) async {
    try {
      // Financial year runs from April 1 to March 31
      int startYear = (DateTime.now().month >= 4) ? year : year - 1;
      DateTime startDate = DateTime(startYear, 4, 1); // April 1 of that year
      DateTime endDate = DateTime(startYear + 1, 3, 31);

      debugPrint(
        'Fetching sales for party $partyId from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      );
      String startDateStr = DateFormat('dd-MM-yyyy').format(startDate);
      String endDateStr = DateFormat('dd-MM-yyyy').format(endDate);

      final sales = await supabase
          .from('sales_entries')
          .select('amount')
          .eq('party_id', partyId)
          .gte('date', startDateStr)
          .lte('date', endDateStr);

      debugPrint('Found ${sales.length} sales entries for party $partyId');

      if (sales.isEmpty) {
        debugPrint('No sales found for party $partyId in year $year');
        return 0.0;
      }
      double total = 0.0;
      for (var sale in sales) {
        debugPrint(
          'Sale entry: ${sale['id']} - Amount: ${sale['amount']} - Date: ${sale['date']}',
        );
        // Handle different possible amount formats
        if (sale['amount'] is int) {
          total += sale['amount'].toDouble();
        } else if (sale['amount'] is double) {
          total += sale['amount'];
        } else if (sale['amount'] is String) {
          total += double.tryParse(sale['amount']) ?? 0.0;
        }
      }
      debugPrint('Total sales for party $partyId: $total');

      return total;
    } catch (e) {
      return 0.0;
    }
  }

  void _showAddTargetDialog() {
    _targetController.clear();
    _yearController.text = DateTime.now().year.toString();
    _selectedPartyId = null;
    _selectedPartyName = null;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Add New Target'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap:
                            _isLoading || _parties.isEmpty
                                ? () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Loading parties, please wait...",
                                        ),
                                      ),
                                    )
                                : () => _showPartyDropDown(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedPartyName ?? "Select Party",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Year'),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Target Amount'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => _verifyAdmin(context),
                    child: Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _verifyAdmin(BuildContext dialogContext) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Admin Authentication'),
            content: TextField(
              controller: _adminPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Admin Password'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (_adminPasswordController.text == 'admin123') {
                    Navigator.pop(context); // Close password dialog
                    Navigator.pop(dialogContext); // Close add dialog
                    await _saveTarget();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Incorrect Password')),
                    );
                  }
                  _adminPasswordController.clear();
                },
                child: Text('Verify'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveTarget() async {
    if (_selectedPartyId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a party')));
      return;
    }

    final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
    final target = double.tryParse(_targetController.text) ?? 0.0;

    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    await addOrUpdateTarget(_selectedPartyId!, year, target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Party Sales Targets')),
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
          onPressed: _showAddTargetDialog,
          child: Icon(Icons.add),
        ),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _targets.isEmpty
              ? Center(child: Text('No targets set yet'))
              : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  itemCount: _targets.length,
                  itemBuilder: (context, index) {
                    final target = _targets[index];
                    final partyName =
                        target['parties']?['partyname'] ??
                        'Party ${target['party_id']}';

                    return FutureBuilder<double>(
                      future: fetchSalesProgress(
                        target['party_id'].toString(),
                        target['year'],
                      ),
                      builder: (context, progressSnapshot) {
                        double progress = progressSnapshot.data ?? 0.0;
                        double targetAmount = target['target_amount'] ?? 0.0;
                        double percentage =
                            targetAmount > 0
                                ? (progress / targetAmount).clamp(0.0, 1.0)
                                : 0.0;

                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text('$partyName - ${target['year']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target: ₹${targetAmount.toStringAsFixed(2)}',
                                ),
                                SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation(
                                    percentage >= 1.0
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),

                                SizedBox(height: 4),
                                Text(
                                  'Achieved: ₹${progress.toStringAsFixed(2)} '
                                  '(${(percentage * 100).toStringAsFixed(1)}%)',
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showEditDialog(target),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
    );
  }

  void _showEditDialog(Map<String, dynamic> target) {
    _selectedPartyId = target['party_id'].toString();
    _selectedPartyName = target['parties']?['partyname'];
    _targetController.text = target['target_amount']?.toString() ?? '';
    _yearController.text =
        target['year']?.toString() ?? DateTime.now().year.toString();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Target'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Party'),
                    subtitle: Text(_selectedPartyName ?? 'Unknown'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Year'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Target Amount'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => _verifyAdmin(context),
                child: Text('Save'),
              ),
            ],
          ),
    );
  }
}
