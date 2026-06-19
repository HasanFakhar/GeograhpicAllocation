class PortfolioData {
  final List<PortfolioHolding> holdings;
  final List<PortfolioSummary> summary;

  PortfolioData({required this.holdings, required this.summary});

  factory PortfolioData.fromJson(Map<String, dynamic> json) {
    return PortfolioData(
      holdings: (json['Table'] as List<dynamic>)
          .map((e) => PortfolioHolding.fromJson(e))
          .toList(),
      summary: (json['Table1'] as List<dynamic>)
          .map((e) => PortfolioSummary.fromJson(e))
          .toList(),
    );
  }
}

class PortfolioHolding {
  final String fullSecurityName;
  final String localCurrencyName;
  final String localCurrencyCode;
  final String portfolioCode;
  final String reportDate;
  final String countryName;
  final String assetClassName;
  final String localCurrencyISOCode;
  final double marketValue;
  final String sector;
  final double quantity;
  final String securityTypeName;
  final String securitySymbol;

  PortfolioHolding({
    required this.sector,
    required this.quantity,
    required this.securityTypeName,
    required this.countryName,
    required this.securitySymbol,
    required this.fullSecurityName,
    required this.localCurrencyName,
    required this.localCurrencyCode,
    required this.portfolioCode,
    required this.reportDate,
    required this.localCurrencyISOCode,

    required this.assetClassName,

    required this.marketValue,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      quantity: (json['Quantity'] as num?)?.toDouble() ?? 0.0,
      fullSecurityName: json['FullSecurityName'] ?? '',
      securitySymbol: json['SecuritySymbol'] ?? '',
      securityTypeName: json['SecurityTypeName'] ?? '',
      localCurrencyCode: json['LocalCurrencyCode'].toString().toUpperCase(),
      sector: json['IndSector'] ?? '',
      countryName: json['CountryName'] ?? '',
      localCurrencyName: json['LocalCurrencyName'] ?? '',
      portfolioCode: json['PortfolioCode'] ?? '',
      reportDate: json['ReportDate'] ?? '',
      assetClassName: json['AssetClass'] ?? '',
      localCurrencyISOCode: json['LocalCurrencyISOCode'] ?? '',
      marketValue: (json['LocalMarketValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PortfolioSummary {
  final String columnValue;
  final double marketValue;

  PortfolioSummary({required this.columnValue, required this.marketValue});

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      columnValue: json['ColumnValue'] ?? '',
      marketValue: (json['MarketValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AllocationItem {
  final String code;
  final String name;
  final String subLabel;
  final double quantity;
  final double allocationPct;
  final double marketValue;
  final String filterGroup;
  final String? currencyCode;

  const AllocationItem({
    required this.code,
    required this.name,
    required this.subLabel,
    required this.allocationPct,
    required this.marketValue,
    required this.filterGroup,
    required this.quantity,
    this.currencyCode,
  });
}

class FilterGroup {
  final String label;
  final double allocationPct;
  final String groupKey;
  bool selected;

  FilterGroup({
    this.selected = false,
    required this.label,
    required this.allocationPct,
    required this.groupKey,
  });
}
