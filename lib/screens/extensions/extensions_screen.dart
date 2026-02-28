import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/app_drawer.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'extensions'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
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
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : _extensions.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF7C3AED),
                  backgroundColor: const Color(0xFF1A1A2E),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _extensions.length,
                    itemBuilder: (_, i) =>
                        _buildCard(_extensions[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_repeat_rounded,
              size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text('No has solicitado extensiones',
              style: TextStyle(fontSize: 16, color: Colors.grey[400])),
          const SizedBox(height: 6),
          Text('Puedes solicitarlas desde el detalle de un préstamo',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildCard(LoanExtension ext) {
    final info = _statusInfo(ext.status);
    final color = info['color'] as Color;
    final loan = _loansById[ext.loanId];
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
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
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Extensión #${ext.id}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
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
                ),
                if (loan != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.inventory_2_outlined,
                    'Fecha original',
                    fmt.format(loan.expectedReturnDate),
                  ),
                ],
                if (ext.reason != null && ext.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.comment_outlined,
                    'Motivo',
                    ext.reason!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 8),
        Text('$label: ',
            style:
                TextStyle(fontSize: 12, color: Colors.grey[500])),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
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
          'color': const Color(0xFF10B981),
          'icon': Icons.check_circle_outline_rounded,
        },
      'rejected' => {
          'label': 'Rechazada',
          'color': const Color(0xFFEF4444),
          'icon': Icons.cancel_outlined,
        },
      _ => {
          'label': 'Pendiente',
          'color': const Color(0xFFF59E0B),
          'icon': Icons.hourglass_top_rounded,
        },
    };
  }
}
