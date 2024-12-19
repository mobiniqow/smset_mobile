import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fetch products from the API
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    print(accessToken);
    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product'), // URL API
      headers: {'Authorization': 'Bearer $accessToken'}, // Token برای احراز هویت
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body)['results'];
        _products.clear();
        _products.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        _isLoading = false;
        setState(() {
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load products');
    }
  }

  // Create product dialog
  Future<void> _showCreateDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
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
                final name = nameController.text;
                final unit = unitController.text;

                if (name.isEmpty || unit.isEmpty) return;

                await _createProduct(name, unit);
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Create product API request
  Future<void> _createProduct(String name, String unit) async {
    var prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.post(
      Uri.parse('https://smset.ir/product/api/v1/product/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'unit': unit,
      }),
    );

    if (response.statusCode == 201) {
      _fetchProducts(); // Refresh the product list
    } else {
      throw Exception('Failed to create product ${response.statusCode} ${response.body}');
    }
  }

  // Delete product confirmation dialog
  Future<void> _deleteProduct(String productId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteProductApi(productId);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Delete product API request
  Future<void> _deleteProductApi(String productId) async {
    var prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.delete(
      Uri.parse('https://smset.ir/product/api/v1/product/$productId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      _fetchProducts(); // Refresh the product list
    } else {
      throw Exception('Failed to delete product');
    }
  }

  // Update product dialog
  Future<void> _showUpdateDialog(String productId, String currentName, String currentUnit) async {
    final TextEditingController nameController = TextEditingController(text: currentName);
    final TextEditingController unitController = TextEditingController(text: currentUnit);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
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
                final name = nameController.text;
                final unit = unitController.text;

                if (name.isEmpty || unit.isEmpty) return;

                await _updateProduct(productId, name, unit);
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Update product API request
  Future<void> _updateProduct(String productId, String name, String unit) async {
    var prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.put(
      Uri.parse('https://smset.ir/product/api/v1/product/$productId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'unit': unit,
      }),
    );

    if (response.statusCode == 200) {
      _fetchProducts(); // Refresh the product list
    } else {
      throw Exception('Failed to update product');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Page")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product['name']),
            subtitle: Text(product['unit']),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _showUpdateDialog(product['id'], product['name'], product['unit']);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deleteProduct(product['id']);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
