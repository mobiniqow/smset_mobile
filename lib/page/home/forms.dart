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
    _fetchProducts();
  }

  // Update a product form with new name
  Future<void> _updateForm(String formId, String name) async {
    var prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.put(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/$formId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'name': name}),
    );

    if (response.statusCode == 200) {
      _fetchForms(); // Refresh the forms list
    } else {
      throw Exception('Failed to update form');
    }
  }

  Future<void> _editForm(String formId, String currentName) async {
    final TextEditingController nameController =
        TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ویرایش فرم محصول'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'نام فرم'),
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
                final formName = nameController.text;
                if (formName.isEmpty) return;

                await _updateForm(formId, formName);
                Navigator.pop(context);
              },
              child: const Text('ویرایش'),
            ),
          ],
        );
      },
    );
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
      List data = jsonDecode(utf8.decode(response.bodyBytes))['results'];
      setState(() {
        _forms.clear();
        _forms.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('${jsonDecode(utf8.decode(response.bodyBytes))}');
    }
  }

  // Fetch products from the API
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
      List data = jsonDecode(utf8.decode(response.bodyBytes))['results'];
      setState(() {
        _products.clear();
        _products.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        _isLoadingProducts = false;
      });
    } else {
      setState(() {
        _isLoadingProducts = false;
      });
      throw Exception('Failed to fetch products');
    }
  }

  Future<void> _showProductSelectionDialog(formId) async {
    print("products $_products");
    for (var i = 0; i < formId['items'].length; i++) {
      bool isSelected = _selectedProducts
          .any((item) => item['id'] == formId['items'][i]['id']);
      if (!isSelected){
        var productId = formId['items'][i];
        print("productId $productId");
        for (var x in _products) {
          if (x['id']==productId['product']){
            _selectedProducts.add(x);
          }
        }
      }
    }
    print(formId);
    // await _fetchProducts();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Products'),
          content: _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
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
                // Send selected products to the form
                await _addProductsToForm(formId['id']);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Add selected products to form
  Future<void> _addProductsToForm(String formId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    // Extract product IDs from selected products
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
      _fetchForms(); // Refresh the forms list after adding products
    } else {
      throw Exception('Failed to add products ${ response.body}response.statusCode');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "فرم‌های محصولات",
          style: TextStyle(fontFamily: 'Vazir', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _forms.length,
              itemBuilder: (context, index) {
                final form = _forms[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    title: Text(
                      form['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle:
                        const Text('برای ویرایش یا مدیریت محصولات ضربه بزنید'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editForm(form['id'], form['name']);
                            // Add your edit functionality here
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteForm(form[
                                'id']); // Call delete method with confirmation
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            _showProductSelectionDialog(
                                form); // Show product selection dialog
                          },
                        ),
                      ],
                    ),
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
                title: const Text('ایجاد فرم محصول'),
                content: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'نام فرم'),
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
                      final formName = nameController.text;
                      if (formName.isEmpty) return;

                      await _createForm(formName);
                      Navigator.pop(context);
                    },
                    child: const Text('ایجاد'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
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

  // Delete a product form with confirmation
  Future<void> _deleteForm(String formId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('آیا مطمئن هستید؟'),
          content: const Text('آیا از حذف این فرم اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('انصراف'),
            ),
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? accessToken = prefs.getString('access_token');
                final response = await http.delete(
                  Uri.parse(
                      'https://smset.ir/product/api/v1/product_forms/$formId/'),
                  headers: {
                    'Authorization': 'Bearer $accessToken',
                  },
                );

                if (response.statusCode == 204) {
                  Navigator.pop(context);
                  _fetchForms(); // Refresh the forms list after deletion
                } else {
                  Navigator.pop(context);
                  throw Exception('Failed to delete form');
                }
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }
}
