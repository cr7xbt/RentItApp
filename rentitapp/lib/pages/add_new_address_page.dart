import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:getwidget/getwidget.dart';

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
      addressLine1Controller.text = widget.address?['address_line1'] ?? '';
      addressLine2Controller.text = widget.address?['address_line2'] ?? '';
      cityController.text = widget.address?['city'] ?? '';
      stateController.text = widget.address?['state'] ?? '';
      zipCodeController.text = widget.address?['zip_code'] ?? '';
      isDefault = widget.address?['is_default'] ?? false;
    }
  }

  String? _validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Address',
          style: TextStyle(color: Colors.white), // Change text color to white
        ),
        backgroundColor: Color(0xFF078BDC), // Set title bar color to 0xFF078BDC
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GFTextField(
                  controller: addressLine1Controller,
                  decoration: InputDecoration(labelText: 'Address Line 1'),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                if (_validateField(addressLine1Controller.text, 'Address Line 1') != null)
                  Text(
                    _validateField(addressLine1Controller.text, 'Address Line 1')!,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 10),
                GFTextField(
                  controller: addressLine2Controller,
                  decoration: InputDecoration(labelText: 'Address Line 2'),
                ),
                SizedBox(height: 10),
                GFTextField(
                  controller: cityController,
                  decoration: InputDecoration(labelText: 'City'),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                if (_validateField(cityController.text, 'City') != null)
                  Text(
                    _validateField(cityController.text, 'City')!,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 10),
                GFTextField(
                  controller: stateController,
                  decoration: InputDecoration(labelText: 'State'),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                if (_validateField(stateController.text, 'State') != null)
                  Text(
                    _validateField(stateController.text, 'State')!,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 10),
                GFTextField(
                  controller: zipCodeController,
                  decoration: InputDecoration(labelText: 'Zip Code'),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                if (_validateField(zipCodeController.text, 'Zip Code') != null)
                  Text(
                    _validateField(zipCodeController.text, 'Zip Code')!,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Text('Set as default address'),
                    Switch(
                      value: isDefault,
                      onChanged: (value) {
                        setState(() {
                          isDefault = value;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                GFButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final supabaseClient = Supabase.instance.client;
                      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

                      if (firebaseUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No user is currently signed in.')),
                        );
                        return;
                      }

                      try {
                        if (isDefault) {
                          await supabaseClient
                              .from('addresses')
                              .update({'is_default': false})
                              .eq('user_email', firebaseUser.email)
                              .execute();
                        }

                        await supabaseClient.from('addresses').insert({
                          'user_email': firebaseUser.email,
                          'address_line1': addressLine1Controller.text,
                          'address_line2': addressLine2Controller.text,
                          'city': cityController.text,
                          'state': stateController.text,
                          'zip_code': zipCodeController.text,
                          'is_default': isDefault,
                        }).execute();

                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save address: $e')),
                        );
                      }
                    }
                  },
                  text: 'Save Address',
                  blockButton: true,
                  color: Color(0xFFF5895A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}