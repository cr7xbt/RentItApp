import 'package:flutter/material.dart';
import 'add_new_address_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AddressPage extends StatefulWidget {
  @override
  _AddressPageState createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      final supabaseClient = Supabase.instance.client;
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in.');
      }

      final response = await supabaseClient
          .from('addresses')
          .select()
          .eq('user_email', firebaseUser.email)
          .order('is_default', ascending: false) // Default address first
          .order('created_at', ascending: false)
          .execute();

      if (response.status != 200) {
        throw Exception('Failed to fetch addresses. Status code: ${response.status}');
      }

      setState(() {
        addresses = List<Map<String, dynamic>>.from(response.data);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching addresses: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeAddress(int addressId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final supabaseClient = Supabase.instance.client;
        await supabaseClient.from('addresses').delete().eq('address_id', addressId).execute();
        _fetchAddresses();
      } catch (e) {
        print('Error deleting address: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete address: $e')),
        );
      }
    }
  }

  void _editAddress(Map<String, dynamic> address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewAddressPage(
          address: address,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
      });
      _fetchAddresses();
    }
  }

  Future<void> _setAsDefaultAddress(int addressId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Default Address'),
        content: Text('Are you sure you want to set this address as the default?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final supabaseClient = Supabase.instance.client;
        final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (firebaseUser == null) {
          throw Exception('No user is currently signed in.');
        }

        // Unset the current default address
        await supabaseClient
            .from('addresses')
            .update({'is_default': false})
            .eq('user_email', firebaseUser.email)
            .execute();

        // Set the selected address as default
        await supabaseClient
            .from('addresses')
            .update({'is_default': true})
            .eq('address_id', addressId)
            .execute();

        // Reload addresses
        await _fetchAddresses();
      } catch (e) {
        print('Error setting default address: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set default address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Addresses'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListTile(
                  title: Text('Add a new address'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddNewAddressPage()),
                    );

                    if (result == true) {
                      setState(() {
                        isLoading = true;
                      });
                      await _fetchAddresses(); // Reload addresses after adding a new one
                    }
                  },
                ),
                Divider(),
                if (addresses.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text('No Addresses Added'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${address['address_line1']}, ${address['address_line2'] ?? ''}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text('${address['city']}, ${address['state']} ${address['zip_code']}'),
                                if (address['is_default'])
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Default Address',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!address['is_default'])
                                      TextButton(
                                        onPressed: () {
                                          _setAsDefaultAddress(address['address_id']);
                                        },
                                        child: Text('Set as Default'),
                                      ),
                                    TextButton(
                                      onPressed: () {
                                        _editAddress(address);
                                      },
                                      child: Text('Edit'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _removeAddress(address['address_id']);
                                      },
                                      child: Text('Remove'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
