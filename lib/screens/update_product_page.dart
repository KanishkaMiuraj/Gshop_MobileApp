import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UpdateProductPage extends StatefulWidget {
  final String productId;

  const UpdateProductPage({super.key, required this.productId});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  File? _pickedImage;
  String? _imageUrl;

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProduct();
  }

  Future<void> _fetchCategoriesAndProduct() async {
    final productData = await supabase
        .from('products')
        .select()
        .eq('id', widget.productId)
        .single();

    final categoryData = await supabase.from('categories').select();

    setState(() {
      _nameController.text = productData['name'] ?? '';
      _descController.text = productData['description'] ?? '';
      _priceController.text = productData['price']?.toString() ?? '';
      _quantityController.text = productData['quantity']?.toString() ?? '';
      _imageUrl = productData['image_url'];
      _selectedCategoryId = productData['category_id']?.toString();
      _categories = List<Map<String, dynamic>>.from(categoryData);
    });
  }

  Future<void> _pickImage() async {
    final pickedImage =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _pickedImage = File(pickedImage.path);
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    final fileExt = file.path.split('.').last;
    final fileName = const Uuid().v4();
    final filePath = 'public/$fileName.$fileExt';

    final bytes = await file.readAsBytes();

    final response = await supabase.storage
        .from('product_images')
        .uploadBinary(filePath, bytes);

    if (response.isNotEmpty) {
      final imageUrl =
      supabase.storage.from('product_images').getPublicUrl(filePath);
      return imageUrl;
    } else {
      return null;
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? newImageUrl = _imageUrl;

        if (_pickedImage != null) {
          newImageUrl = await _uploadImage(_pickedImage!);
        }

        final updateData = {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'price': double.tryParse(_priceController.text.trim()) ?? 0,
          'quantity': double.tryParse(_quantityController.text.trim()) ?? 0,
          'image_url': newImageUrl,
          if (_selectedCategoryId != null) 'category_id': _selectedCategoryId,
        };

        await supabase
            .from('products')
            .update(updateData)
            .eq('id', widget.productId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: _pickedImage != null
                      ? Image.file(_pickedImage!, height: 120)
                      : _imageUrl != null
                      ? Image.network(_imageUrl!, height: 120)
                      : Container(
                    height: 120,
                    width: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.add_a_photo, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) =>
                value!.isEmpty ? 'Enter product name' : null,
              ),
              const SizedBox(height: 10),

              // Description
              TextFormField(
                controller: _descController,
                decoration:
                const InputDecoration(labelText: 'Product Description'),
                validator: (value) =>
                value!.isEmpty ? 'Enter product description' : null,
              ),
              const SizedBox(height: 10),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) =>
                value!.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 10),

              // Quantity
              TextFormField(
                controller: _quantityController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (value) =>
                value!.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 10),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration:
                const InputDecoration(labelText: 'Select Category'),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              // Update Button at Bottom
              ElevatedButton(
                onPressed: _updateProduct,
                child: const Text('Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
