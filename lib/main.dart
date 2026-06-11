import 'package:flutter/material.dart';
import 'controllers/portfolio_controller.dart';
import 'package:get/get.dart';
import 'widgets/geographic_asset_allocation.dart';
import 'package:flutter/gestures.dart';

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
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      home: Scaffold(
        body: PortfolioAllocationWidget()
        ),
      );
    
  }
}
