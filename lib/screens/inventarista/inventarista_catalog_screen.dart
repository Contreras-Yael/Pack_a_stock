import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/material_model.dart';
import '../../services/material_service.dart';
import '../../services/inventarista_service.dart';

class InventaristaCatalogScreen extends StatefulWidget {
  const InventaristaCatalogScreen({super.key});

  @override
  State<InventaristaCatalogScreen> createState() =>
      _InventaristaCatalogScreenState();
}

class _InventaristaCatalogScreenState
    extends State<InventaristaCatalogScreen> {
  final MaterialService _service = MaterialService();
  List<MaterialItem> _all = [];
  List<MaterialItem> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _service.getMaterials();
    if (!mounted) return;
    setState(() {
      _all = items;
      _filtered = _applySearch(items, _search);
      _loading = false;
    });
  }

  List<MaterialItem> _applySearch(List<MaterialItem> list, String query) {
    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list
        .where((m) =>
            m.name.toLowerCase().contains(q) ||
            m.sku.toLowerCase().contains(q) ||
            (m.categoryName?.toLowerCase().contains(q) ?? false) ||
            (m.locationName?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  void _onSearch(String query) {
    setState(() {
      _search = query;
      _filtered = _applySearch(_all, query);
    });
  }

  void _onMaterialUpdated(MaterialItem updated) {
    setState(() {
      _all = _all.map((m) => m.id == updated.id ? updated : m).toList();
      _filtered = _applySearch(_all, _search);
    });
  }

  void _openDetail(MaterialItem mat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaterialDetailSheet(
        material: mat,
        onUpdated: _onMaterialUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppPalette.accent));
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: _onSearch,
            style: TextStyle(color: colors.text),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, SKU, categoría...',
              hintStyle: TextStyle(color: colors.textHint),
              prefixIcon:
                  const Icon(Icons.search, color: AppPalette.accent),
              filled: true,
              fillColor: colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppPalette.accent, width: 2),
              ),
            ),
          ),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${_filtered.length} material${_filtered.length != 1 ? 'es' : ''}',
                style: TextStyle(color: colors.textSub, fontSize: 12),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh,
                    color: AppPalette.accent, size: 16),
                label: const Text('Actualizar',
                    style:
                        TextStyle(color: AppPalette.accent, fontSize: 12)),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          color: colors.textHint, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _search.isEmpty
                            ? 'No hay materiales registrados'
                            : 'Sin resultados para "$_search"',
                        style:
                            TextStyle(color: colors.textSub, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppPalette.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) => _MaterialCard(
                      material: _filtered[i],
                      onTap: () => _openDetail(_filtered[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  final MaterialItem material;
  final VoidCallback onTap;
  const _MaterialCard({required this.material, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isAvailable =
        material.status == 'available' && material.availableQuantity > 0;
    final statusColor = material.isLocked
        ? AppPalette.error
        : isAvailable
            ? AppPalette.success
            : AppPalette.warning;
    final borderColor = material.isLocked
        ? AppPalette.error
        : isAvailable
            ? AppPalette.success
            : AppPalette.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: borderColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image / icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppPalette.accent.withOpacity(0.2)),
                ),
                clipBehavior: Clip.antiAlias,
                child: material.imageUrl != null &&
                        material.imageUrl!.isNotEmpty
                    ? Image.network(
                        material.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _iconPlaceholder(),
                      )
                    : _iconPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            material.name,
                            style: TextStyle(
                              color: colors.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (material.isLocked)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppPalette.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    size: 10, color: AppPalette.error),
                                SizedBox(width: 3),
                                Text('Bloqueado',
                                    style: TextStyle(
                                        color: AppPalette.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppPalette.accent),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${material.sku}',
                      style: TextStyle(color: colors.textSub, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            material.isLocked
                                ? 'Bloqueado'
                                : isAvailable
                                    ? 'Disponible'
                                    : 'No disponible',
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Qty
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: colors.textSub),
                        const SizedBox(width: 3),
                        Text(
                          '${material.availableQuantity}/${material.quantity}',
                          style: TextStyle(
                              color: colors.textSub, fontSize: 11),
                        ),
                      ],
                    ),
                    if (material.locationName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: colors.textSub),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              material.locationName!,
                              style: TextStyle(
                                  color: colors.textSub, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.accent.withOpacity(0.6),
            AppPalette.accentLight.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined,
            size: 28, color: Colors.white),
      ),
    );
  }
}

// ─── Detail / Edit bottom sheet ───────────────────────────────────────────────

class _MaterialDetailSheet extends StatefulWidget {
  final MaterialItem material;
  final void Function(MaterialItem updated) onUpdated;

  const _MaterialDetailSheet({
    required this.material,
    required this.onUpdated,
  });

  @override
  State<_MaterialDetailSheet> createState() => _MaterialDetailSheetState();
}

class _MaterialDetailSheetState extends State<_MaterialDetailSheet> {
  final _service = InventaristaService();
  bool _editing = false;
  bool _saving = false;

  late int _qty;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;

