import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smset/page/home/home.dart';

class VerifyPage extends StatefulWidget {
  final String phone;
  VerifyPage({required this.phone});

  @override
  _VerifyPageState createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyCode() async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.post(
      Uri.parse('https://smset.ir/account/api/v1/verify/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'phone': widget.phone,
        'password': _otpController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false, // حذف همه صفحات قبلی
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تاییدیه ناموفق بود!')),
      );
    }
  }

  void _goBack() {
    Navigator.pop(context);
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
            Pinput(
              controller: _otpController,
              length: 4,
              showCursor: true,
              onCompleted: (pin) => _verifyCode(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'تایید کد یکبار مصرف',
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
              onPressed: _goBack,
              child: Text(
                'بازگشت به صفحه ورود',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'ProductSans', // فونت برای این متن
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
