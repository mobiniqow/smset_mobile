import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool _isLoadingForms = false;
  bool _isLoadingProducts = false;
  List<Map<String, dynamic>> _forms = [];
  List<Map<String, dynamic>> _all_products = [];
  var _allproduc = {};
  List<Map<String, dynamic>> _products = [];
  String? _selectedFormId;
  Map<String, String> _productQuantities = {}; // برای ذخیره مقادیر محصولات
  Map<String, TextEditingController> _controllers = {}; // برای ذخیره کنترلرهای مربوط به هر محصول

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
      List data = jsonDecode(utf8.decode(response.bodyBytes))['results'];
      setState(() {
        _all_products.clear();
        _all_products.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        print("_all_products $_all_products");
        for (var item in _all_products) {
          _allproduc[item['id']] = item;
        }
        _isLoadingProducts = false;

        // Initialize controllers for each product
        for (var product in _products) {
          _controllers[product['id']] = TextEditingController();
        }
      });
    } else {
      setState(() {
        _isLoadingProducts = false;
      });
      throw Exception('مشکلی در دریافت اطلاعات محصولات پیش آمده است');
    }
  }

  Future<void> _fetchForms() async {
    setState(() {
      _isLoadingForms = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(utf8.decode(response.bodyBytes))['results'];
      setState(() {
        _forms.clear();
        _forms.addAll(data.map((e) => e as Map<String, dynamic>).toList());
        _isLoadingForms = false;
      });
    } else {
      setState(() {
        _isLoadingForms = false;
      });
      throw Exception('مشکلی در دریافت فرم‌ها پیش آمده است');
    }
  }

  Future<void> _fetchProductsForForm(String formId) async {
    setState(() {
      _isLoadingProducts = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    final response = await http.get(
      Uri.parse('https://smset.ir/product/api/v1/product_forms/$formId/'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final formData = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _products = List<Map<String, dynamic>>.from(formData['items']);
        _isLoadingProducts = false;

        // Initialize controllers for each product when products are fetched
        for (var product in _products) {
          if (!_controllers.containsKey(product['id'])) {
            _controllers[product['id']] = TextEditingController();
          }
        }
      });
    } else {
      setState(() {
        _isLoadingProducts = false;
      });
      throw Exception('مشکلی در دریافت محصولات برای فرم انتخابی پیش آمده است');
    }
  }

  // Share order (form products and quantities)
  void _shareOrder() {
    print("_forms $_forms");
    var form_name ="";
    for(var i in _forms){
      if (i['id']==_selectedFormId){
        form_name=i['name'];
      }
    }
    // شروع با نوشتار سفارش و شناسه فرم
    String orderSummary = "📝 **سفارش برای فرم:** $form_name\n\n";

    // افزودن اطلاعات هر محصول به صورت مرتب و فارسی
    _products.forEach((product) {
      String quantity = _productQuantities[product['id']] ?? '0';
      String productName = _allproduc[product['product']]['name'] ?? 'نامشخص';
      String productUnit = _allproduc[product['product']]['unit'] ?? 'واحد نامشخص';

      // اضافه کردن اطلاعات محصول به خلاصه سفارش
      orderSummary += " **محصول:** $productName\n";
      orderSummary += " **تعداد:** $quantity $productUnit\n";
      orderSummary += "------------------------\n";
    });

    // اشتراک‌گذاری پیام
    Share.share(orderSummary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("صفحه سفارش"),
        backgroundColor: Colors.blue, // رنگ هدر
      ),
      body: _isLoadingForms
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // فرم‌ها (Dropdown برای انتخاب فرم)
          DropdownButton<String>(
            hint: const Text("انتخاب فرم"),
            value: _selectedFormId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedFormId = value;
                  _fetchProductsForForm(value); // بارگذاری محصولات برای فرم انتخاب شده
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
          // نمایش بارگذاری در صورت دریافت اطلاعات محصولات
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final TextEditingController _productQuantityController =
                _controllers[product['id']]!;

                return ListTile(
                  title: Text(_allproduc[product['product']]['name']),
                  subtitle: Text('واحد: ${_allproduc[product['product']]['unit']}'),
                  trailing: SizedBox(
                    width: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _productQuantityController,
                            keyboardType: TextInputType.text, // ورودی آزاد
                            decoration: const InputDecoration(
                              labelText: 'تعداد',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              // به‌روزرسانی مقدار محصول
                              _productQuantities[product['id']] = value;
                              setState(() {});
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
          // دکمه اشتراک‌گذاری
          ElevatedButton(
            onPressed: _selectedFormId == null || _products.isEmpty
                ? null
                : _shareOrder,
            child: const Text("اشتراک گذاری سفارش"),
          ),
        ],
      ),
    );
  }
}
