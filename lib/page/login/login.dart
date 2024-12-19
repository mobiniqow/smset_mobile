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
        SnackBar(content: Text('Login failed!')),
      );
    }
  }

  // نمایش قوانین و مقررات
  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Terms & Conditions"),
          content: Text("Here are the terms and conditions of using the app..."),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
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
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.white),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendLoginRequest,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Send OTP', style: TextStyle(fontSize: 18)),
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
                'Terms & Conditions',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
