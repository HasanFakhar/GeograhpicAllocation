import '../models/portfolio_model.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class PortfolioController extends GetxController {
  // static const String portfolioApiUrl = 'https://your-api.example.com/portfolio'; // placeholder URL
  // static const String mandateApiUrl = 'https://your-api.example.com/mandates'; // placeholder URL

  final Rx<PortfolioData?> portfolioData = Rx<PortfolioData?>(null);
  double totalPortfolioValue = 0.0;
  Map<String, double> marketValueByAssetClass = <String, double>{};
  Map<String, double> allocationByAssetClass = <String, double>{};

  @override
  void onInit() {
    super.onInit();
    _loadDummyData();
  }

  void _loadDummyData() async {
    await _loadPortfolioFromJson();
  }

  Future<void> _loadPortfolioFromJson() async {
    try {
      print("JSON LENGTH: here");

      final jsonString = await rootBundle.loadString('assets/dummy.json');
      print("JSON LENGTH: ${jsonString.length}");
      print(jsonString.substring(0, 200));

      print("Loaded JSON length: ${jsonString.length}");

      final rawJson = jsonDecode(jsonString);

      portfolioData.value = PortfolioData.fromJson(rawJson);
      _runCalculations();
    } catch (e, st) {
      print("ERROR loading asset: $e");
      print(st);
    }
  }

  void _runCalculations() {
    final data = portfolioData.value;
    if (data == null) return;
    print("Holdings length: ${data.holdings.length}");
    for (final h in data.holdings) {
      print("DEBUG HOLDING:");
      print("assetClass: ${h.assetClassName}");
      print("marketValue: ${h.marketValue}");
    }
    totalPortfolioValue = _calculateTotalValue(data.holdings);
    marketValueByAssetClass = _groupAndAggregate(data.holdings);
    allocationByAssetClass = _calculateAllocations(
      marketValueByAssetClass,
      totalPortfolioValue,
    );
    update();
  }

  double _calculateTotalValue(List<PortfolioHolding> holdings) =>
      holdings.fold(0.0, (sum, h) => sum + h.marketValue);
 
 

  Map<String, double> _groupAndAggregate(List<PortfolioHolding> holdings) {
    final Map<String, double> result = {};
    for (final h in holdings) {
      result[h.assetClassName] =
          (result[h.assetClassName] ?? 0.0) + h.marketValue;
    }
    return result;
  }

  Map<String, double> _calculateAllocations(
    Map<String, double> mvByClass,
    double total,
  ) {
    if (total == 0) return {for (final k in mvByClass.keys) k: 0.0};
    return mvByClass.map((cls, mv) => MapEntry(cls, (mv / total) * 100));
  }

  double actualAllocation(String assetName) =>
      allocationByAssetClass[assetName] ?? 0.0;

  double marketValue(String assetName) =>
      marketValueByAssetClass[assetName] ?? 0.0;
}
