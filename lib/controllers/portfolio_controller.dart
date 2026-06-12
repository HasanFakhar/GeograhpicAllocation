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
  List<AllocationItem> regionItems = [];
  List<AllocationItem> classItems = [];
  List<AllocationItem> currencyItems = [];
  List<AllocationItem> sectorItems = [];
  Map<String, String> countryIsoMap = {};

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
      final jsonString = await rootBundle.loadString('assets/dummy.json');
      final jsonString2 = await rootBundle.loadString(
        'assets/country_iso.json',
      );
      final Map<String, dynamic> data = jsonDecode(jsonString2);
      countryIsoMap = data.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      final rawJson = jsonDecode(jsonString);

      portfolioData.value = PortfolioData.fromJson(rawJson);
      _runCalculations();
    } catch (e, st) {
      print("ERROR loading asset: $e");
      print(st);
    }
  }

  // ─── Core calculations ───────────────────────────────────────────────────────
  void _runCalculations() {
    final data = portfolioData.value;
    if (data == null) return;

    totalPortfolioValue = _sumMarketValues(data.holdings);
    marketValueByAssetClass = _aggregateBy(
      data.holdings,
      key: (h) => h.assetClassName,
    );
    allocationByAssetClass = _toAllocations(
      marketValueByAssetClass,
      totalPortfolioValue,
    );

    regionItems = _buildRegionItems(data.holdings);
    classItems = _buildClassItems(data.holdings);
    currencyItems = _buildCurrencyItems(data.holdings);
    sectorItems = _buildSectorItems(data.holdings);

    update();
  }

  // ─── Internal helpers ────────────────────────────────────────────────────────
  double _sumMarketValues(List<PortfolioHolding> holdings) =>
      holdings.fold(0.0, (s, h) => s + h.marketValue);

  /// Aggregates market values by an arbitrary string key extracted from each holding.
  Map<String, double> _aggregateBy(
    List<PortfolioHolding> holdings, {
    required String Function(PortfolioHolding) key,
  }) {
    final Map<String, double> result = {};
    for (final h in holdings) {
      final k = key(h);
      result[k] = (result[k] ?? 0.0) + h.marketValue;
    }
    return result;
  }

  Map<String, double> _toAllocations(Map<String, double> mvMap, double total) {
    if (total == 0) return {for (final k in mvMap.keys) k: 0.0};
    return mvMap.map((k, mv) => MapEntry(k, (mv / total) * 100));
  }

  // ─── Region ──────────────────────────────────────────────────────────────────
  List<AllocationItem> _buildRegionItems(List<PortfolioHolding> holdings) {
    // Aggregate by country
    final mvByCountry = <String, double>{};
    final metaByCountry = <String, PortfolioHolding>{};
    for (final h in holdings) {
      if (h.marketValue == 0.0) continue;
      final key = h.countryName;
      mvByCountry[key] = (mvByCountry[key] ?? 0.0) + h.marketValue;
      metaByCountry.putIfAbsent(key, () => h);
    }
    return _toAllocationItems(
      mvByCountry,
      totalPortfolioValue,
      code: (k) => countryIsoMap[metaByCountry[k]!.countryName.toUpperCase()] ?? '',
      name: (k) => metaByCountry[k]!.countryName,
      subLabel: (k) => metaByCountry[k]!.countryName,
      filterGroup: (k) => metaByCountry[k]!.countryName,
    );
  }

  /// Filter groups for the Region tab — "All" + one button per unique region.
  List<FilterGroup> getRegionFilters() =>
      _buildFilterGroups(regionItems, labelAll: 'All');

  /// Holdings filtered by [regionGroupKey] ('all' returns everything).
  List<AllocationItem> getRegionItems([String regionGroupKey = 'all']) =>
      _applyFilter(regionItems, regionGroupKey);

  // ─── Asset Class ─────────────────────────────────────────────────────────────
  List<AllocationItem> _buildClassItems(List<PortfolioHolding> holdings) {
    final mvByClass = <String, double>{};
    final metaByClass = <String, PortfolioHolding>{};
    for (final h in holdings) {
      mvByClass[h.assetClassName] =
          (mvByClass[h.assetClassName] ?? 0.0) + h.marketValue;
      metaByClass.putIfAbsent(h.assetClassName, () => h);
    }
    return _toAllocationItems(
      mvByClass,
      totalPortfolioValue,
      code: (k) => getAssetClassCode(k),
      name: (k) => k,
      subLabel: (k) => k,
      filterGroup: (k) => k,
    );
  }

  String getAssetClassCode(String assetClassName) {
    var codeMapping = {
      'Equity': 'EQ',
      'Fixed Income': 'FI',
      'Cash and Equiv.': 'CA',
      'Alternatives': 'ALT',
    };
    return codeMapping[assetClassName] ?? '';
  }

  /// Filter groups for the Class tab — "All" + one button per asset-class group.
  List<FilterGroup> getClassFilters() =>
      _buildFilterGroups(classItems, labelAll: 'All');

  /// Holdings filtered by [classGroupKey] ('all' returns everything).
  List<AllocationItem> getClassItems([String classGroupKey = 'all']) =>
      _applyFilter(classItems, classGroupKey);

  /// The dominant (highest allocation) asset class.
  AllocationItem? getDominantClass() =>
      classItems.isNotEmpty ? classItems.first : null;

  // ─── Currency ────────────────────────────────────────────────────────────────
  List<AllocationItem> _buildCurrencyItems(List<PortfolioHolding> holdings) {
    final mvByCurrency = <String, double>{};
    final metaByCurrency = <String, PortfolioHolding>{};
    for (final h in holdings) {
      final key = h.localCurrencyISOCode;
      mvByCurrency[key] = (mvByCurrency[key] ?? 0.0) + h.marketValue;
      metaByCurrency.putIfAbsent(key, () => h);
    }
    return _toAllocationItems(
      mvByCurrency,
      totalPortfolioValue,
      code: (k) => k,
      name: (k) => metaByCurrency[k]!.localCurrencyName,
      subLabel: (k) => metaByCurrency[k]!.assetClassName,
      filterGroup: (k) => metaByCurrency[k]!.localCurrencyName,
    );
  }

  /// Filter groups for the Currency tab — "All" + one button per currency group.
  List<FilterGroup> getCurrencyFilters() =>
      _buildFilterGroups(currencyItems, labelAll: 'All');

  /// Holdings filtered by [currencyGroupKey] ('all' returns everything).
  List<AllocationItem> getCurrencyItems([String currencyGroupKey = 'all']) =>
      _applyFilter(currencyItems, currencyGroupKey);

  // ─── Sector ──────────────────────────────────────────────────────────────────
  List<AllocationItem> _buildSectorItems(List<PortfolioHolding> holdings) {
    final mvBySector = <String, double>{};
    final metaBySector = <String, PortfolioHolding>{};
    for (final h in holdings) {
      if (h.marketValue == 0.0) continue;
      if (h.sector.isEmpty) {
        mvBySector['N/A'] = (mvBySector['N/A'] ?? 0.0) + h.marketValue;
        metaBySector.putIfAbsent('N/A', () => h);
      } else {
        // skip holdings with no sector info
        mvBySector[h.sector] = (mvBySector[h.sector] ?? 0.0) + h.marketValue;
        metaBySector.putIfAbsent(h.sector, () => h);
      }
    }
    return _toAllocationItems(
      mvBySector,
      totalPortfolioValue,
      code: (k) => '',
      name: (k) => k,
      subLabel: (k) => getSecurityType(metaBySector[k]!.securityTypeName),
      filterGroup: (k) =>
          metaBySector[k]!.sector.isNotEmpty ? metaBySector[k]!.sector : 'N/A',
    );
  }

  String getSecurityType(String securityTypeName) {
    return securityTypeName.split('-').first.trim();
  }

  /// Filter groups for the Sector tab — "All" + one button per sector group.
  List<FilterGroup> getSectorFilters() =>
      _buildFilterGroups(sectorItems, labelAll: 'All');

  /// Holdings filtered by [sectorGroupKey] ('all' returns everything).
  List<AllocationItem> getSectorItems([String sectorGroupKey = 'all']) =>
      _applyFilter(sectorItems, sectorGroupKey);

  // ─── Generic helpers ─────────────────────────────────────────────────────────

  /// Converts a [mvMap] (key → market value) into a sorted list of [AllocationItem].
  List<AllocationItem> _toAllocationItems(
    Map<String, double> mvMap,
    double total, {
    required String Function(String key) code,
    required String Function(String key) name,
    required String Function(String key) subLabel,
    required String Function(String key) filterGroup,
  }) {
    final allocations = _toAllocations(mvMap, total);
    final items = mvMap.keys.map((k) {
      return AllocationItem(
        code: code(k),
        name: name(k),
        subLabel: subLabel(k),
        allocationPct: allocations[k] ?? 0.0,
        marketValue: mvMap[k] ?? 0.0,
        filterGroup: filterGroup(k),
      );
    }).toList()..sort((a, b) => b.allocationPct.compareTo(a.allocationPct));
    return items;
  }

  /// Builds the filter pill list from [items].
  /// Always prepends an "All · 100%" button, then one button per unique group,
  /// each showing the summed allocation for that group.
  List<FilterGroup> _buildFilterGroups(
    List<AllocationItem> items, {
    required String labelAll,
  }) {
    final Map<String, double> groupAlloc = {};
    for (final item in items) {
      groupAlloc[item.filterGroup] =
          (groupAlloc[item.filterGroup] ?? 0.0) + item.allocationPct;
    }

    // Sort groups by their total allocation descending
    final sortedGroups = groupAlloc.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      FilterGroup(selected: true, label: labelAll, allocationPct: 100.0, groupKey: 'all'),
      ...sortedGroups.map(
        (e) =>
            FilterGroup(label: e.key, allocationPct: e.value, groupKey: e.key),
      ),
    ];
  }

  List<AllocationItem> _applyFilter(
    List<AllocationItem> items,
    String groupKey,
  ) => groupKey == 'all'
      ? items
      : items.where((i) => i.filterGroup == groupKey).toList();

  double actualAllocation(String assetName) =>
      allocationByAssetClass[assetName] ?? 0.0;

  double marketValue(String assetName) =>
      marketValueByAssetClass[assetName] ?? 0.0;

  String get formattedTotalValue {
    if (totalPortfolioValue >= 1e9) {
      return '£${(totalPortfolioValue / 1e9).toStringAsFixed(3)}B';
    } else if (totalPortfolioValue >= 1e6) {
      return '£${(totalPortfolioValue / 1e6).toStringAsFixed(1)}M';
    } else if (totalPortfolioValue >= 1e3) {
      return '£${(totalPortfolioValue / 1e3).toStringAsFixed(1)}K';
    }
    return '£${totalPortfolioValue.toStringAsFixed(0)}';
  }

  String get reportQuarter {
    final date = portfolioData.value?.holdings.firstOrNull?.reportDate ?? '';
    if (date.isEmpty) return '';
    try {
      final parts = date.split('-'); //"YYYY-MM-DD"
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final quarter = ((month - 1) ~/ 3) + 1;
      final shortYear = year.toString().substring(2);
      return "Q$quarter '$shortYear";
    } catch (_) {
      return date;
    }
  }
}
