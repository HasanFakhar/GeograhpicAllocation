import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/portfolio_controller.dart';
import '../models/portfolio_model.dart';
import '../utils/format_currency.dart';

const Color _kBg = Color(0xFF0F0F14);
const Color _kSurface = Color(0xFF1A1A24);
const Color _kAmber1 = Color(0xFFF5C842);
const Color _kAmber2 = Color(0xFFD4882A);
const Color _kText = Color(0xFFF0E8D8);
const Color _kMuted = Color(0xFF8A8070);
const Color _kDivider = Color(0xFF252530);

const List<Color> _kDotColors = [
  _kAmber1,
  _kAmber2,
  Color.fromARGB(255, 199, 80, 24),
  Color.fromARGB(255, 252, 47, 32),
  Color(0xFF8C4C12),
  Color(0xFF5E3008),
];

Color _dotColor(int idx) => _kDotColors[idx % _kDotColors.length];

const List<Dimension> _kDimensions = [
  Dimension.assetClass,
  Dimension.region,
  Dimension.sector,
  Dimension.currency,
];

String _headlineTitle(Dimension slice) => '${dimensionLabel[slice]},';
String _headlineSubtitle(Dimension by) =>
    'by ${dimensionLabel[by]!.toLowerCase()}.';

class CrossSectionTab extends StatefulWidget {
  const CrossSectionTab({super.key});

  @override
  State<CrossSectionTab> createState() => _CrossSectionTabState();
}

class _CrossSectionTabState extends State<CrossSectionTab> {
  Dimension _slice = Dimension.assetClass;
  Dimension _by = Dimension.region;
  String _byFilter = 'all';
  String? _expandedKey;

  void _onSlice(Dimension d) {
    if (d == _by) {
      setState(() {
        _by = _slice;
        _slice = d;
        _byFilter = 'all';
        _expandedKey = null;
      });
      return;
    }
    setState(() {
      _slice = d;
      _byFilter = 'all';
      _expandedKey = null;
    });
  }

  void _onBy(Dimension d) {
    if (d == _slice) {
      setState(() {
        _slice = _by;
        _by = d;
        _byFilter = 'all';
        _expandedKey = null;
      });
      return;
    }
    setState(() {
      _by = d;
      _byFilter = 'all';
      _expandedKey = null;
    });
  }

  void _onChip(String groupKey) => setState(() {
    _byFilter = _byFilter == groupKey ? 'all' : groupKey;
  });

