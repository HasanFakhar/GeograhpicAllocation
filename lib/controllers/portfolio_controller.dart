import '../models/portfolio_model.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// The four dimensions a holding can be grouped by.
/// Shared between the simple tabs (Region/Class/Currency/Sector) and the
/// Cross-section tab's SLICE × BY pickers.
enum Dimension { assetClass, region, currency, sector }

const Map<Dimension, String> dimensionLabel = {
  Dimension.assetClass: 'Class',
  Dimension.region: 'Region',
  Dimension.currency: 'Currency',
  Dimension.sector: 'Sector',
};

/// One row in the cross-section SLICE list: a primary-dimension group
/// (e.g. "Public Equities") with its share of the whole portfolio, plus
/// — once expanded — its breakdown across the BY dimension.
class CrossSectionRow {
  final String key; // raw group key, e.g. 'Equity'
  final String label; // display label, e.g. 'Public Equities'
  final double allocationPct; // % of WHOLE portfolio
  final double marketValue;
  final int positionCount;
  final List<AllocationItem> byBreakdown; // this slice's split across BY dimension

  CrossSectionRow({
    required this.key,
    required this.label,
    required this.allocationPct,
    required this.marketValue,
    required this.positionCount,
    required this.byBreakdown,
  });
}

class PortfolioController extends GetxController {
  // static const String portfolioApiUrl = 'https://your-api.example.com/portfolio'; // placeholder URL
  // static const String mandateApiUrl = 'https://your-api.example.com/mandates'; // placeholder URL

  final Rx<PortfolioData?> portfolioData = Rx<PortfolioData?>(null);
  double totalPortfolioValue = 0.0;
  Map<String, double> marketValueByAssetClass = <String, double>{};
  Map<String, double> allocationByAssetClass = <String, double>{};
  List<AllocationItem> regionItems = [];
  List<AllocationItem> regionChartData = [];
  List<AllocationItem> classItems = [];
  List<AllocationItem> classChartData = [];
  List<AllocationItem> currencyItems = [];
  List<AllocationItem> currencyChartData = [];
  List<AllocationItem> sectorItems = [];
  List<AllocationItem> sectorChartData = [];
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
      countryIsoMap = data.map((key, value) => MapEntry(key, value.toString()));

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
    List<AllocationItem> r1 = [];
    List<AllocationItem> r2 = [];
    List<AllocationItem> c1 = [];
    List<AllocationItem> c2 = [];
    List<AllocationItem> x1 = [];
    List<AllocationItem> x2 = [];
    List<AllocationItem> b1 = [];
    List<AllocationItem> b2 = [];

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

    (r1, r2) = _buildRegionItems(data.holdings);
    regionItems = r1;
    regionChartData = r2;

    (c1, c2) = _buildClassItems(data.holdings);

    classItems = c1;
    classChartData = c2;
    (x1, x2) = _buildCurrencyItems(data.holdings);
    currencyItems = x1;
    currencyChartData = x2;

    (b1, b2) = _buildSectorItems(data.holdings);
    sectorItems = b1;
    sectorChartData = b2;

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
  (List<AllocationItem>, List<AllocationItem>) _buildRegionItems(
    List<PortfolioHolding> holdings,
  ) {
    // Aggregate by country
    final mvByCountry = <String, double>{};
    final metaByCountry = <String, PortfolioHolding>{};
    final holdingsbyCountry = <String, List<PortfolioHolding>>{};

    for (final h in holdings) {
      if (h.marketValue == 0.0) continue;
      final key = h.countryName;
      mvByCountry[key] = (mvByCountry[key] ?? 0.0) + h.marketValue;
      metaByCountry.putIfAbsent(key, () => h);
      holdingsbyCountry.putIfAbsent(key, () => []).add(h);
    }
    return _toAllocationItems(
      holdingsbyCountry,
      mvByCountry,
      totalPortfolioValue,
      code: (k) => countryIsoMap[k.toUpperCase()] ?? '',
      name: (k) => k,
      subLabel: (k) => k,
      filterGroup: (k) => k,
    );
  }

  /// Filter groups for the Region tab — "All" + one button per unique region.
  List<FilterGroup> getRegionFilters() =>
      _buildFilterGroups(regionItems, labelAll: 'All');

