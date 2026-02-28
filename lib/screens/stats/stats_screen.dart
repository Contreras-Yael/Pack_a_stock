import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/app_drawer.dart';

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
    Color(0xFF7C3AED),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'stats'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF7C3AED),
              backgroundColor: const Color(0xFF1A1A2E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatTiles(),
                    const SizedBox(height: 28),
                    _sectionTitle('Préstamos por mes', Icons.bar_chart_rounded),
                    const SizedBox(height: 16),
                    _buildBarChart(),
                    const SizedBox(height: 28),
                    _sectionTitle(
                        'Materiales más solicitados', Icons.pie_chart_rounded),
                    const SizedBox(height: 16),
                    _buildPieSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Stat tiles ─────────────────────────────────────────────────────────────
  Widget _buildStatTiles() {
    return Row(
      children: [
        _statTile(
          label: 'Total',
          value: '$_totalLoans',
          sub: 'préstamos',
          color: const Color(0xFF7C3AED),
          icon: Icons.inventory_2_outlined,
        ),
        const SizedBox(width: 10),
        _statTile(
          label: 'Puntualidad',
          value: '${(_returnRate * 100).toStringAsFixed(0)}%',
          sub: 'a tiempo',
          color: _returnRate >= 0.8
              ? const Color(0xFF10B981)
              : _returnRate >= 0.5
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444),
          icon: Icons.verified_outlined,
        ),
        const SizedBox(width: 10),
        _statTile(
          label: 'Promedio',
          value: '${_avgDays.toStringAsFixed(0)}d',
          sub: 'por préstamo',
          color: const Color(0xFF3B82F6),
          icon: Icons.schedule_rounded,
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
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
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
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
            Text(sub,
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Bar chart ──────────────────────────────────────────────────────────────
  Widget _buildBarChart() {
    final data = _monthlyData;
    final maxY = data.fold<int>(1, (m, d) => d.count > m ? d.count : m);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: data.every((d) => d.count == 0)
          ? Center(
              child: Text('Sin datos',
                  style: TextStyle(color: Colors.grey[600])))
          : BarChart(
              BarChartData(
                maxY: (maxY + 1).toDouble(),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.count.toDouble(),
                        color: const Color(0xFF7C3AED),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: (maxY + 1).toDouble(),
                          color: Colors.white.withOpacity(0.04),
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
                                color: Colors.grey[500], fontSize: 11),
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
                    color: Colors.white.withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2A2A3E),
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      '${rod.toY.toInt()}',
                      const TextStyle(
                          color: Colors.white,
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
  Widget _buildPieSection() {
    final top = _topMaterials;
    if (top.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text('Sin datos',
              style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    final total = top.fold<int>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '×${e.value.value}',
                        style: TextStyle(
                            color: Colors.grey[500],
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
  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7C3AED), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
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
