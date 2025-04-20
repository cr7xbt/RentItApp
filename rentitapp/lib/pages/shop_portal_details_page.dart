import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'address_input_page.dart';
import 'dart:io';

class ShopPortalDetailsPage extends StatefulWidget {
  @override
  _ShopPortalDetailsPageState createState() => _ShopPortalDetailsPageState();
}

class _ShopPortalDetailsPageState extends State<ShopPortalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  String? _address; // Store the selected address
  String? _state; // Store the state
  double? _latitude; // Store the latitude
  double? _longitude; // Store the longitude
  TimeOfDay? _startTime; // Store the selected start time
  TimeOfDay? _endTime; // Store the selected end time
  File? _selectedImage; // Store the selected image
  String? _imageUrl; // Store the uploaded image URL

  final SupabaseClient supabase = Supabase.instance.client;

  void _navigateToAddressPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressInputPage(), // Navigate to the address input page
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _address = result['address']; // Update the address
        _state = result['state']; // Update the state
        _latitude = result['latitude']; // Update the latitude
        _longitude = result['longitude']; // Update the longitude
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToSupabase(File image) async {
    try {
      final fileName = 'shop_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String filePath = await supabase.storage
          .from('shop-images')
          .upload(fileName, image);

      final String publicUrl = supabase.storage
          .from('shop-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitShopData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    try {
      final imageUrl = await _uploadImageToSupabase(_selectedImage!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image')),
        );
        return;
      }

      // **** Fixed: treat the response as List directly
      final response = await supabase.from('shops').insert({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'contact_number': _contactNumberController.text,
        'email': _emailController.text,
        'location': _address,
        'state': _state,
        'latitude': _latitude,
        'longitude': _longitude,
        'opening_hours': 'Mon-Sat: ${_startTime?.format(context)} - ${_endTime?.format(context)}',
        'image_url': imageUrl,
      }).select();

      if (response.isNotEmpty) { // **** Updated: check if list has rows
        Navigator.pop(context, {
          'name': _nameController.text,
          'description': _descriptionController.text,
          'city': _address?.split(',').first ?? '',
          'state': _state,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert shop')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add shop: $e')),
      );
      print('Error adding shop: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Portal Details'), // Updated title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Shop Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the shop name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                minLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contactNumberController,
                decoration: InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the contact number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              if (_address != null) ...[
                Text(
                  'Address:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _address!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
              ],
              if (_state != null) ...[
                Text(
                  'State:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  _state!,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _navigateToAddressPage,
                child: Text('Add New Address'),
              ),
              SizedBox(height: 16),
              Text(
                'Operational Hours',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, true),
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _startTime != null
                              ? _startTime!.format(context)
                              : 'Start Time',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, false),
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          _endTime != null
                              ? _endTime!.format(context)
                              : 'End Time',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (_selectedImage != null)
                Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Upload Photo'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitShopData,
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}