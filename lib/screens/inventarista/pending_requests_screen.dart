import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/pending_request_model.dart';
import '../../services/inventarista_service.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final InventaristaService _service = InventaristaService();
  List<PendingRequest> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await _service.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar las solicitudes';
        _loading = false;
      });
    }
  }

  void _showActionDialog(PendingRequest request, bool isApprove) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: isApprove ? AppPalette.success : AppPalette.error,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              isApprove ? 'Aprobar solicitud' : 'Rechazar solicitud',
              style: TextStyle(
                  color: context.colors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? '¿Aprobar la solicitud de ${request.requesterName}?'
                  : '¿Rechazar la solicitud de ${request.requesterName}?',
              style:
                  TextStyle(color: context.colors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              style: TextStyle(color: context.colors.text),
              decoration: InputDecoration(
                hintText: isApprove
                    ? 'Notas opcionales'
                    : 'Motivo del rechazo (opcional)',
                hintStyle: TextStyle(color: context.colors.textHint),
                filled: true,
                fillColor: context.colors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isApprove ? AppPalette.success : AppPalette.error,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: context.colors.textSub)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _handleAction(request.id, isApprove, notesCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isApprove ? AppPalette.success : AppPalette.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isApprove ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(int id, bool isApprove, String notes) async {
    final result = isApprove
        ? await _service.approveLoanRequest(id, notes: notes)
        : await _service.rejectLoanRequest(id, reason: notes);

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApprove
              ? 'Solicitud aprobada correctamente'
              : 'Solicitud rechazada'),
          backgroundColor:
              isApprove ? AppPalette.success : AppPalette.error,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al procesar'),
          backgroundColor: AppPalette.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppPalette.accent));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppPalette.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: colors.textSub)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.card,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_outlined,
                  color: colors.textHint, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Sin solicitudes pendientes',
                style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            const SizedBox(height: 6),
            Text('No hay préstamos esperando aprobación',
                style:
                    TextStyle(color: colors.textSub, fontSize: 13)),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: AppPalette.accent),
              label: const Text('Actualizar',
                  style: TextStyle(color: AppPalette.accent)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppPalette.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _RequestCard(
          request: _requests[i],
          onApprove: () => _showActionDialog(_requests[i], true),
          onReject: () => _showActionDialog(_requests[i], false),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PendingRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('dd MMM yyyy', 'es');

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: const BorderSide(color: AppPalette.warning, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: requester + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppPalette.accent.withOpacity(0.15),
                  child: Text(
                    request.requesterName.isNotEmpty
                        ? request.requesterName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppPalette.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      Text(
                        request.requesterEmail,
                        style: TextStyle(
                            color: colors.textSub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppPalette.warning.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'Pendiente',
                    style: TextStyle(
                        color: AppPalette.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            if (request.pickupDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: colors.textSub),
                  const SizedBox(width: 6),
                  Text(
                    'Recogida: ${dateFmt.format(request.pickupDate!)}',
                    style: TextStyle(
                        color: colors.textSub, fontSize: 12),
                  ),
                  if (request.returnDate != null) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.event_available_outlined,
                        size: 14, color: colors.textSub),
                    const SizedBox(width: 6),
                    Text(
                      'Devolución: ${dateFmt.format(request.returnDate!)}',
                      style: TextStyle(
                          color: colors.textSub, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],

            // Items
            if (request.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Materiales solicitados',
                      style: TextStyle(
                          color: colors.textSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    ...request.items.map((item) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle,
                                  size: 6, color: AppPalette.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.materialName,
                                  style: TextStyle(
                                      color: colors.text, fontSize: 13),
                                ),
                              ),
                              Text(
                                'x${item.quantity}',
                                style: TextStyle(
                                    color: AppPalette.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            // Purpose
            if (request.purpose != null && request.purpose!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '"${request.purpose}"',
                style: TextStyle(
                    color: colors.textSub,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ],

            const SizedBox(height: 14),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: AppPalette.error),
                    label: const Text('Rechazar',
                        style: TextStyle(color: AppPalette.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppPalette.error, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Aprobar',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPalette.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
