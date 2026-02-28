import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/loan_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/app_drawer.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen>
    with SingleTickerProviderStateMixin {
  final LoanService _loanService = LoanService();
  late TabController _tabController;

  List<Loan> _allLoans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final loans = await _loanService.getMyLoans();
    if (!mounted) return;
    setState(() {
      _allLoans = loans;
      _loading = false;
    });
  }

  List<Loan> get _activeLoans =>
      _allLoans.where((l) => l.status == 'active').toList();

  List<Loan> get _overdueLoans =>
      _allLoans.where((l) => l.status == 'overdue').toList();

  List<Loan> get _historyLoans =>
      _allLoans.where((l) => l.status == 'returned' || l.status == 'lost').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'loans'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Mis Préstamos'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLoans,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C3AED),
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Activos'),
                  if (_activeLoans.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _badge(_activeLoans.length, const Color(0xFF10B981)),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Vencidos'),
                  if (_overdueLoans.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _badge(_overdueLoans.length, const Color(0xFFEF4444)),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Historial'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _LoansList(
                  loans: _activeLoans,
                  emptyMessage: 'No tienes préstamos activos',
                  emptyIcon: Icons.inventory_2_outlined,
                  onRefresh: _loadLoans,
                  onTap: _openDetail,
                  showExtensionButton: true,
                  onExtension: _showExtensionModal,
                ),
                _LoansList(
                  loans: _overdueLoans,
                  emptyMessage: 'No tienes préstamos vencidos',
                  emptyIcon: Icons.check_circle_outline,
                  onRefresh: _loadLoans,
                  onTap: _openDetail,
                  isOverdueList: true,
                  showExtensionButton: true,
                  onExtension: _showExtensionModal,
                ),
                _LoansList(
                  loans: _historyLoans,
                  emptyMessage: 'Tu historial de préstamos está vacío',
                  emptyIcon: Icons.history,
                  onRefresh: _loadLoans,
                  onTap: _openDetail,
                ),
              ],
            ),
    );
  }

  Widget _badge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openDetail(Loan loan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoanDetailScreen(loan: loan)),
    ).then((_) => _loadLoans());
  }

  Future<void> _showExtensionModal(Loan loan) async {
    DateTime selectedDate = loan.expectedReturnDate.add(const Duration(days: 7));
    final reasonController = TextEditingController();
    bool sending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Solicitar Extensión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loan.materialName,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Current return date
                  _infoRow(
                    'Fecha actual de devolución',
                    DateFormat('dd MMM yyyy', 'es').format(loan.expectedReturnDate),
                    Icons.event,
                    const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 16),

                  // New date selector
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: loan.expectedReturnDate.add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF7C3AED),
                                surface: Color(0xFF1A1A2E),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF7C3AED)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_calendar,
                              color: Color(0xFF7C3AED), size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nueva fecha de devolución',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                              Text(
                                DateFormat('dd MMM yyyy', 'es').format(selectedDate),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason field
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Motivo de la extensión (opcional)',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF0F0F1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: sending
                          ? null
                          : () async {
                              setModalState(() => sending = true);
                              final result = await _loanService.requestExtension(
                                loanId: loan.id,
                                newReturnDate: selectedDate,
                                reason: reasonController.text,
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Extensión solicitada exitosamente'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                                _loadLoans();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        result['message'] ?? 'Error al solicitar extensión'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Solicitar Extensión',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

// ─── Loans list widget ─────────────────────────────────────────────────────

class _LoansList extends StatelessWidget {
  final List<Loan> loans;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;
  final void Function(Loan) onTap;
  final bool showExtensionButton;
  final void Function(Loan)? onExtension;
  final bool isOverdueList;

  const _LoansList({
    required this.loans,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
    required this.onTap,
    this.showExtensionButton = false,
    this.onExtension,
    this.isOverdueList = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF7C3AED),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        itemCount: loans.length,
        itemBuilder: (context, index) => _LoanCard(
          loan: loans[index],
          onTap: () => onTap(loans[index]),
          showExtensionButton: showExtensionButton,
          onExtension:
              onExtension != null ? () => onExtension!(loans[index]) : null,
          isOverdue: isOverdueList,
        ),
      ),
    );
  }
}

// ─── Loan card widget ──────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;
  final bool showExtensionButton;
  final VoidCallback? onExtension;
  final bool isOverdue;

  const _LoanCard({
    required this.loan,
    required this.onTap,
    this.showExtensionButton = false,
    this.onExtension,
    this.isOverdue = false,
  });

  Color get _progressColor {
    final days = loan.daysRemaining;
    if (days <= 0) return const Color(0xFFEF4444);
    if (days <= 2) return const Color(0xFFEF4444);
    if (days <= 5) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  double get _progressValue {
    if (loan.status == 'overdue') return 1.0;
    final total =
        loan.expectedReturnDate.difference(loan.issuedAt).inDays.toDouble();
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(loan.issuedAt).inDays.toDouble();
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String get _daysLabel {
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

  @override
  Widget build(BuildContext context) {
    final borderColor = isOverdue
        ? const Color(0xFFEF4444).withOpacity(0.4)
        : Colors.white.withOpacity(0.08);
    final accentColor = isOverdue
        ? const Color(0xFFEF4444)
        : const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  // Material icon/image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: loan.materialImageUrl != null &&
                            loan.materialImageUrl!.isNotEmpty
                        ? Image.network(
                            loan.materialImageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _iconPlaceholder(accentColor),
                          )
                        : _iconPlaceholder(accentColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.materialName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${loan.quantity} unidad${loan.quantity == 1 ? '' : 'es'}',
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      loan.statusLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Progress bar (only for active/overdue)
            if (loan.status == 'active' || loan.status == 'overdue') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _daysLabel,
                          style: TextStyle(
                            color: _progressColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy', 'es')
                              .format(loan.expectedReturnDate),
                          style:
                              TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(_progressColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Dates row for history
            if (loan.status == 'returned' || loan.status == 'lost') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${loan.isConsumable ? 'Recibido' : 'Devuelto'}: ${loan.actualReturnDate != null ? DateFormat('dd MMM yyyy', 'es').format(loan.actualReturnDate!) : '-'}',
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bottom row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  // Issue date
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Desde: ${DateFormat('dd MMM', 'es').format(loan.issuedAt)}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const Spacer(),
                  // Extension button
                  if (showExtensionButton && onExtension != null) ...[
                    TextButton.icon(
                      onPressed: onExtension,
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text('Extensión'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.chevron_right,
                        color: Colors.grey, size: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconPlaceholder(Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child:
          Icon(Icons.inventory_2_outlined, color: color, size: 24),
    );
  }
}
