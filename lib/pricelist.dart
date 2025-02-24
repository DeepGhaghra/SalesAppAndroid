import 'package:flutter/material.dart';

class PriceListScreen extends StatefulWidget {
  const PriceListScreen({super.key});

  @override
  _PriceListScreenState createState() => _PriceListScreenState();
}

class _PriceListScreenState extends State<PriceListScreen> {
  final Map<String, double> priceList = {
    'Party A - Product X': 100.0,
    'Party A - Product Z': 120.0,
    'Party A - Product Y': 330.0,
    'Party B - Product Y': 150.0,
    'Party B - Product X': 250.0,
    'Party C - Product X': 145.0,
    'Party C - Product Y': 115.0,
    'Party C - Product Z': 145.0,
  };

  String searchQuery = '';

  List<MapEntry<String, double>> get filteredPriceList {
    return priceList.entries
        .where(
          (entry) =>
              entry.key.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // Sort alphabetically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Price List"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: PriceListSearch(priceList: priceList),
              );
            },
          ),
        ],
      ),
      body:
          priceList.isEmpty
              ? Center(
                child: Text(
                  "No prices available",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.builder(
                itemCount: filteredPriceList.length,
                itemBuilder: (context, index) {
                  final entry = filteredPriceList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(entry.key),
                      subtitle: Text("Price: ₹${entry.value.toString()}"),
                      trailing: Icon(Icons.attach_money, color: Colors.green),
                    ),
                  );
                },
              ),
    );
  }
}

class PriceListSearch extends SearchDelegate<String> {
  final Map<String, double> priceList;

  PriceListSearch({required this.priceList});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null!);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredList =
        priceList.entries
            .where(
              (entry) => entry.key.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final entry = filteredList[index];
        return ListTile(
          title: Text(entry.key),
          subtitle: Text("Price: ₹${entry.value.toString()}"),
          onTap: () {
            close(context, entry.key);
          },
        );
      },
    );
  }
}
