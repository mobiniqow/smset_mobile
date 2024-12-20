import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // برای اشتراک گذاری

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool _isLoadingForms = false;
  bool _isLoadingProducts = false;
  List<Map<String, dynamic>> _forms = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedFormId;
  Map<String, String> _productQuantities = {}; // برای ذخیره مقادیر محصولات

  @override
  void initState() {
    super.initState();
    _fetchForms();
    _fetchProducts();
  }
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
      throw Exception('Failed to fetch products');
    }
  }

  // Fetch forms from the API
  Future<void> _fetchForms() async {
    setState(() {
      _isLoadingForms = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/'),
      headers: {
        'Authorization': 'Bearer $accessToken', // برای احراز هویت
      },
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body)['results'];
      setState(() {
        _forms.clear();
        _forms.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        _isLoadingForms = false;
      });
    } else {
      setState(() {
        _isLoadingForms = false;
      });
      throw Exception('Failed to load forms');
    }
  }

  // Fetch products of a selected form
  Future<void> _fetchProductsForForm(String formId) async {
    setState(() {
      _isLoadingProducts = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    print(accessToken);
    print(formId);
    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/$formId/'),
      headers: {
        'Authorization': 'Bearer $accessToken', // برای احراز هویت
      },
    );

    if (response.statusCode == 200) {
      final formData = json.decode(response.body) ;
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

  // Share order (form products and quantities)
  void _shareOrder() {
    String orderSummary = "Order for Form: $_selectedFormId\n\n";
    _products.forEach((product) {
      String quantity = _productQuantities[product['id']] ?? '0';
      orderSummary +=
      "${product['name']} - Quantity: $quantity ${product['unit']}\n";
    });

    // Share the order using share_plus
    Share.share(orderSummary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Page")),
      body: _isLoadingForms
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Form list (Dropdown to select form)
          DropdownButton<String>(
            hint: const Text("Select a Form"),
            value: _selectedFormId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFormId = value;
                  _fetchProductsForForm(value); // Load products for selected form
                });
              }
            },
            items: _forms.map((form) {
              return DropdownMenuItem<String>(
                value: form['id'],
                child: Text(form['name']),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Show loading if products are being fetched
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final TextEditingController _productQuantityController =
                TextEditingController();
                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text('Unit: ${product['unit']}'),
                  trailing: SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _productQuantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              // Update product quantity
                              setState(() {
                                _productQuantities[product['id']] =
                                    value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Share button
          ElevatedButton(
            onPressed: _selectedFormId == null || _products.isEmpty
                ? null
                : _shareOrder,
            child: const Text("Share Order"),
          ),
        ],
      ),
    );
  }
}
