import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class AddNewAddressPage extends StatefulWidget {
  final Map<String, dynamic>? address;

  AddNewAddressPage({this.address});

  @override
  _AddNewAddressPageState createState() => _AddNewAddressPageState();
}

class _AddNewAddressPageState extends State<AddNewAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController addressLine1Controller = TextEditingController();
  final TextEditingController addressLine2Controller = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      addressLine1Controller.text = widget.address!['address_line1'] ?? '';
      addressLine2Controller.text = widget.address!['address_line2'] ?? '';
      cityController.text = widget.address!['city'] ?? '';
      stateController.text = widget.address!['state'] ?? '';
      zipCodeController.text = widget.address!['zip_code'] ?? '';
      isDefault = widget.address!['is_default'] ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: addressLine1Controller,
                decoration: InputDecoration(labelText: 'Address Line 1'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Address Line 1';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: addressLine2Controller,
                decoration: InputDecoration(labelText: 'Address Line 2'),
              ),
              TextFormField(
                controller: cityController,
                decoration: InputDecoration(labelText: 'City'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter City';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: stateController,
                decoration: InputDecoration(labelText: 'State'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter State';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: zipCodeController,
                decoration: InputDecoration(labelText: 'Zip Code'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Zip Code';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Checkbox(
                    value: isDefault,
                    onChanged: (value) {
                      setState(() {
                        isDefault = value ?? false;
                      });
                    },
                  ),
                  Text('Set as Default Address'),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final supabaseClient = Supabase.instance.client;
                      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

                      if (firebaseUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No user is currently signed in.')),
                        );
                        return;
                      }

                      try {
                        // If the address is marked as default, unset other default addresses
                        if (isDefault) {
                          await supabaseClient
                              .from('addresses')
                              .update({'is_default': false})
                              .eq('user_email', firebaseUser.email)
                              .execute();
                        }

                        // Insert the new address
                        await supabaseClient.from('addresses').insert({
                          'user_email': firebaseUser.email,
                          'address_line1': addressLine1Controller.text,
                          'address_line2': addressLine2Controller.text,
                          'city': cityController.text,
                          'state': stateController.text,
                          'zip_code': zipCodeController.text,
                          'is_default': isDefault,
                        }).execute();

                        Navigator.pop(context, true); // Return true to indicate success
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save address: $e')),
                        );
                      }
                    }
                  },
                  child: Text('Save Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
