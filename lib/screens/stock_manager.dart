import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'update_product_page.dart';

class StockManager extends StatefulWidget {
  const StockManager({super.key});

  @override
  State<StockManager> createState() => _StockManagerState();
}

class _StockManagerState extends State<StockManager> {
  final supabase = Supabase.instance.client;
  Map<String, bool> _expandedCategories = {};
  Map<String, double> _modifiedQuantities = {};
  Map<String, bool> _showUpdateButton = {};

  List<Map<String, dynamic>> _categories = [];
  Map<String, List<Map<String, dynamic>>> _productsByCategory = {};

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProducts();
  }

  Future<void> _fetchCategoriesAndProducts() async {
    final categories = await supabase.from('categories').select();
    final products = await supabase.from('products').select();

    setState(() {
      _categories = List<Map<String, dynamic>>.from(categories);
      _productsByCategory = {};

      for (var category in _categories) {
        final categoryId = category['id'].toString();
        _productsByCategory[categoryId] = products
            .where((product) => product['category_id'].toString() == categoryId)
            .toList();

        // Init expansion state and modified state
        _expandedCategories[categoryId] = false;

        for (var product in _productsByCategory[categoryId]!) {
          final id = product['id'].toString();
          _modifiedQuantities[id] = (product['quantity'] ?? 0).toDouble();
          _showUpdateButton[id] = false;
        }
      }
    });
  }

  void _updateQuantity(String productId, double value) {
    setState(() {
      _modifiedQuantities[productId] = value;
      _showUpdateButton[productId] = true;
    });
  }

  Future<void> _saveQuantity(String productId) async {
    final updatedQuantity = _modifiedQuantities[productId];
    await supabase.from('products').update({
      'quantity': updatedQuantity,
    }).eq('id', productId);

    setState(() {
      _showUpdateButton[productId] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock updated')),
    );
  }

  Widget _buildProductTile(Map<String, dynamic> product) {
    final id = product['id'].toString();
    final name = product['name'];
    final quantity = _modifiedQuantities[id] ?? 0;
    final imageUrl = product['image_url'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpdateProductPage(productId: id),
          ),
        ).then((_) {
          _fetchCategoriesAndProducts(); // Refresh after update
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : const AssetImage('assets/placeholder.png') as ImageProvider,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              const Text("Qty: "),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  if (quantity > 0) {
                    _updateQuantity(id, quantity - 1);
                  }
                },
              ),
              Text(quantity.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  _updateQuantity(id, quantity + 1);
                },
              ),
              if (_showUpdateButton[id] == true)
                ElevatedButton(
                  onPressed: () => _saveQuantity(id),
                  child: const Text('Update'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final categoryId = category['id'].toString();
    final categoryName = category['name'];

    return ExpansionTile(
      title: Text(
        categoryName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      initiallyExpanded: _expandedCategories[categoryId] ?? false,
      onExpansionChanged: (expanded) {
        setState(() {
          _expandedCategories[categoryId] = expanded;
        });
      },
      children: _productsByCategory[categoryId]!
          .map((product) => _buildProductTile(product))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Manager'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCategoriesAndProducts,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return _buildCategorySection(category);
          },
        ),
      ),
    );
  }
}
