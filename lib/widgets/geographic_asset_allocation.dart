import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../controllers/portfolio_controller.dart';
import '../models/portfolio_model.dart';
import 'package:countries_world_map/countries_world_map.dart';

import 'package:countries_world_map/data/maps/world_map.dart';
// ─────────────────────────────────────────────
//  Colours
// ─────────────────────────────────────────────
const Color kBg      = Color(0xFF0F0F14);
const Color kSurface = Color(0xFF1A1A24);
const Color kAmber1  = Color(0xFFF5C842);
const Color kAmber2  = Color(0xFFD4882A);
const Color kAmber3  = Color(0xFFE09030);
const Color kAmber4  = Color(0xFFB86820);
const Color kAmber5  = Color(0xFF8C4C12);
const Color kAmber6  = Color(0xFF5E3008);
const Color kText    = Color(0xFFF0E8D8);
const Color kMuted   = Color(0xFF8A8070);
const Color kDivider = Color(0xFF252530);

const List<Color> kDotColors = [
  kAmber1, kAmber2, kAmber3, kAmber4, kAmber5, kAmber6,
];

Color dotColor(int idx) => kDotColors[idx % kDotColors.length];

// ─────────────────────────────────────────────
//  Static tab metadata (labels / chart types only)
// ─────────────────────────────────────────────
enum _Tab { region, assetClass, currency, sector }

const _tabLabels = ['Region', 'Class', 'Currency', 'Sector'];

const _tabEyebrows = [
  'GEOGRAPHIC ALLOCATION',
  'ASSET CLASS',
  'CURRENCY EXPOSURE',
  'SECTOR EXPOSURE',
];

const _tabH1 = [
  'The world,',
  'Our capital,',
  'What we hold,',
  'Where we invest,',
];

const _tabH2 = [
  'by allocation.',
  'by class.',
  'in currency.',
  'by sector.',
];

// 'world' | 'donut' | 'bar' | 'treemap'
const _tabChartTypes = ['world', 'donut', 'bar', 'treemap'];

// ─────────────────────────────────────────────
//  Currency symbol lookup (ISO → symbol)
// ─────────────────────────────────────────────
const Map<String, String> kCurrencySymbols = {
  'GBP': '£', 'USD': '\$', 'EUR': '€',
  'JPY': '¥', 'CNY': '¥', 'INR': '₹',
  'CHF': '₣', 'AUD': 'A\$', 'CAD': 'C\$',
};

// ─────────────────────────────────────────────
//  Root widget
// ─────────────────────────────────────────────
class PortfolioAllocationWidget extends StatefulWidget {
  const PortfolioAllocationWidget({super.key});

  @override
  State<PortfolioAllocationWidget> createState() =>
      _PortfolioAllocationWidgetState();
}

