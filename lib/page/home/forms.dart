import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  bool _isLoading = false;
  bool _isLoadingProducts = false;
  List<Map<String, dynamic>> _forms = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _selectedProducts = [];

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

    var prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/'),
      headers: {
        'Authorization': 'Bearer $accessToken', // for authentication
      },
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body)['results'];
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

  // Fetch products for the current user
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });
    var prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body)['results'];
      setState(() {
        _products.clear();
        _products.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        _isLoadingProducts = false;
      });
    } else {
      setState(() {
        _isLoadingProducts = false;
      });
      throw Exception('Failed to load products');
    }
  }

  Future<void> _showProductSelectionDialog(String formId) async {
    // ابتدا محصولات را بارگذاری می‌کنیم
    await _fetchProducts();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Products'),
          content: _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : Container(
            height: 290,
            width: 190,
            child: StatefulBuilder(
              builder: (BuildContext context, setState) {
                return ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    bool isSelected = _selectedProducts
                        .any((item) => item['id'] == product['id']);
                    return CheckboxListTile(
                      title: Text(product['name']),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedProducts.add(product);
                          } else {
                            _selectedProducts.removeWhere(
                                    (item) => item['id'] == product['id']);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
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
                // ارسال محصولات انتخابی به فرم
                await _addProductsToForm(formId);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProductsToForm(String formId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    // استخراج شناسه‌های محصولات از لیست انتخاب شده
    final List<String> productIds =
    _selectedProducts.map((product) => product['id'].toString()).toList();

    final response = await http.post(
      Uri.parse(
          'https://smset.ir/product/api/v1/product_forms/$formId/add_product/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'product_ids': productIds}),
    );

    if (response.statusCode == 201) {
      // پس از ارسال موفق، لیست فرم‌ها را دوباره بکشیم
      _fetchForms(); // Refresh the forms list
    } else {
      throw Exception('Failed to add products');
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
                          _showProductSelectionDialog(form['id']);
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

  // Create a new product form
  Future<void> _createForm(String name) async {
    var prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.post(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.delete(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/$formId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      _fetchForms(); // Refresh the forms list
    } else {
      throw Exception('Failed to delete form');
    }
  }
}