  /// Holdings filtered by [regionGroupKey] ('all' returns everything).
  List<AllocationItem> getRegionItems([String regionGroupKey = 'all']) =>
      _applyFilter(regionItems, regionGroupKey);

  // ─── Asset Class ─────────────────────────────────────────────────────────────
  (List<AllocationItem>, List<AllocationItem>) _buildClassItems(
    List<PortfolioHolding> holdings,
  ) {
    final mvByClass = <String, double>{};
    final metaByClass = <String, PortfolioHolding>{};
    final holdingsByClass = <String, List<PortfolioHolding>>{};
    for (final h in holdings) {
      mvByClass[h.assetClassName] =
          (mvByClass[h.assetClassName] ?? 0.0) + h.marketValue;
      metaByClass.putIfAbsent(h.assetClassName, () => h);
      holdingsByClass.putIfAbsent(h.assetClassName, () => []).add(h);
    }
    return _toAllocationItems(
      holdingsByClass,
      mvByClass,
      totalPortfolioValue,
      code: (k) => countryIsoMap[k.toUpperCase()] ?? '',
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
      classChartData.isNotEmpty ? classChartData.first : null;

  // ─── Currency ────────────────────────────────────────────────────────────────
  (List<AllocationItem>, List<AllocationItem>) _buildCurrencyItems(
    List<PortfolioHolding> holdings,
  ) {
    final mvByCurrency = <String, double>{};
    final metaByCurrency = <String, PortfolioHolding>{};
    final holdingsByCurrency = <String, List<PortfolioHolding>>{};
    for (final h in holdings) {
      final key = h.localCurrencyISOCode;
      mvByCurrency[key] = (mvByCurrency[key] ?? 0.0) + h.marketValue;
      metaByCurrency.putIfAbsent(key, () => h);
      holdingsByCurrency.putIfAbsent(key, () => []).add(h);
    }
    return _toAllocationItems(
      holdingsByCurrency,
      mvByCurrency,
      totalPortfolioValue,
      code: (k) => countryIsoMap[k.toUpperCase()] ?? '',
      name: (k) => k,
      subLabel: (k) => k,
      filterGroup: (k) => k,
    );
  }

  /// Filter groups for the Currency tab — "All" + one button per currency group.
  List<FilterGroup> getCurrencyFilters() =>
      _buildFilterGroups(currencyItems, labelAll: 'All');

  /// Holdings filtered by [currencyGroupKey] ('all' returns everything).
  List<AllocationItem> getCurrencyItems([String currencyGroupKey = 'all']) =>
      _applyFilter(currencyItems, currencyGroupKey);

  // ─── Sector ──────────────────────────────────────────────────────────────────
  (List<AllocationItem>, List<AllocationItem>) _buildSectorItems(
    List<PortfolioHolding> holdings,
  ) {
    final mvBySector = <String, double>{};
    final metaBySector = <String, PortfolioHolding>{};
    final holdingsBySector = <String, List<PortfolioHolding>>{};
    for (final h in holdings) {
      if (h.marketValue == 0.0) continue;
      if (h.sector.isEmpty) {
        mvBySector['N/A'] = (mvBySector['N/A'] ?? 0.0) + h.marketValue;
        metaBySector.putIfAbsent('N/A', () => h);
      } else {
        // skip holdings with no sector info
        mvBySector[h.sector] = (mvBySector[h.sector] ?? 0.0) + h.marketValue;
        metaBySector.putIfAbsent(h.sector, () => h);
        holdingsBySector.putIfAbsent(h.sector, () => []).add(h);
      }
    }
    return _toAllocationItems(
      holdingsBySector,
      mvBySector,
      totalPortfolioValue,
      code: (k) => countryIsoMap[k.toUpperCase()] ?? '',
      name: (k) => k,
      subLabel: (k) => k,
      filterGroup: (k) => k,
    );
  }

  List<AllocationItem> getChartData(String chartType){
    switch (chartType.toLowerCase()){
      case 'donut' :
      return classChartData;
      case 'bar':
      return currencyChartData;
      case 'treemap':
      return sectorChartData;
      default:
      return regionChartData;
    }
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
  (List<AllocationItem>, List<AllocationItem>) _toAllocationItems(
    Map<String, List<PortfolioHolding>> holdingsByKey,
    Map<String, double> mvMap,
    double total, {
    required String Function(String key) code,
    required String Function(String key) name,
    required String Function(String key) subLabel,
    required String Function(String key) filterGroup,
  }) {
    final items = <AllocationItem>[];

    holdingsByKey.forEach((key, holdings) {
      final group = filterGroup(key);
      for (final h in holdings) {
        final pct = total == 0 ? 0.0 : (h.marketValue / total) * 100;
        items.add(
          AllocationItem(
            code: code(h.countryName),
            name: name(h.fullSecurityName),
            subLabel: subLabel(h.securitySymbol),
            allocationPct: pct,
            marketValue: h.marketValue,
            filterGroup: group,
            quantity: h.quantity.roundToDouble(),
            currencyCode: h.localCurrencyISOCode
          ),
        );
      }
    });

    items.sort((a, b) => b.allocationPct.compareTo(a.allocationPct));
    
    // group by keys for chart (all) data
    final allocations = _toAllocations(mvMap, total);
    final items2 = mvMap.keys.map((k) {
      return AllocationItem(
        code: code(k),
        name: k,
        subLabel: subLabel(k),
        allocationPct: allocations[k] ?? 0.0,
        marketValue: mvMap[k] ?? 0.0,
        filterGroup: filterGroup(k),
        quantity: 0,
      );
    }).toList()..sort((a, b) => b.allocationPct.compareTo(a.allocationPct));

    return (items, items2);
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
      FilterGroup(
        selected: true,
        label: labelAll,
        allocationPct: 100.0,
        groupKey: 'all',
      ),
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

  // ─── Cross-section (SLICE × BY) ───────────────────────────────────────────────
  // Lets the user pick two dimensions at once, e.g. "Class, by Region":
  // SLICE picks the primary grouping shown as rows; BY picks the secondary
  // grouping used both for the chip filter row and each row's expanded
  // breakdown.

  /// Extracts the raw grouping key for [dim] from a single holding.
  String _keyFor(Dimension dim, PortfolioHolding h) {
    switch (dim) {
      case Dimension.assetClass:
        return h.assetClassName;
      case Dimension.region:
        return h.countryName;
      case Dimension.currency:
        return h.localCurrencyISOCode;
      case Dimension.sector:
        return h.sector.isEmpty ? 'N/A' : h.sector;
    }
  }

  /// Display label for a raw key under [dim] (currently identity — kept as a
  /// seam in case dimensions need prettified labels later, e.g. ISO → flag name).
  String _labelFor(Dimension dim, String key) => key;

  /// Country/region ISO code lookup, reused for chip + row "code" badges.
  String _codeFor(Dimension dim, String key) {
      var x = dim == Dimension.region ? (countryIsoMap[key.toUpperCase()] ?? '') : '';
      print('code for $key');
      return x;
  }

  /// Top-line chips for the BY dimension — used to filter the cross-section
  /// view down to one BY-group at a time. 'all' is implicit (no chip needed
  /// since SLICE/BY pickers already sit above), so this returns only the
  /// real groups, sorted by allocation, largest first.
  List<FilterGroup> getCrossSectionByChips(Dimension sliceDim, Dimension byDim) {
    final data = portfolioData.value;
    if (data == null) return [];

    final mvByKey = <String, double>{};
    for (final h in data.holdings) {
      if (h.marketValue == 0.0) continue;
      final k = _keyFor(byDim, h);
      mvByKey[k] = (mvByKey[k] ?? 0.0) + h.marketValue;
    }

    final entries = mvByKey.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.map((e) {
      final pct = totalPortfolioValue == 0 ? 0.0 : (e.value / totalPortfolioValue) * 100;
      return FilterGroup(
        label: _labelFor(byDim, e.key),
        allocationPct: pct,
        groupKey: e.key,
      );
    }).toList();
  }

  /// Builds the SLICE rows for the cross-section view.
  ///
  /// Each row's [CrossSectionRow.allocationPct] is always the group's share
  /// of the WHOLE portfolio (independent of any BY-chip filter), so the
  /// headline bars stay stable as the user explores. [byBreakdown] is that
  /// same slice's holdings split across the BY dimension, recomputed against
  /// [byFilterKey] when set ('all' or null = no chip filter applied) — this
  /// is what renders inside a row once it's expanded.
  List<CrossSectionRow> getCrossSectionRows(
    Dimension sliceDim,
    Dimension byDim, {
    String? byFilterKey,
  }) {
    final data = portfolioData.value;
    if (data == null) return [];

    // Restrict to holdings matching the BY chip filter, if any.
    final relevantHoldings = (byFilterKey == null || byFilterKey == 'all')
        ? data.holdings
        : data.holdings
            .where((h) => _keyFor(byDim, h) == byFilterKey)
            .toList();

    // Group the (filter-restricted) holdings by the SLICE dimension.
    final holdingsBySlice = <String, List<PortfolioHolding>>{};
    for (final h in relevantHoldings) {
      if (h.marketValue == 0.0) continue;
      holdingsBySlice.putIfAbsent(_keyFor(sliceDim, h), () => []).add(h);
    }

    final rows = <CrossSectionRow>[];
    holdingsBySlice.forEach((sliceKey, sliceHoldings) {
      final sliceMv = sliceHoldings.fold(0.0, (s, h) => s + h.marketValue);
      final pctOfWhole =
          totalPortfolioValue == 0 ? 0.0 : (sliceMv / totalPortfolioValue) * 100;

      // Breakdown of this slice across the BY dimension (used when expanded).
      final mvByByKey = <String, double>{};
      final currencyByKey = <String,String>{};
      for (final h in sliceHoldings) {
        final k = _keyFor(byDim, h);
        mvByByKey[k] = (mvByByKey[k] ?? 0.0) + h.marketValue;
        currencyByKey[k] = h.localCurrencyISOCode;

      }
      print(currencyByKey);
      final byBreakdown = mvByByKey.entries.map((e) {
        final pctOfSlice = sliceMv == 0 ? 0.0 : (e.value / sliceMv) * 100;
        return AllocationItem(
          code: _codeFor(byDim, e.key),
          name: _labelFor(byDim, e.key),
          subLabel: dimensionLabel[byDim] ?? '',
          allocationPct: pctOfSlice,
          marketValue: e.value,
          filterGroup: e.key,
          quantity: 0,
          currencyCode: currencyByKey[e.key] ?? '',
        );
      }).toList()
        ..sort((a, b) => b.allocationPct.compareTo(a.allocationPct));

      rows.add(CrossSectionRow(
        key: sliceKey,
        label: _labelFor(sliceDim, sliceKey),
        allocationPct: pctOfWhole,
        marketValue: sliceMv,
        positionCount: sliceHoldings.length,
        byBreakdown: byBreakdown,
      ));
    });

    rows.sort((a, b) => b.allocationPct.compareTo(a.allocationPct));
    return rows;
  }

  /// The positions list for the cross-section view: every underlying
  /// holding matching the BY chip filter (or everything, if none selected),
  /// optionally narrowed further to one expanded [sliceFilterKey], sorted
  /// largest first.
  List<AllocationItem> getCrossSectionPositions(
    Dimension sliceDim,
    Dimension byDim, {
    String? byFilterKey,
    String? sliceFilterKey,
  }) {
    final data = portfolioData.value;
    if (data == null) return [];

    Iterable<PortfolioHolding> relevantHoldings = data.holdings;
    if (byFilterKey != null && byFilterKey != 'all') {
      relevantHoldings =
          relevantHoldings.where((h) => _keyFor(byDim, h) == byFilterKey);
    }
    if (sliceFilterKey != null) {
      relevantHoldings =
          relevantHoldings.where((h) => _keyFor(sliceDim, h) == sliceFilterKey);
    }

    final items = relevantHoldings.where((h) => h.marketValue != 0.0).map((h) {
      final pct = totalPortfolioValue == 0
          ? 0.0
          : (h.marketValue / totalPortfolioValue) * 100;
      return AllocationItem(
        code: _codeFor(Dimension.region, h.countryName),
        name: h.fullSecurityName,
        subLabel: h.securitySymbol,
        allocationPct: pct,
        marketValue: h.marketValue,
        filterGroup: _keyFor(sliceDim, h),
        quantity: h.quantity.roundToDouble(),
        currencyCode: h.localCurrencyISOCode,
      );
    }).toList()
      ..sort((a, b) => b.allocationPct.compareTo(a.allocationPct));

    return items;
  }
}