import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCategoryPage extends StatelessWidget {
  final categoryController = TextEditingController();

  Future<void> addCategory() async {
    await Supabase.instance.client.from('categories').insert({
      'name': categoryController.text,
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Add Category")),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        TextField(controller: categoryController, decoration: InputDecoration(labelText: "Category Name")),
        ElevatedButton(
            onPressed: () {
              addCategory();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Category Added")));
            },
            child: Text("Add")),
      ]),
    ),
  );
}
