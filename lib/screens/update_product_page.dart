import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateProductPage extends StatefulWidget {
  final String productId;

  const UpdateProductPage({super.key, required this.productId});

  @override
  State<UpdateProductPage> createState() => _UpdateProductPageState();
}

class _UpdateProductPageState extends State<UpdateProductPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedUnit;
  String? _imageUrl;
  File? _pickedImage;

  List<Map<String, dynamic>> _categories = [];
  List<String> _unitOptions = ['Kg', 'pcs', 'ml', 'l'];

  @override
  void initState() {
    super.initState();
    _fetchCategoriesAndProduct();
  }

  Future<void> _fetchCategoriesAndProduct() async {
    final categoryData = await supabase.from('categories').select();
    final productData = await supabase
        .from('products')
        .select()
        .eq('id', widget.productId)
        .single();

    setState(() {
      _categories = List<Map<String, dynamic>>.from(categoryData);

      _nameController.text = productData['name'] ?? '';
      _descController.text = productData['description'] ?? '';
      _priceController.text = productData['price'].toString();
      _quantityController.text = productData['quantity'].toString();
      _selectedUnit = productData['unit'] ?? '';
      _selectedCategoryId = productData['category_id'].toString();
      _imageUrl = productData['image_url'];
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadImage(File file) async {
    final fileExt = p.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
    final filePath = 'product_images/$fileName';

    final bytes = await file.readAsBytes();
    final contentType = lookupMimeType(file.path);

    final response = await supabase.storage
        .from('product_images')
        .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: contentType));

    if (response.isEmpty) {
      final imageUrl =
      supabase.storage.from('product_images').getPublicUrl(filePath);
      return imageUrl;
    }
    return null;
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      String? newImageUrl = _imageUrl;

      if (_pickedImage != null) {
        newImageUrl = await _uploadImage(_pickedImage!);
      }

      await supabase.from('products').update({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'quantity': double.parse(_quantityController.text.trim()),
        'unit': _selectedUnit,
        'category_id': int.parse(_selectedCategoryId!),
        'image_url': newImageUrl,
      }).eq('id', widget.productId);

      // Update the unit in the categories table
      await supabase.from('categories').update({
        'units': _selectedUnit,
      }).eq('id', int.parse(_selectedCategoryId!));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Product")),
      body: _selectedCategoryId == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!)
                        : (_imageUrl != null
                        ? NetworkImage(_imageUrl!)
                        : const AssetImage('assets/placeholder.png')) as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['id'].toString(),
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                items: _unitOptions.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit,
                    child: Text(unit),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Unit'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
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
