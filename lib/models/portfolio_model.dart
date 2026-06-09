class PortfolioData {
  final List<PortfolioHolding> holdings;
  final List<PortfolioSummary> summary;

  PortfolioData({
    required this.holdings,
    required this.summary,
  });

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
  final String portfolioCode;
  final String reportDate;
  final String countryName;
  final String assetClassName;
  final String localCurrencyISOCode;
  final double marketValue;
  final String sector;

  PortfolioHolding({
    required this.sector,
    required this.countryName,
    required this.fullSecurityName,
    required this.localCurrencyName,
    required this.portfolioCode,
    required this.reportDate,
    required this.localCurrencyISOCode,
   
    required this.assetClassName,
 
    required this.marketValue,
  });

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      fullSecurityName: json['FullSecurityName'] ?? '',
            sector:json['IndSector'] ?? '',

      countryName:json['CountryName'] ?? '',
      localCurrencyName: json['LocalCurrencyName'] ?? '',
      portfolioCode: json['PortfolioCode'] ?? '',
      reportDate: json['ReportDate'] ?? '',
      assetClassName: json['AssetClass'] ?? '',
      localCurrencyISOCode: json['LocalCurrencyISOCode'] ?? '',
      marketValue: (json['MarketValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PortfolioSummary {
  final String columnValue;
  final double marketValue;

  PortfolioSummary({
    required this.columnValue,
    required this.marketValue,
  });

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      columnValue: json['ColumnValue'] ?? '',
      marketValue: (json['MarketValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}