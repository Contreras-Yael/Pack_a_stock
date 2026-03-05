import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/app_drawer.dart';
import '../../config/app_colors.dart';

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  final LoanService _loanService = LoanService();

  List<LoanExtension> _extensions = [];
  Map<int, Loan> _loansById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _loanService.getMyExtensions(),
      _loanService.getMyLoans(),
    ]);
    if (!mounted) return;
    final extensions = results[0] as List<LoanExtension>;
    final loans = results[1] as List<Loan>;
    setState(() {
      _extensions = extensions
        ..sort((a, b) => b.id.compareTo(a.id));
      _loansById = {for (final l in loans) l.id: l};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      drawer: const AppDrawer(currentRoute: 'extensions'),
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.text,
        title: const Text('Mis Extensiones'),
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
          : _extensions.isEmpty
              ? _buildEmpty(colors)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppPalette.accent,
                  backgroundColor: colors.card,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _extensions.length,
                    itemBuilder: (_, i) =>
                        _buildCard(_extensions[i], colors),
                  ),
                ),
    );
  }

  Widget _buildEmpty(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_repeat_rounded,
              size: 64, color: colors.textHint),
          const SizedBox(height: 16),
          Text('No has solicitado extensiones',
              style: TextStyle(fontSize: 16, color: colors.textSub)),
          const SizedBox(height: 6),
          Text('Puedes solicitarlas desde el detalle de un préstamo',
              style: TextStyle(fontSize: 13, color: colors.textHint),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCard(LoanExtension ext, AppColors colors) {
    final info = _statusInfo(ext.status);
    final color = info['color'] as Color;
    final loan = _loansById[ext.loanId];
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(info['icon'] as IconData,
                      color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan?.materialName ?? 'Préstamo #${ext.loanId}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Extensión #${ext.id}',
                        style: TextStyle(
                            fontSize: 11, color: colors.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    info['label'] as String,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _infoRow(
                  Icons.event_available_rounded,
                  'Nueva fecha solicitada',
                  fmt.format(ext.newReturnDate),
                  colors,
                ),
                if (loan != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.inventory_2_outlined,
                    'Fecha original',
                    fmt.format(loan.expectedReturnDate),
                    colors,
                  ),
                ],
                if (ext.reason != null && ext.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.comment_outlined,
                    'Motivo',
                    ext.reason!,
                    colors,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, AppColors colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppPalette.accent),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: colors.textHint)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
                fontSize: 12,
                color: colors.text,
                fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    return switch (status) {
      'approved' => {
          'label': 'Aprobada',
          'color': AppPalette.success,
          'icon': Icons.check_circle_outline_rounded,
        },
      'rejected' => {
          'label': 'Rechazada',
          'color': AppPalette.error,
          'icon': Icons.cancel_outlined,
        },
      _ => {
          'label': 'Pendiente',
          'color': AppPalette.warning,
          'icon': Icons.hourglass_top_rounded,
        },
    };
  }
}
