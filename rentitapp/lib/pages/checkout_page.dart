import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'order_completion_page.dart';
import '../models/shop_item_model.dart'; // Assuming this is the model for your shop items
import 'package:provider/provider.dart' as provider;
import '../models/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class CheckoutPage extends StatefulWidget {
  final List<ShopItemModel> orderItems; // Changed to ShopItemModel type
  final double totalAmount;

  CheckoutPage({required this.orderItems, required this.totalAmount});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!; // Load Stripe publishable key from .env
  }

  Future<void> _startPayment() async {
    try {
      // Call your backend to create a Payment Intent
      final response = await http.post(
        Uri.parse(dotenv.env['BACKEND_URL']! + 'create-payment-intent'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': widget.totalAmount.toInt(), // Amount in the smallest currency unit
          'currency': 'usd',
        }),
      );

      print("Response from backend: ${response.body}");
      final clientSecret = jsonDecode(response.body)['clientSecret'];

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'RentItApp',
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Save order to Supabase
      await _saveOrderToSupabase();

      // Navigate to Order Completion Page with order summary
      provider.Provider.of<CartProvider>(context, listen: false).clearCart(); // Clear the cart after order completion
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderCompletionPage(
            items: widget.orderItems.map((item) => {
              'name': item.name,
              'quantity': item.quantity,
              'price': item.price,
            }).toList(),
            totalAmount: widget.totalAmount,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  Future<void> _saveOrderToSupabase() async {
    try {
      final supabaseClient = Supabase.instance.client;
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in.');
      }

      for (var item in widget.orderItems) {
        await supabaseClient.from('orders').insert({
          'user_email': firebaseUser.email,
          'item_id': item.itemId,
          'quantity': item.quantity,
          'total_price': item.price * item.quantity,
          'order_status': 'Pending',
        }).execute();
      }
    } catch (e) {
      print('Error saving order to Supabase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                items: [
                  DropdownMenuItem(
                    value: 'Credit Card',
                    child: Text('Credit Card'),
                  ),
                  DropdownMenuItem(
                    value: 'Debit Card',
                    child: Text('Debit Card'),
                  ),
                  DropdownMenuItem(
                    value: 'Cash on Delivery',
                    child: Text('Cash on Delivery'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a payment method',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a payment method';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange, // Saffron color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedPaymentMethod == 'Cash on Delivery') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order placed successfully!')),
                        );
                      } else {
                        _startPayment();
                      }
                    }
                  },
                  child: Text(
                    'Place Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}