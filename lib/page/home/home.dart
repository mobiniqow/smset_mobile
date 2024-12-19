import 'package:flutter/material.dart';
import 'package:smset/page/home/forms.dart';
import 'package:smset/page/home/order.dart';
import 'package:smset/page/home/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;
  final _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          const ProductFormPage(),
          const ProductPage(),
          const OrderPage(),
        ],
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (index) {
          _pageController.jumpToPage(index);
          setState(() => _currentPage = index);
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Form',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Order',
          ),
        ],
      ),
    );
  }
}