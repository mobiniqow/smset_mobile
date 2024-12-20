import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smset/page/login/verify.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  // تابع برای ارسال درخواست لاگین
  void _sendLoginRequest() async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.post(
      Uri.parse('https://smset.ir/account/api/v1/login/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'phone': _phoneController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyPage(phone: _phoneController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در اطلاعات وارد شده.')),
      );
    }
  }

  // نمایش قوانین و مقررات
  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "قوانین و مقررات",
            style: TextStyle(
                fontFamily: 'ProductSans', fontWeight: FontWeight.w600),
          ),
          content: Text(
            "این قوانین و مقررات استفاده از اپلیکیشن هستند. لطفاً پیش از استفاده از اپلیکیشن، آنها را با دقت مطالعه کنید. "
            "ما از اطلاعات شما برای ارسال کد یکبار مصرف استفاده می‌کنیم و شما مسئول حفاظت از شماره تلفن خود خواهید بود. "
            "با استفاده از این اپلیکیشن، شما موافقت خود را با این قوانین اعلام می‌کنید.",
            style: TextStyle(fontFamily: 'ProductSans'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "باشه",
                style: TextStyle(fontFamily: 'ProductSans'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent, // رنگ پس‌زمینه شاد
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'شماره همراه',
                labelStyle:
                    TextStyle(color: Colors.white, fontFamily: 'ProductSans'),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: TextStyle(color: Colors.white, fontFamily: 'ProductSans'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendLoginRequest,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'ورود',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'ProductSans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // عرض دکمه
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // گوشه‌های گرد دکمه
                ),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: _showTermsAndConditions,
              child: Text(
                'قوانین و مقررات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'ProductSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