  @override
  void initState() {
    super.initState();
    _qty = widget.material.quantity;
    _nameCtrl = TextEditingController(text: widget.material.name);
    _descCtrl = TextEditingController(text: widget.material.description);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = <String, dynamic>{'quantity': _qty};
    if (_editing) {
      payload['name'] = _nameCtrl.text.trim();
      payload['description'] = _descCtrl.text.trim();
    }
    final result = await _service.updateMaterial(widget.material.id, payload);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      // Build updated MaterialItem from response or patch locally
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final updated = MaterialItem(
        id: widget.material.id,
        name: data['name'] as String? ?? _nameCtrl.text.trim(),
        description: data['description'] as String? ?? _descCtrl.text.trim(),
        sku: widget.material.sku,
        qrCode: widget.material.qrCode,
        availableQuantity: data['available_quantity'] as int? ??
            widget.material.availableQuantity,
        quantity: data['quantity'] as int? ?? _qty,
        status: data['status'] as String? ?? widget.material.status,
        imageUrl: widget.material.imageUrl,
        categoryName: widget.material.categoryName,
        locationName: widget.material.locationName,
        isConsumable: widget.material.isConsumable,
        isLowStock: data['is_low_stock'] as bool? ?? widget.material.isLowStock,
        isLocked: widget.material.isLocked,
        nextAvailableDate: widget.material.nextAvailableDate,
      );
      widget.onUpdated(updated);
      if (mounted) Navigator.pop(context);
      _showSnack('Material actualizado', success: true);
    } else {
      _showSnack(result['message'] ?? 'Error al guardar', success: false);
    }
  }

  void _showSnack(String msg, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? AppPalette.success : AppPalette.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mat = widget.material;
    final isAvailable = mat.status == 'available' && mat.availableQuantity > 0;
    final statusColor = mat.isLocked
        ? AppPalette.error
        : isAvailable
            ? AppPalette.success
            : AppPalette.warning;
    final inLoan = mat.quantity - mat.availableQuantity;
    final previewAvailable = (_qty - inLoan).clamp(0, _qty);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textHint.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Detalle de material',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Edit toggle
                  TextButton.icon(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(
                      _editing ? Icons.close_rounded : Icons.edit_rounded,
                      size: 16,
                      color: _editing ? colors.textHint : AppPalette.accent,
                    ),
                    label: Text(
                      _editing ? 'Cancelar' : 'Editar',
                      style: TextStyle(
                        color: _editing ? colors.textHint : AppPalette.accent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Image + basic info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppPalette.accent.withOpacity(0.2)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: mat.imageUrl != null && mat.imageUrl!.isNotEmpty
                            ? Image.network(mat.imageUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imgPlaceholder())
                            : _imgPlaceholder(),
                      ),
                      const SizedBox(width: 16),

                      // Name / SKU / status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_editing)
                              TextField(
                                controller: _nameCtrl,
                                style: TextStyle(
                                    color: colors.text,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: colors.input,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppPalette.accent, width: 2),
                                  ),
                                  hintText: 'Nombre',
                                  hintStyle:
                                      TextStyle(color: colors.textHint),
                                ),
                              )
                            else
                              Text(
                                mat.name,
                                style: TextStyle(
                                  color: colors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text('SKU: ${mat.sku}',
                                style: TextStyle(
                                    color: colors.textHint, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                mat.isLocked
                                    ? 'Bloqueado'
                                    : isAvailable
                                        ? 'Disponible'
                                        : 'No disponible',
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Description
                  _label(colors, 'Descripción'),
                  const SizedBox(height: 6),
                  if (_editing)
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: TextStyle(color: colors.text, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.input,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppPalette.accent, width: 2),
                        ),
                        hintText: 'Sin descripción',
                        hintStyle: TextStyle(color: colors.textHint),
                      ),
                    )
                  else
                    Text(
                      mat.description.isEmpty ? 'Sin descripción' : mat.description,
                      style: TextStyle(color: colors.textSub, fontSize: 13),
                    ),

                  const SizedBox(height: 20),

                  // Category / Location row
                  Row(
                    children: [
                      Expanded(
                        child: _infoTile(
                          colors,
                          icon: Icons.label_outline_rounded,
                          label: 'Categoría',
                          value: mat.categoryName ?? '—',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoTile(
                          colors,
                          icon: Icons.location_on_outlined,
                          label: 'Ubicación',
                          value: mat.locationName ?? '—',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stock control
                  _label(colors, 'Stock total'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _qtyBtn(
                              icon: Icons.remove_rounded,
                              color: AppPalette.error,
                              onTap: () {
                                if (_qty > 0) setState(() => _qty--);
                              },
                            ),
                            const SizedBox(width: 24),
                            Text(
                              '$_qty',
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 24),
                            _qtyBtn(
                              icon: Icons.add_rounded,
                              color: AppPalette.success,
                              onTap: () => setState(() => _qty++),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _stockChip(colors, 'En préstamo', '$inLoan',
                                AppPalette.warning),
                            const SizedBox(width: 12),
                            _stockChip(colors, 'Disponibles',
                                '$previewAvailable', AppPalette.success),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(AppColors colors, String text) => Text(
        text,
        style: TextStyle(
          color: colors.textHint,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );

  Widget _infoTile(AppColors colors,
      {required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppPalette.accent),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: colors.textHint, fontSize: 10, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: colors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _stockChip(AppColors colors, String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: colors.textHint, fontSize: 10)),
      ],
    );
  }

  Widget _qtyBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.accent.withOpacity(0.6),
            AppPalette.accentLight.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, size: 36, color: Colors.white),
      ),
    );
  }
}
