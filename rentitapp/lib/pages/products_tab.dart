import 'package:flutter/material.dart';

class ProductsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy data for product types with icons
    final List<Map<String, dynamic>> productTypes = [
      {'name': 'Home Decor', 'icon': Icons.home},
      {'name': 'Kitchen', 'icon': Icons.kitchen},
      {'name': 'Embroidery', 'icon': Icons.format_paint},
      {'name': 'Books', 'icon': Icons.book},
      // Add more product types here
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 3/2, // Aspect ratio of the grid items to make them square
        ),
        itemCount: productTypes.length,
        itemBuilder: (context, index) {
          final productType = productTypes[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Rounded edges
            ),
            elevation: 4.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    productType['icon'],
                    size: 40, // Adjust the size as needed
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    productType['name']!,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}