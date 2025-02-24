import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PartyListScreen extends StatefulWidget {
  @override
  _PartyListScreenState createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  List<String> partyList = [];
  List<String> filteredList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedParties = prefs.getStringList('party_list');

    if (savedParties != null) {
      setState(() {
        partyList = savedParties;
        filteredList = List.from(partyList);
      });
    }
  }

  Future<void> _saveParties() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('party_list', partyList);
  }

  void _addParty() {
    TextEditingController partyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Party"),
          content: TextField(
            controller: partyController,
            decoration: InputDecoration(hintText: "Enter Party Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newParty = partyController.text.trim();
                if (newParty.isNotEmpty && !partyList.contains(newParty)) {
                  setState(() {
                    partyList.add(newParty);
                    filteredList.add(newParty);
                    _saveParties();
                  });
                  Navigator.pop(context, true); // Notify Sales Entry Page
                } else {
                  Navigator.pop(context, false); // No change
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _filterParties(String query) {
    setState(() {
      filteredList =
          partyList
              .where(
                (party) => party.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Party List"),
        actions: [IconButton(icon: Icon(Icons.add), onPressed: _addParty)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search Party",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterParties,
            ),
          ),
          Expanded(
            child:
                filteredList.isEmpty
                    ? Center(child: Text("No parties available"))
                    : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(filteredList[index]),
                            leading: Icon(Icons.person, color: Colors.blue),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
