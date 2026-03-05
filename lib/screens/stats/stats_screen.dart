import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/app_drawer.dart';
import '../../config/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final LoanService _loanService = LoanService();
  List<Loan> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final loans = await _loanService.getMyLoans();
    if (!mounted) return;
    setState(() {
      _loans = loans;
      _loading = false;
    });
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  int get _totalLoans => _loans.length;

  double get _returnRate {
    final returned = _loans.where((l) => l.status == 'returned').toList();
    if (returned.isEmpty) return 0;
    final onTime = returned.where((l) =>
        l.actualReturnDate != null &&
        !l.actualReturnDate!.isAfter(l.expectedReturnDate)).length;
    return onTime / returned.length;
  }

  double get _avgDays {
    if (_loans.isEmpty) return 0;
    final total = _loans.fold<int>(
        0,
        (sum, l) =>
            sum + l.expectedReturnDate.difference(l.issuedAt).inDays);
    return total / _loans.length;
  }

  // Last 6 months — count by month
  List<_MonthCount> get _monthlyData {
    final now = DateTime.now();
    final result = <_MonthCount>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final count = _loans
          .where((l) =>
              l.issuedAt.year == month.year &&
              l.issuedAt.month == month.month)
          .length;
      result.add(_MonthCount(month: month, count: count));
    }
    return result;
  }

  // Top 5 most borrowed materials
  List<MapEntry<String, int>> get _topMaterials {
    final map = <String, int>{};
    for (final l in _loans) {
      map[l.materialName] = (map[l.materialName] ?? 0) + 1;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  static const _pieColors = [
    AppPalette.accent,
    AppPalette.info,
    AppPalette.success,
    AppPalette.warning,
    AppPalette.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      drawer: const AppDrawer(currentRoute: 'stats'),
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.text,
        title: const Text('Mi Resumen'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppPalette.accent))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppPalette.accent,
              backgroundColor: colors.card,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatTiles(colors),
                    const SizedBox(height: 28),
                    _sectionTitle('Préstamos por mes', Icons.bar_chart_rounded, colors),
                    const SizedBox(height: 16),
                    _buildBarChart(colors),
                    const SizedBox(height: 28),
                    _sectionTitle(
                        'Materiales más solicitados', Icons.pie_chart_rounded, colors),
                    const SizedBox(height: 16),
                    _buildPieSection(colors),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Stat tiles ─────────────────────────────────────────────────────────────
  Widget _buildStatTiles(AppColors colors) {
    return Row(
      children: [
        _statTile(
          label: 'Total',
          value: '$_totalLoans',
          sub: 'préstamos',
          color: AppPalette.accent,
          icon: Icons.inventory_2_outlined,
          colors: colors,
        ),
        const SizedBox(width: 10),
        _statTile(
          label: 'Puntualidad',
          value: '${(_returnRate * 100).toStringAsFixed(0)}%',
          sub: 'a tiempo',
          color: _returnRate >= 0.8
              ? AppPalette.success
              : _returnRate >= 0.5
                  ? AppPalette.warning
                  : AppPalette.error,
          icon: Icons.verified_outlined,
          colors: colors,
        ),
        const SizedBox(width: 10),
        _statTile(
          label: 'Promedio',
          value: '${_avgDays.toStringAsFixed(0)}d',
          sub: 'por préstamo',
          color: AppPalette.info,
          icon: Icons.schedule_rounded,
          colors: colors,
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
    required AppColors colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(
                    color: colors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            Text(sub,
                style: TextStyle(color: colors.textHint, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Bar chart ──────────────────────────────────────────────────────────────
  Widget _buildBarChart(AppColors colors) {
    final data = _monthlyData;
    final maxY = data.fold<int>(1, (m, d) => d.count > m ? d.count : m);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: data.every((d) => d.count == 0)
          ? Center(
              child: Text('Sin datos',
                  style: TextStyle(color: colors.textHint)))
          : BarChart(
              BarChartData(
                maxY: (maxY + 1).toDouble(),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.count.toDouble(),
                        color: AppPalette.accent,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: (maxY + 1).toDouble(),
                          color: colors.border.withOpacity(0.3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final label =
                            DateFormat('MMM', 'es').format(data[idx].month);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
                                color: colors.textHint, fontSize: 11),
                          ),
                        );
                      },
                      reservedSize: 26,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: colors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.input,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()}',
                      TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ── Pie chart ──────────────────────────────────────────────────────────────
  Widget _buildPieSection(AppColors colors) {
    final top = _topMaterials;
    if (top.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('Sin datos',
              style: TextStyle(color: colors.textHint)),
        ),
      );
    }

    final total = top.fold<int>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 34,
                sectionsSpace: 2,
                sections: top.asMap().entries.map((e) {
                  final color = _pieColors[e.key % _pieColors.length];
                  final pct = e.value.value / total * 100;
                  return PieChartSectionData(
                    value: e.value.value.toDouble(),
                    color: color,
                    radius: 36,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: top.asMap().entries.map((e) {
                final color = _pieColors[e.key % _pieColors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.key,
                          style: TextStyle(color: colors.text, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '×${e.value.value}',
                        style: TextStyle(
                            color: colors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon, AppColors colors) {
    return Row(
      children: [
        Icon(icon, color: AppPalette.accent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MonthCount {
  final DateTime month;
  final int count;
  const _MonthCount({required this.month, required this.count});
}
