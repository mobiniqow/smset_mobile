import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _forms = [];
  List<Map<String, dynamic>> _products = [];
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _fetchForms();
  }

  // Fetch forms from the API
  Future<void> _fetchForms() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/productforms/'),
      headers: {
        'Authorization': 'Bearer YOUR_ACCESS_TOKEN', // برای احراز هویت
      },
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      setState(() {
        _forms.clear();
        _forms.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load forms');
    }
  }

  // Create a new product form
  Future<void> _createForm(String name) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/productforms/'),
      headers: {
        'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
        'Content-Type': 'application/json',
      },
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 201) {
      _fetchForms(); // Refresh the forms list
    } else {
      throw Exception('Failed to create form');
    }
  }

  // Delete a product form
  Future<void> _deleteForm(String formId) async {
    final response = await http.delete(
      Uri.parse('http://127.0.0.1:8000/api/productforms/$formId/'),
      headers: {
        'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
      },
    );

    if (response.statusCode == 204) {
      _fetchForms(); // Refresh the forms list
    } else {
      throw Exception('Failed to delete form');
    }
  }

  // Show a dialog to add product to form
  Future<void> _addProductToForm(String formId) async {
    final TextEditingController productIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Product to Form'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: productIdController,
                decoration: const InputDecoration(labelText: 'Product ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final productId = productIdController.text;
                if (productId.isEmpty) return;

                await _addProduct(formId, productId);
                Navigator.pop(context);
              },
              child: const Text('Add Product'),
            ),
          ],
        );
      },
    );
  }

  // Add product to form API request
  Future<void> _addProduct(String formId, String productId) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/productforms/$formId/add_product/'),
      headers: {
        'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
        'Content-Type': 'application/json',
      },
      body: json.encode({'product_id': productId}),
    );

    if (response.statusCode == 201) {
      _fetchForms(); // Refresh the forms list
    } else {
      throw Exception('Failed to add product');
    }
  }

  // Show products of a form
  Future<void> _fetchProductsForForm(String formId) async {
    setState(() {
      _isLoadingProducts = true;
    });

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/productforms/$formId/'),
      headers: {
        'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      final formData = json.decode(response.body);
      setState(() {
        _products = List<Map<String, dynamic>>.from(formData['items']);
        _isLoadingProducts = false;
      });
    } else {
      setState(() {
        _isLoadingProducts = false;
      });
      throw Exception('Failed to load products for form');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Forms")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _forms.length,
        itemBuilder: (context, index) {
          final form = _forms[index];
          return ListTile(
            title: Text(form['name']),
            subtitle: Text('ID: ${form['id']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Implement form edit functionality if needed
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteForm(form['id']);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _addProductToForm(form['id']);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.view_list),
                  onPressed: () {
                    _fetchProductsForForm(form['id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final TextEditingController nameController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Create Product Form'),
                content: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Form Name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final formName = nameController.text;
                      if (formName.isEmpty) return;

                      await _createForm(formName);
                      Navigator.pop(context);
                    },
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
