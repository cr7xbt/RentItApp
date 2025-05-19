import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressInputPage extends StatefulWidget {
  @override
  _AddressInputPageState createState() => _AddressInputPageState();
}

class _AddressInputPageState extends State<AddressInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  String? _recommendedAddress;
  String? _recommendedState; // Store the state from the recommended address
  double? _latitude; // Store latitude
  double? _longitude; // Store longitude
  
  static const kGoogleApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY'); // Set via --dart-define

  Future<void> _fetchRecommendedAddress() async {
    final address =
        '${_streetController.text}, ${_cityController.text}, ${_stateController.text}, ${_zipCodeController.text}';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$kGoogleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          _recommendedAddress = data['results'][0]['formatted_address'];
          _latitude = data['results'][0]['geometry']['location']['lat']; // Extract latitude
          _longitude = data['results'][0]['geometry']['location']['lng']; // Extract longitude

          // Extract state from the address components
          final addressComponents = data['results'][0]['address_components'];
          for (var component in addressComponents) {
            if (component['types'].contains('administrative_area_level_1')) {
              _recommendedState = component['long_name']; // Extract state name
              break;
            }
          }
        });
      } else {
        setState(() {
          _recommendedAddress = null;
          _latitude = null;
          _longitude = null;
          _recommendedState = null;
        });
      }
    } else {
      setState(() {
        _recommendedAddress = null;
        _latitude = null;
        _longitude = null;
        _recommendedState = null;
      });
    }
  }

  Future<void> _showAddressConfirmationDialog() async {
    await _fetchRecommendedAddress();

    if (_recommendedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch recommended address.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Entered Address:'),
              Text(
                '${_streetController.text}, ${_cityController.text}, ${_stateController.text}, ${_zipCodeController.text}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Recommended Address:'),
              Text(
                _recommendedAddress!,
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(
                  context,
                  {
                    'address': '${_streetController.text}, ${_cityController.text}, ${_stateController.text}, ${_zipCodeController.text}',
                    'state': _stateController.text, // Return entered state
                    'latitude': null,
                    'longitude': null,
                  },
                ); // Return entered address without lat/lng
              },
              child: Text('Use Entered Address'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(
                  context,
                  {
                    'address': _recommendedAddress,
                    'state': _recommendedState, // Return recommended state
                    'latitude': _latitude,
                    'longitude': _longitude,
                  },
                ); // Return recommended address with lat/lng
              },
              child: Text('Use Recommended Address'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Address')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the street';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the city';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the state';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _zipCodeController,
                decoration: InputDecoration(
                  labelText: 'Zip Code',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the zip code';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _showAddressConfirmationDialog();
                  }
                },
                child: Text('Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}