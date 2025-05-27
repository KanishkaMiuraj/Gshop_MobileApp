import 'package:flutter/material.dart';
import 'add_product_page.dart';
import 'login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late Future<List<Map<String, dynamic>>> _categoryProductFuture;

  // Maps to track quantity edits and update button visibility per product ID
  Map<String, int> _editedQuantities = {};
  Map<String, bool> _showUpdateButton = {};

  @override
  void initState() {
    super.initState();
    _categoryProductFuture = _fetchProductsByCategory();
  }

  Future<List<Map<String, dynamic>>> _fetchProductsByCategory() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select('id, name, products(id, name, quantity)')
          .order('name');

      // Reset state when data is fetched
      _editedQuantities.clear();
      _showUpdateButton.clear();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  void _refreshProductList() {
    setState(() {
      _categoryProductFuture = _fetchProductsByCategory();
    });
  }

  void _incrementQuantity(String productId) {
    setState(() {
      _editedQuantities[productId] = (_editedQuantities[productId] ?? 0) + 1;
      _showUpdateButton[productId] = true;
    });
  }

  void _decrementQuantity(String productId) {
    setState(() {
      if ((_editedQuantities[productId] ?? 0) > 0) {
        _editedQuantities[productId] = (_editedQuantities[productId] ?? 0) - 1;
        _showUpdateButton[productId] = true;
      }
    });
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    try {
      await Supabase.instance.client
          .from('products')
          .update({'quantity': newQuantity})
          .eq('id', productId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated')),
      );

      _refreshProductList();
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stock')),
      );
    }
  }

  Widget _buildQuantityControl({
    required String productId,
    required int originalQuantity,
    required bool isKg,
  }) {
    // Initialize if not already
    if (!_editedQuantities.containsKey(productId)) {
      _editedQuantities[productId] = originalQuantity;
    }

    final editedQuantity = _editedQuantities[productId]!;

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: () => _decrementQuantity(productId),
        ),
        Text(
          '$editedQuantity${isKg ? ' Kg' : ''}',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _incrementQuantity(productId),
        ),
        if (_showUpdateButton[productId] == true)
          ElevatedButton(
            onPressed: () => _updateQuantity(productId, editedQuantity),
            child: Text('Update'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshProductList,
            tooltip: "Refresh List",
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddProductPage()),
                  );
                  _refreshProductList();
                },
                icon: Icon(Icons.add),
                label: Text('Add Product'),
              ),
              SizedBox(height: 24),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _categoryProductFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());

                  if (snapshot.hasError)
                    return Center(child: Text('Error loading products'));

                  final categories = snapshot.data ?? [];

                  if (categories.isEmpty)
                    return Center(child: Text('No products found.'));

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isFruit = (cat['name'] as String).toLowerCase() == 'fruits';
                      final products =
                      List<Map<String, dynamic>>.from(cat['products'] ?? []);

                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['name'] ?? 'Unnamed Category',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              ...products.map((product) {
                                final productId = product['id'].toString();
                                final quantity = product['quantity'] ?? 0;
                                final name = product['name'] ?? 'Unnamed';

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(name),
                                  subtitle: _buildQuantityControl(
                                    productId: productId,
                                    originalQuantity: quantity,
                                    isKg: isFruit,
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}



