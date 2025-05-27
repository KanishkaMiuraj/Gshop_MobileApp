import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserHomePage extends StatefulWidget {
  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List categories = [];
  String? selectedCategoryId;
  List products = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await Supabase.instance.client.from('categories').select();
    setState(() {
      categories = data;
      if (data.isNotEmpty) {
        selectedCategoryId = data[0]['id'];
        loadProducts(data[0]['id']);
      }
    });
  }

  Future<void> loadProducts(String categoryId) async {
    final data = await Supabase.instance.client
        .from('products')
        .select()
        .eq('category_id', categoryId);
    setState(() {
      products = data;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Browse Products")),
    body: Column(
      children: [
        DropdownButton<String>(
          value: selectedCategoryId,
          onChanged: (val) {
            setState(() => selectedCategoryId = val);
            loadProducts(val!);
          },
          items: categories.map<DropdownMenuItem<String>>((item) {
            return DropdownMenuItem(
              value: item['id'],
              child: Text(item['name']),
            );
          }).toList(),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, index) {
              final product = products[index];
              return ListTile(
                title: Text(product['name']),
                subtitle: Text(product['description'] ?? ""),
                trailing: Text("\$${product['price']}"),
              );
            },
          ),
        ),
      ],
    ),
  );
}
