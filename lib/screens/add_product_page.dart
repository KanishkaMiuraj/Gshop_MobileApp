import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductPage extends StatefulWidget {
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  File? _selectedImage;
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final response = await Supabase.instance.client
        .from('categories')
        .select('id, name');

    setState(() {
      _categories = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      print("Image picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'products/$fileName';

      final bytes = await image.readAsBytes();

      final response = await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: false,
        ),
      );

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }


  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields correctly.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(_selectedImage!);
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;

    try {
      await Supabase.instance.client.from('products').insert({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'category_id': _selectedCategoryId,
        'image_url': imageUrl,
        'created_by': userId,
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product uploaded successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Insert error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final _newCategoryController = TextEditingController();

    final newCategoryId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Category'),
        content: TextField(
          controller: _newCategoryController,
          decoration: InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _newCategoryController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  final insertResult = await Supabase.instance.client
                      .from('categories')
                      .insert({'name': newName})
                      .select()
                      .single();

                  Navigator.pop(context, insertResult['id']);
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (newCategoryId != null) {
      await _loadCategories(); // Reload category list
      setState(() {
        _selectedCategoryId = newCategoryId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: _isUploading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage == null
                    ? Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Icon(Icons.add_a_photo, size: 50),
                )
                    : Image.file(_selectedImage!, height: 150),
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) =>
                value!.isEmpty ? 'Enter product name' : null,
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _priceController,
                keyboardType:
                TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter price';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Quantity'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter quantity';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 0) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                hint: Text("Select Category"),
                items: [
                  ..._categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['id'] as String,
                      child: Text(cat['name'] as String),
                    );
                  }).toList(),
                  DropdownMenuItem(
                    value: 'add_new_category',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 6),
                        Text('Add New Category'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) async {
                  if (value == 'add_new_category') {
                    await _showAddCategoryDialog();
                  } else {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  }
                },
                validator: (value) => value == null ||
                    value == 'add_new_category'
                    ? 'Select a valid category'
                    : null,
              ),
              SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _uploadProduct,
                icon: Icon(Icons.upload),
                label: Text("Upload Product"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
