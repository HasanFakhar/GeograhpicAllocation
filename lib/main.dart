import 'package:flutter/material.dart';
import 'controllers/portfolio_controller.dart';
import 'package:get/get.dart';

void main() {
  Get.put(PortfolioController());
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mc = Get.find<PortfolioController>();

    return MaterialApp(
      home: Scaffold(
        body: GetBuilder<PortfolioController>(
          builder: (mc) {
            return Center(child: Text('total value ${mc.totalPortfolioValue}'));
          },
        ),
      ),
    );
  }
}
