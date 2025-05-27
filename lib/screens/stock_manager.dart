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

  Widget _buildProductTile(Map<String, dynamic> product, String unit) {
    final id = product['id'].toString();
    final name = product['name'];
    final quantity = _modifiedQuantities[id] ?? 0;
    final imageUrl = product['image_url'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        leading: CircleAvatar(
          radius: 25,
          backgroundImage: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl)
              : const AssetImage('assets/placeholder.png') as ImageProvider,
        ),
        title: Text(name, style: const TextStyle(fontSize: 16)),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Qty: "),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // absorb taps, prevent expansion toggle on quantity change
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (quantity > 0) {
                        _updateQuantity(id, quantity - 1);
                      }
                    },
                  ),
                  Text(
                    quantity.toStringAsFixed(1) +
                        (unit.isNotEmpty ? ' $unit' : ''),
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      _updateQuantity(id, quantity + 1);
                    },
                  ),
                ],
              ),
            ),
            if (_showUpdateButton[id] == true)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                  onPressed: () => _saveQuantity(id),
                  child: const Text('Save'),
                ),
              ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UpdateProductPage(productId: id),
            ),
          );
          _fetchCategoriesAndProducts(); // Refresh after update
        },
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final categoryId = category['id'].toString();
    final categoryName = category['name'];
    final unit = (category['units'] ?? '').toString(); // get unit for category

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
          .map((product) => _buildProductTile(product, unit))
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