class _PortfolioAllocationWidgetState
    extends State<PortfolioAllocationWidget> {
  int _tabIndex = 0;
  String _filter = 'all';

  void _onTab(int i) => setState(() {
        _tabIndex = i;
        _filter = 'all';
      });

  void _onFilter(String g) => setState(() => _filter = g);

  // ── Resolve live data from controller for the active tab ──────────────────
  List<AllocationItem> _items(PortfolioController c) {
    return switch (_Tab.values[_tabIndex]) {
      _Tab.region     => c.getRegionItems(_filter),
      _Tab.assetClass => c.getClassItems(_filter),
      _Tab.currency   => c.getCurrencyItems(_filter),
      _Tab.sector     => c.getSectorItems(_filter),
    };
  }

  // All items (unfiltered) – used for consistent colour indexing
  List<AllocationItem> _allItems(PortfolioController c) {
    return switch (_Tab.values[_tabIndex]) {
      _Tab.region     => c.getRegionItems(),
      _Tab.assetClass => c.getClassItems(),
      _Tab.currency   => c.getCurrencyItems(),
      _Tab.sector     => c.getSectorItems(),
    };
  }

  List<FilterGroup> _filters(PortfolioController c) {
    return switch (_Tab.values[_tabIndex]) {
      _Tab.region     => c.getRegionFilters(),
      _Tab.assetClass => c.getClassFilters(),
      _Tab.currency   => c.getCurrencyFilters(),
      _Tab.sector     => c.getSectorFilters(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PortfolioController>(
      builder: (c) {
        // While data is still loading show a spinner
        if (c.portfolioData.value == null) {
          return const Scaffold(
            backgroundColor: kBg,
            body: Center(
              child: CircularProgressIndicator(color: kAmber2),
            ),
          );
        }

        final allItems      = _allItems(c);
        final filteredItems = _items(c);
        final filterGroups  = _filters(c);
        final chartType     = _tabChartTypes[_tabIndex];

        return Scaffold(
          backgroundColor: kBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TabBar(selected: _tabIndex, onTap: _onTab),
                  const SizedBox(height: 24),
                  _Header(
                    eyebrow:   _tabEyebrows[_tabIndex],
                    h1:        _tabH1[_tabIndex],
                    h2:        _tabH2[_tabIndex],
                    aum:       c.formattedTotalValue,
                    positions: allItems.length,
                    quarter:   c.reportQuarter,
                  ),
                  const SizedBox(height: 30),
                  _ChartArea(
                    chartType:  chartType,
                    filter:     _filter,
                    allItems:   allItems,
                    dominant:   chartType == 'donut' ? c.getDominantClass() : null,
                  ),
                  const SizedBox(height: 20),
                  _FilterBar(
                    filters:  filterGroups,
                    selected: _filter,
                    onSelect: _onFilter,
                  ),
                  const SizedBox(height: 16),
                  _HoldingsSection(
                    holdings:    filteredItems,
                    allHoldings: allItems,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Tab bar
// ─────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _TabBar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(40),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? kAmber2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _tabLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : kMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String eyebrow, h1, h2, aum, quarter;
  final int positions;
  const _Header({
    required this.eyebrow,
    required this.h1,
    required this.h2,
    required this.aum,
    required this.positions,
    required this.quarter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 1.5, color: Color(0xFF9A8F7A))),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 28, color: kText, height: 1.25),
            children: [
              TextSpan(text: '$h1\n'),
              TextSpan(
                  text: h2,
                  style: const TextStyle(
                      color: kAmber2, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(children: [
            TextSpan(
                text: aum,
                style: const TextStyle(
                    color: kText, fontSize: 18, fontWeight: FontWeight.w600)),
            TextSpan(
                text: '  AUM · $positions positions · $quarter',
                style: const TextStyle(color: kMuted, fontSize: 13)),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Chart area dispatcher
// ─────────────────────────────────────────────
class _ChartArea extends StatelessWidget {
  final String chartType;
  final String filter;
  final List<AllocationItem> allItems;
  final AllocationItem? dominant; // only for donut

  const _ChartArea({
    required this.chartType,
    required this.filter,
    required this.allItems,
    this.dominant,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: switch (chartType) {
        'donut'   => _DonutChart(allItems: allItems, filter: filter, dominant: dominant),
        'bar'     => _BarChart(allItems: allItems, filter: filter),
        'treemap' => _Treemap(allItems: allItems, filter: filter),
        _         => _WorldMap(allItems: allItems),
      },
    );
  }
}

// ─────────────────────────────────────────────
//  World map — countries_world_map SimpleMap
// ─────────────────────────────────────────────
 

 
class _WorldMap extends StatelessWidget {
  final List<AllocationItem> allItems;
  const _WorldMap({required this.allItems});
 
  /// Build a color map for SMapWorldColors from the holdings.
  /// Countries are tinted amber; intensity scales with allocation.
  /// All other countries get the dim background colour.
  Map<String, Color> _buildColorMap() {
    if (allItems.isEmpty) return {};
    print(allItems.map((i) => '${i.code}: ${i.allocationPct}').join(', '));
 
    final maxPct = allItems.map((i) => i.allocationPct).reduce(math.max);
 
    return {
      for (final item in allItems)
        if (item.code.isNotEmpty)
          item.code.toLowerCase(): _allocationColor(item.allocationPct, maxPct),
    };
  }
 
  /// Lerp from a dim amber to bright amber based on relative allocation size.
  Color _allocationColor(double pct, double maxPct) {
    final t = (pct / maxPct).clamp(0.2, 1.0);
    return Color.lerp(kAmber5.withAlpha(140), kAmber1, t)!;
  }
  SMapWorldColors buildSMapColors(Map<String, Color> map) {
  return SMapWorldColors(
    aD: map['ad'],
    aE: map['ae'],
    aF: map['af'],
    aG: map['ag'],
    aI: map['ai'],
    aL: map['al'],
    aM: map['am'],
    aN: map['an'],
    aO: map['ao'],
    aQ: map['aq'],
    aR: map['ar'],
    aS: map['as'],
    aT: map['at'],
    aU: map['au'],
    aW: map['aw'],
    aX: map['ax'],
    aZ: map['az'],

    bA: map['ba'],
    bB: map['bb'],
    bD: map['bd'],
    bE: map['be'],
    bF: map['bf'],
    bG: map['bg'],
    bH: map['bh'],
    bI: map['bi'],
    bJ: map['bj'],
    bL: map['bl'],
    bM: map['bm'],
    bN: map['bn'],
    bO: map['bo'],
    bQ: map['bq'],
    bR: map['br'],
    bS: map['bs'],
    bT: map['bt'],
    bW: map['bw'],
    bY: map['by'],
    bZ: map['bz'],

    cA: map['ca'],
    cC: map['cc'],
    cD: map['cd'],
    cF: map['cf'],
    cG: map['cg'],
    cH: map['ch'],
    cI: map['ci'],
    cL: map['cl'],
    cN: map['cn'],
    cO: map['co'],
    cR: map['cr'],
    cU: map['cu'],
    cV: map['cv'],
    cW: map['cw'],
    cX: map['cx'],
    cY: map['cy'],
    cZ: map['cz'],

    dE: map['de'],
    dK: map['dk'],
    dZ: map['dz'],

    eC: map['ec'],
    eG: map['eg'],
    eS: map['es'],
    eT: map['et'],

    fI: map['fi'],
    fR: map['fr'],

    gB: map['gb'],
    gR: map['gr'],

    iN: map['in'],
    iT: map['it'],

    jP: map['jp'],

    kR: map['kr'],

    nL: map['nl'],
    nO: map['no'],

    pL: map['pl'],
    pT: map['pt'],

    rU: map['ru'],

    sA: map['sa'],
    sE: map['se'],
    sG: map['sg'],

    tR: map['tr'],

    uS: map['us'],

    zA: map['za'],
  );
}
 
  @override
  Widget build(BuildContext context) {
    final largest   = allItems.isNotEmpty ? allItems.first : null;
    final colorMap  = _buildColorMap();
    print('Color map: $colorMap');
 
    // SMapWorldColors accepts individual 2-letter-code named params.
    // We pass the dynamic map via the fromMap constructor.
 
    return Stack(
      children: [
        // ── Map background ───────────────────────────────────────────────
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF16161E),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SimpleMap(
              instructions: SMapWorld.instructions,
              defaultColor: const Color(0xFF2A2A38),
              colors: colorMap,
           
            ),
          ),
        ),
 
        // ── "Largest" highlight card ──────────────────────────────────────
        if (largest != null)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kSurface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LARGEST',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        color: Color(0xFF6A6058)),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text:
                              '${largest.allocationPct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: kAmber2)),
                      TextSpan(
                          text: ' ${largest.name}',
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFC8BFB0))),
                    ]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Donut chart
// ─────────────────────────────────────────────
class _DonutChart extends StatelessWidget {
  final List<AllocationItem> allItems;
  final String filter;
  final AllocationItem? dominant;
  const _DonutChart({
    required this.allItems,
    required this.filter,
    this.dominant,
  });

  @override
  Widget build(BuildContext context) {
    final items = filter == 'all'
        ? allItems
        : allItems.where((h) => h.filterGroup == filter).toList();

    return Center(
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(210, 210),
              painter: _DonutPainter(items: items, allItems: allItems),
            ),
            if (dominant != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('DOMINANT',
                      style: TextStyle(
                          fontSize: 9, letterSpacing: 1.2, color: kMuted)),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: dominant!.allocationPct.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 30,
                              color: kText,
                              fontWeight: FontWeight.w300)),
                      const TextSpan(
                          text: '%',
                          style: TextStyle(fontSize: 16, color: kText)),
                    ]),
                  ),
                  Text(dominant!.name,
                      style: const TextStyle(fontSize: 11, color: kMuted)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<AllocationItem> items;
  final List<AllocationItem> allItems;
  _DonutPainter({required this.items, required this.allItems});

  @override
  void paint(Canvas canvas, Size size) {
    final center   = Offset(size.width / 2, size.height / 2);
    final radius   = size.width / 2 - 4;
    const strokeW  = 32.0;
    final total    = items.fold(0.0, (s, h) => s + h.allocationPct);
    double startAngle = -math.pi / 2;

    for (final item in items) {
      final idx   = allItems.indexOf(item);
      final color = dotColor(idx);
      final sweep = (item.allocationPct / total) * 2 * math.pi;

      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - strokeW / 2),
          startAngle,
          sweep - 0.03,
          false,
          Paint()
            ..color      = color
            ..style      = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap  = StrokeCap.butt);

      // Outer label (code + pct)
      final midAngle = startAngle + sweep / 2;
      final labelR   = radius + 16;
      final lx = center.dx + labelR * math.cos(midAngle);
      final ly = center.dy + labelR * math.sin(midAngle);

      void drawLabel(String text, double dy, double fontSize) {
        final tp = TextPainter(
          text: TextSpan(
              text: text,
              style: TextStyle(fontSize: fontSize, color: kMuted)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly + dy - tp.height / 2));
      }

      drawLabel(item.code, -8, 10);
      drawLabel('${item.allocationPct.toStringAsFixed(0)}%', 4, 9);

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.items != items || old.allItems != allItems;
}

// ─────────────────────────────────────────────
//  Bar chart (Currency tab)
// ─────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<AllocationItem> allItems;
  final String filter;
  const _BarChart({required this.allItems, required this.filter});

  @override
  Widget build(BuildContext context) {
    final items = filter == 'all'
        ? allItems
        : allItems.where((h) => h.filterGroup == filter).toList();
    return CustomPaint(
      size: const Size(double.infinity, 220),
      painter: _BarChartPainter(items: items, allItems: allItems),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<AllocationItem> items;
  final List<AllocationItem> allItems;
  _BarChartPainter({required this.items, required this.allItems});

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;
    const bottomPad = 48.0;
    const topPad    = 30.0;
    const leftPad   = 28.0;
    final chartH = size.height - bottomPad - topPad;
    final maxVal = items.map((h) => h.allocationPct).reduce(math.max);
    final slot   = (size.width - leftPad) / items.length;
    final barW   = slot * 0.55;

    // Grid lines
    final gridPaint = Paint()
      ..color      = const Color(0xFF1E1E2A)
      ..strokeWidth = 0.5;
    for (final v in [17.0, 34.0, 51.0, 68.0]) {
      if (v > maxVal * 1.1) continue;
      final y = topPad + chartH * (1 - v / (maxVal * 1.15));
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
            text: v.toInt().toString(),
            style: const TextStyle(fontSize: 9, color: kMuted)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    for (int i = 0; i < items.length; i++) {
      final item  = items[i];
      final idx   = allItems.indexOf(item);
      final color = dotColor(idx);
      final x     = leftPad + slot * i + slot / 2 - barW / 2;
      final barH  = chartH * (item.allocationPct / (maxVal * 1.15));
      final y     = topPad + chartH - barH;

      // Bar
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, barW, barH), const Radius.circular(4)),
          Paint()..color = color);

      // Currency symbol above bar (look up by ISO code)
      final sym = kCurrencySymbols[item.code] ?? '';
      if (sym.isNotEmpty) {
        final symTp = TextPainter(
          text: TextSpan(
              text: sym,
              style: TextStyle(
                  fontSize: 14, color: color, fontWeight: FontWeight.w300)),
          textDirection: TextDirection.ltr,
        )..layout();
        symTp.paint(
            canvas, Offset(x + barW / 2 - symTp.width / 2, y - 20));
      }

      // Code label
      final codeTp = TextPainter(
        text: TextSpan(
            text: item.code,
            style: const TextStyle(fontSize: 10, color: kMuted)),
        textDirection: TextDirection.ltr,
      )..layout();
      codeTp.paint(canvas,
          Offset(x + barW / 2 - codeTp.width / 2,
              size.height - bottomPad + 6));

      // Pct label (first bar highlighted amber)
      final pctTp = TextPainter(
        text: TextSpan(
            text: '${item.allocationPct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 10, color: i == 0 ? kAmber2 : kMuted)),
        textDirection: TextDirection.ltr,
      )..layout();
      pctTp.paint(canvas,
          Offset(x + barW / 2 - pctTp.width / 2,
              size.height - bottomPad + 18));
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) =>
      old.items != items || old.allItems != allItems;
}

// ─────────────────────────────────────────────
//  Treemap (Sector tab)
// ─────────────────────────────────────────────
class _Treemap extends StatelessWidget {
  final List<AllocationItem> allItems;
  final String filter;
  const _Treemap({required this.allItems, required this.filter});

  @override
  Widget build(BuildContext context) {
    final items = filter == 'all'
        ? allItems
        : allItems.where((h) => h.filterGroup == filter).toList();

    return LayoutBuilder(builder: (ctx, constraints) {
      final rects = _squarify(items, 0, 0, constraints.maxWidth, 220);
      return SizedBox(
        width: constraints.maxWidth,
        height: 220,
        child: Stack(
          children: rects.map((r) {
            final idx  = allItems.indexOf(r.item);
            final color = dotColor(idx);
            final isLight  = idx < 3;
            final textColor = isLight
                ? const Color(0xFF2A1A00)
                : const Color(0xFFF0E0C0);
            return Positioned(
              left:   r.x,
              top:    r.y,
              width:  r.w,
              height: r.h,
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    // Top-left code
                    Positioned(
                      top: 0, left: 0,
                      child: Text(r.item.code,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textColor)),
                    ),
                    // Bottom row: name + pct
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(r.item.name,
                                style: TextStyle(
                                    fontSize: r.h > 80 ? 12 : 10,
                                    color: textColor),
                                overflow: TextOverflow.ellipsis),
                          ),
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: r.item.allocationPct
                                      .toStringAsFixed(0),
                                  style: TextStyle(
                                      fontSize: r.h > 80 ? 15 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: textColor)),
                              TextSpan(
                                  text: '%',
                                  style: TextStyle(
                                      fontSize: r.h > 80 ? 10 : 9,
                                      color: textColor)),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

// ── Squarify layout ───────────────────────────
class _Rect {
  final AllocationItem item;
  final double x, y, w, h;
  _Rect(this.item, this.x, this.y, this.w, this.h);
}

List<_Rect> _squarify(
    List<AllocationItem> items, double x, double y, double w, double h) {
  if (items.isEmpty) return [];
  if (items.length == 1) return [_Rect(items[0], x, y, w, h)];

  final total = items.fold(0.0, (s, i) => s + i.allocationPct);
  final half  = total / 2;
  double acc  = 0;
  int split   = 1;
  for (int i = 0; i < items.length; i++) {
    acc += items[i].allocationPct;
    if (acc >= half) { split = i + 1; break; }
  }
  split = split.clamp(1, items.length - 1);

  final a    = items.sublist(0, split);
  final b    = items.sublist(split);
  final aSum = a.fold(0.0, (s, i) => s + i.allocationPct);
  final bSum = b.fold(0.0, (s, i) => s + i.allocationPct);
  const gap  = 2.0;

  if (w >= h) {
    final aw = (aSum / total) * w - gap / 2;
    final bw = (bSum / total) * w - gap / 2;
    return [..._squarify(a, x, y, aw, h), ..._squarify(b, x + aw + gap, y, bw, h)];
  } else {
    final ah = (aSum / total) * h - gap / 2;
    final bh = (bSum / total) * h - gap / 2;
    return [..._squarify(a, x, y, w, ah), ..._squarify(b, x, y + ah + gap, w, bh)];
  }
}

class _FilterBar extends StatelessWidget {
  final List<FilterGroup> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final active = f.groupKey == selected;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(f.groupKey),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: active ? kAmber2 : kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : const Color(0xFFC8BFB0),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${f.allocationPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: active
                            ? Colors.white70
                            : const Color(0xFF8A8070),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Holdings list  (uses AllocationItem from model)
// ─────────────────────────────────────────────
class _HoldingsSection extends StatelessWidget {
  final List<AllocationItem> holdings;
  final List<AllocationItem> allHoldings; // for colour indexing

  const _HoldingsSection({
    required this.holdings,
    required this.allHoldings,
  });

  @override
  Widget build(BuildContext context) {
    // Bar scale: largest item in the full unfiltered list = 100% width
    final maxPct = allHoldings.isNotEmpty
        ? allHoldings.map((h) => h.allocationPct).reduce(math.max)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('HOLDINGS',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    color: Color(0xFF6A6058))),
            Text('${holdings.length} positions',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6A6058))),
          ],
        ),
        const SizedBox(height: 8),
        ...holdings.map((h) {
          final idx      = allHoldings.indexOf(h);
          final color    = dotColor(idx);
          final barFrac  = (h.allocationPct / maxPct).clamp(0.0, 1.0);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // Colour dot
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    // Short code
                    SizedBox(
                      width: 36,
                      child: Text(h.code,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF7A7060))),
                    ),
                    // Name + sub-label
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: kText,
                                  fontWeight: FontWeight.w500)),
                          Text(h.subLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7A7060))),
                        ],
                      ),
                    ),
                    // Progress bar
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: barFrac,
                          backgroundColor: kDivider,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Percentage
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: h.allocationPct.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xFFC8BFB0))),
                        const TextSpan(
                            text: '%',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF7A7060))),
                      ]),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0, thickness: 0.5, color: kDivider),
            ],
          );
        }),
      ],
    );
  }
}