  void _toggleExpand(String rowKey) => setState(() {
    _expandedKey = _expandedKey == rowKey ? null : rowKey;
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PortfolioController>(
      builder: (c) {
        if (c.portfolioData.value == null) {
          return const Scaffold(
            backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kAmber2)),
          );
        }

        final rows = c.getCrossSectionRows(_slice, _by, byFilterKey: _byFilter);
        final chips = c.getCrossSectionByChips(_slice, _by);
        final positions = c.getCrossSectionPositions(
          _slice,
          _by,
          byFilterKey: _byFilter,
          sliceFilterKey: _expandedKey,
        );

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CROSS-SECTION',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Color(0xFF9A8F7A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 28,
                        color: _kText,
                        height: 1.25,
                      ),
                      children: [
                        TextSpan(text: '${_headlineTitle(_slice)}\n'),
                        TextSpan(
                          text: _headlineSubtitle(_by),
                          style: const TextStyle(
                            color: _kAmber2,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _DimensionPicker(
                    label: 'SLICE',
                    selected: _slice,
                    disabled: _by,
                    onSelect: _onSlice,
                  ),
                  const SizedBox(height: 14),
                  _DimensionPicker(
                    label: 'BY',
                    selected: _by,
                    disabled: _slice,
                    onSelect: _onBy,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '${dimensionLabel[_slice]!.toUpperCase()} · ${dimensionLabel[_by]!.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A6058),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ByChipRow(chips: chips, selected: _byFilter, onTap: _onChip),
                  const SizedBox(height: 18),
                  ...rows.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    return _SliceRow(
                      row: row,
                      color: _dotColor(idx),
                      expanded: _expandedKey == row.key,
                      byFilter: _byFilter,
                      onTap: () => _toggleExpand(row.key),
                    );
                  }),
                  const SizedBox(height: 24),
                  _PositionsList(
                    positions: positions,
                    scopedToSliceLabel: _expandedKey == null
                        ? null
                        : rows
                              .firstWhere(
                                (r) => r.key == _expandedKey,
                                orElse: () => rows.first,
                              )
                              .label,
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
//   BY picker row
// ─────────────────────────────────────────────
class _DimensionPicker extends StatelessWidget {
  final String label;
  final Dimension selected;
  final Dimension disabled; // the dimension claimed by the other picker
  final ValueChanged<Dimension> onSelect;

  const _DimensionPicker({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A6058),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: _kDimensions.map((d) {
                final active = d == selected;
                final isDisabled = d == disabled;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: active
                            ? (label == 'SLICE' ? _kAmber2 : _kText)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Text(
                        dimensionLabel[d]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? (label == 'SLICE' ? Colors.white : _kBg)
                              : (isDisabled
                                    ? const Color(0xFF45424C)
                                    : _kMuted),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  BY chip row filters of by row
// ─────────────────────────────────────────────
class _ByChipRow extends StatelessWidget {
  final List<FilterGroup> chips;
  final String selected;
  final ValueChanged<String> onTap;

  const _ByChipRow({
    required this.chips,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips.asMap().entries.map((entry) {
          final idx = entry.key;
          final chip = entry.value;
          final active = chip.groupKey == selected;
          return GestureDetector(
            onTap: () => onTap(chip.groupKey),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: active ? _kAmber2.withOpacity(0.16) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? _kAmber2 : _kDivider,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _dotColor(idx),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? _kText : const Color(0xFFC8BFB0),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SLice Row for each slice
// ─────────────────────────────────────────────
class _SliceRow extends StatelessWidget {
  final CrossSectionRow row;
  final Color color;
  final bool expanded;
  final String byFilter;
  final VoidCallback onTap;

  const _SliceRow({
    required this.row,
    required this.color,
    required this.expanded,
    required this.byFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    row.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _SegmentedBar(
                      fillFraction: (row.allocationPct / 100).clamp(0.0, 1.0),
                      segments: row.byBreakdown,
                    ),
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${row.allocationPct.toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: expanded ? color : _kText,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: expanded ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: _kMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: expanded ? _ByBreakdown(row: row) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final double fillFraction;
  final List<AllocationItem> segments;

  const _SegmentedBar({required this.fillFraction, required this.segments});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullWidth = constraints.maxWidth;
        final filledWidth = fullWidth;

        return SizedBox(
          height: 10,
          width: fullWidth,
          child: Stack(
            children: [
              // Track
              ClipRRect(
                // borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 10,
                  width: fullWidth,
                  color: _kDivider,
                ),
              ),
              // Segments
              ClipRRect(
                // borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 10,
                  width: filledWidth,
                  child: segments.isEmpty
                      ? Container(color: _kAmber2)
                      : Row(
                          children: segments.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final seg = entry.value;
                            final frac = (seg.allocationPct / 100).clamp(
                              0.0,
                              1.0,
                            );
                            return Expanded(
                              flex: (frac * 1000).round().clamp(1, 1000000),
                              child: Container(
                                color: _dotColor(idx),
                                margin: idx == segments.length - 1
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.only(right: 1.5),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ByBreakdown extends StatelessWidget {
  final CrossSectionRow row;
  const _ByBreakdown({required this.row});

  @override
  Widget build(BuildContext context) {
    if (row.byBreakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 10, top: 2),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: _kAmber2.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WITHIN THIS SLICE · ${_formatTotal(row.marketValue)} TOTAL',
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A7A5C),
            ),
          ),
          const SizedBox(height: 10),
          ...row.byBreakdown.asMap().entries.map((entry) {
            final idx = entry.key;
            final b = entry.value;
            print('codes ${b.code}');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _dotColor(idx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b.filterGroup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(b.marketValue, b.currencyCode),
                    style: const TextStyle(fontSize: 12, color: _kMuted),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${b.allocationPct.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatTotal(double v) {
    final abs = v.abs();
    if (abs >= 1000000) return '£${(abs / 1000000).toStringAsFixed(0)}M';
    if (abs >= 1000) return '£${(abs / 1000).toStringAsFixed(0)}K';
    return '£${abs.toStringAsFixed(0)}';
  }
}

// ─────────────────────────────────────────────
//  Positions list
// ─────────────────────────────────────────────
class _PositionsList extends StatefulWidget {
  final List<AllocationItem> positions;
  final String? scopedToSliceLabel;
  const _PositionsList({required this.positions, this.scopedToSliceLabel});

  @override
  State<_PositionsList> createState() => _PositionsListState();
}

class _PositionsListState extends State<_PositionsList> {
  @override
  Widget build(BuildContext context) {
    final positions = widget.positions;
    final header = widget.scopedToSliceLabel == null
        ? 'ALL POSITIONS'
        : 'POSITIONS IN SLICE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              header,
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A6058),
              ),
            ),
            Text(
              '${positions.length}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6A6058)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...positions.map((p) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _kAmber2,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  formatCurrency(p.marketValue, p.currencyCode),
                  style: const TextStyle(fontSize: 12, color: _kMuted),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${p.allocationPct.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
