import 'package:flutter/material.dart';
import '../data/states_data.dart';
import '../models/state_model.dart';
import 'shop_list_page.dart';

class StateSelectionPage extends StatefulWidget {
  @override
  _StateSelectionPageState createState() => _StateSelectionPageState();
}

class _StateSelectionPageState extends State<StateSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<StateModel> _filteredStates = states;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStates = states;
      } else {
        _filteredStates = states
            .where((state) => state.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search States',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredStates.length,
              itemBuilder: (context, index) {
                final state = _filteredStates[index];
                return ListTile(
                  leading: Image.asset(state.imagePath, width: 50, height: 50),
                  title: Text(state.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopListPage(state: state),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}