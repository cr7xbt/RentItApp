import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  late GoogleMapsPlaces _places;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Google Maps API key not found in environment variables.");
    }
    _places = GoogleMapsPlaces(apiKey: apiKey);

    if (widget.address != null) {
      addressLine1Controller.text = widget.address?['address_line1'] ?? '';
      addressLine2Controller.text = widget.address?['address_line2'] ?? '';
      cityController.text = widget.address?['city'] ?? '';
      stateController.text = widget.address?['state'] ?? '';
      zipCodeController.text = widget.address?['zip_code'] ?? '';
      isDefault = widget.address?['is_default'] ?? false;
    }
  }

  Future<void> _handlePressButton() async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Google Maps API key not found in environment variables.");
    }

    Prediction? p = await PlacesAutocomplete.show(
      context: context,
      apiKey: apiKey,
      mode: Mode.overlay,
      language: "en",
      components: [Component(Component.country, "us")],
    );

    if (p != null && p.placeId != null) {
      PlacesDetailsResponse detail = await _places.getDetailsByPlaceId(p.placeId!);
      final result = detail.result;

      setState(() {
        String streetNumber = '';
        String route = '';

        for (var component in result.addressComponents) {
          final types = component.types;
          if (types.contains('street_number')) {
            streetNumber = component.longName;
          } else if (types.contains('route')) {
            route = component.longName;
          } else if (types.contains('locality')) {
            cityController.text = component.longName;
          } else if (types.contains('administrative_area_level_1')) {
            stateController.text = component.longName;
          } else if (types.contains('postal_code')) {
            zipCodeController.text = component.longName;
          }
        }

        addressLine1Controller.text = streetNumber.isNotEmpty && route.isNotEmpty
            ? '$streetNumber $route'
            : route;
      });
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
                readOnly: true,
                onTap: _handlePressButton,
                decoration: InputDecoration(
                  labelText: 'Address Line 1',
                  suffixIcon: Icon(Icons.search),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an address';
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