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
    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product'), // URL API
      headers: {'Authorization': 'Bearer $accessToken'}, // Token برای احراز هویت
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body)['results'];
      _products.clear();
      _products.addAll(data.map((e) => e as Map<String, dynamic>).toList());
      setState(() {
        _isLoading = false;
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
          title: const Text('ایجاد محصول'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'نام محصول'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'واحد'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('انصراف', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                final unit = unitController.text;

                if (name.isEmpty || unit.isEmpty) return;

                await _createProduct(name, unit);
                Navigator.pop(context);
              },
              child: const Text('ایجاد', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.green),
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
          title: const Text('تایید حذف'),
          content: const Text('آیا از حذف این محصول اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteProductApi(productId);
                Navigator.pop(context);
              },
              child: const Text('حذف'),
              style: TextButton.styleFrom(backgroundColor: Colors.red),
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
          title: const Text('به روز رسانی محصول'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'نام محصول'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'واحد'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                final unit = unitController.text;

                if (name.isEmpty || unit.isEmpty) return;

                await _updateProduct(productId, name, unit);
                Navigator.pop(context);
              },
              child: const Text('به روز رسانی'),
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
      appBar: AppBar(
        title: const Text("صفحه محصولات"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.blue, width: 1),
            ),
            child: ListTile(
              title: Text(product['name'], style: TextStyle(fontFamily: 'ProductSans', fontSize: 18)),
              subtitle: Text(product['unit'], style: TextStyle(fontFamily: 'ProductSans', color: Colors.grey)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () {
                      _showUpdateDialog(product['id'], product['name'], product['unit']);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteProduct(product['id']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.green,
      ),
    );
  }
}
