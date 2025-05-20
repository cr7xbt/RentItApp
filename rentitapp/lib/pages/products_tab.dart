import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';

class ProductsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> productTypes = [
      {'name': 'Home Decor', 'icon': Icons.home, 'color': Colors.blue, 'items': '150+ items'},
      {'name': 'Kitchen', 'icon': Icons.kitchen, 'color': Colors.green, 'items': '200+ items'},
      {'name': 'Embroidery', 'icon': Icons.format_paint, 'color': Colors.orange, 'items': '120+ items'},
      {'name': 'Books', 'icon': Icons.book, 'color': Colors.purple, 'items': '300+ items'},
    ];

    final List<Map<String, dynamic>> popularProducts = [
      {
        'name': 'Ceramic Cup',
        'state': 'Gujarat',
        'image': 'https://lopugfofldvdgnnxmmok.supabase.co/storage/v1/object/public/shop-items//ceramic_cup.png'
      },
      {
        'name': 'Madhubani Painting',
        'state': 'Kerala',
        'image': 'https://lopugfofldvdgnnxmmok.supabase.co/storage/v1/object/public/shop-items//madhubani_2.png'
      },
      {
        'name': 'Tribal Mask',
        'state': 'Gujarat',
        'image': 'https://lopugfofldvdgnnxmmok.supabase.co/storage/v1/object/public/shop-items//tribal_mask.png'
      },
    ];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Search Products',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 6 / 5.2, // Increased width and height by 20%
              ),
              itemCount: productTypes.length,
              itemBuilder: (context, index) {
                final productType = productTypes[index];
                return GFCard(
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: productType['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          productType['icon'],
                          color: productType['color'],
                          size: 28, // Smaller icon
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        productType['name'],
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        productType['items'],
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            GFTypography(
              text: 'Popular Products',
              type: GFTypographyType.typo1,
              showDivider: false,
            ),
            SizedBox(height: 16),
            GFCarousel(
              items: popularProducts.map((product) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                product['image'],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          product['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            SizedBox(width: 4),
                            Text(
                              product['state'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              autoPlay: false,
              viewportFraction: 0.5, // Two cards per row
            ),
          ],
        ),
      ),
    );
  }
}