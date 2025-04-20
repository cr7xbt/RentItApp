import 'package:flutter/material.dart';
import '../data/states_data.dart';
import '../models/state_model.dart';
import 'shop_list_page.dart';

class StateSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select a State')),
      body: ListView.builder(
        itemCount: states.length,
        itemBuilder: (context, index) {
          StateModel state = states[index];
          return ListTile(
            leading: Image.asset(state.imagePath, width: 50, height: 50),
            title: Text(state.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ShopListPage(state: state)),
              );
            },
          );
        },
      ),
    );
  }
}