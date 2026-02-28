import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final LoanService _loanService = LoanService();
  List<LoanExtension> _extensions = [];
  bool _loadingExtensions = true;

  @override
  void initState() {
    super.initState();
    _loadExtensions();
  }

  Future<void> _loadExtensions() async {
    final ext = await _loanService.getMyExtensions(loanId: widget.loan.id);
    if (!mounted) return;
    setState(() {
      _extensions = ext;
      _loadingExtensions = false;
    });
  }

  Color get _statusColor {
    switch (widget.loan.status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'returned':
        return const Color(0xFF3B82F6);
      case 'lost':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final fmt = DateFormat('dd MMM yyyy', 'es');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Detalle del Préstamo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _statusColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  // Material image / icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: loan.materialImageUrl != null &&
                            loan.materialImageUrl!.isNotEmpty
                        ? Image.network(
                            loan.materialImageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _iconPlaceholder(80),
                          )
                        : _iconPlaceholder(80),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    loan.materialName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loan.statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Días restantes (solo activo/vencido) ──────────────────────
            if (loan.status == 'active' || loan.status == 'overdue') ...[
              _DaysIndicator(loan: loan),
              const SizedBox(height: 20),
            ],

            // ── Info grid ────────────────────────────────────────────────
            _sectionTitle('Información del Préstamo'),
            const SizedBox(height: 10),
            _infoGrid([
              _InfoItem(
                icon: Icons.tag,
                label: 'ID Préstamo',
                value: '#${loan.id}',
                color: const Color(0xFF7C3AED),
              ),
              _InfoItem(
                icon: Icons.inventory,
                label: 'Cantidad',
                value: '${loan.quantity} ud.',
                color: const Color(0xFF3B82F6),
              ),
              _InfoItem(
                icon: Icons.calendar_today,
                label: 'Fecha inicio',
                value: fmt.format(loan.issuedAt),
                color: const Color(0xFF10B981),
              ),
              _InfoItem(
                icon: Icons.event,
                label: 'Devolución esperada',
                value: fmt.format(loan.expectedReturnDate),
                color: const Color(0xFFF59E0B),
              ),
              if (loan.actualReturnDate != null)
                _InfoItem(
                  icon: Icons.check_circle_outline,
                  label: 'Devuelto el',
                  value: fmt.format(loan.actualReturnDate!),
                  color: const Color(0xFF10B981),
                ),
              if (loan.condition != null && loan.condition!.isNotEmpty)
                _InfoItem(
                  icon: Icons.info_outline,
                  label: 'Condición',
                  value: loan.condition!,
                  color: Colors.grey,
                ),
            ]),

            // ── Damage notes ─────────────────────────────────────────────
            if (loan.damageNotes != null && loan.damageNotes!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Notas de Daño'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loan.damageNotes!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── QR Code ──────────────────────────────────────────────────
            if (loan.qrToken != null && loan.qrToken!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle('Código QR del Préstamo'),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: loan.qrToken!,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Muestra este QR al devolver el material',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            ],

            // ── Extensions history ────────────────────────────────────────
            const SizedBox(height: 24),
            Row(
              children: [
                _sectionTitle('Extensiones Solicitadas'),
                const Spacer(),
                if (_loadingExtensions)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3AED),
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_loadingExtensions && _extensions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No has solicitado extensiones para este préstamo.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._extensions.map((ext) => _ExtensionCard(extension: ext)),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _iconPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: const Color(0xFF7C3AED),
        size: size * 0.45,
      ),
    );
  }

  Widget _infoGrid(List<_InfoItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: items.map((item) => _buildInfoCard(item)).toList(),
    );
  }

  Widget _buildInfoCard(_InfoItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style:
                      TextStyle(color: Colors.grey[400], fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Days remaining indicator ──────────────────────────────────────────────

class _DaysIndicator extends StatelessWidget {
  final Loan loan;

  const _DaysIndicator({required this.loan});

  Color get _color {
    final days = loan.daysRemaining;
    if (days <= 0) return const Color(0xFFEF4444);
    if (days <= 2) return const Color(0xFFEF4444);
    if (days <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String get _label {
    if (loan.status == 'overdue') {
      final days = loan.expectedReturnDate
          .difference(DateTime.now())
          .inDays
          .abs();
      return 'Vencido hace $days día${days == 1 ? '' : 's'}';
    }
    final days = loan.daysRemaining;
    if (days == 0) return 'Vence hoy';
    if (days == 1) return 'Vence mañana';
    return 'Vence en $days días';
  }

  double get _progress {
    if (loan.status == 'overdue') return 1.0;
    final total =
        loan.expectedReturnDate.difference(loan.issuedAt).inDays.toDouble();
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(loan.issuedAt).inDays.toDouble();
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                loan.status == 'overdue'
                    ? Icons.error_outline
                    : Icons.timer_outlined,
                color: _color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _label,
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(_color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Extension card ─────────────────────────────────────────────────────────

class _ExtensionCard extends StatelessWidget {
  final LoanExtension extension;

  const _ExtensionCard({required this.extension});

  Color get _statusColor {
    switch (extension.status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get _statusLabel {
    switch (extension.status) {
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva fecha: ${fmt.format(extension.newReturnDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (extension.reason != null &&
                    extension.reason!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    extension.reason!,
                    style:
                        TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                color: _statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data class ─────────────────────────────────────────────────────────────

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
