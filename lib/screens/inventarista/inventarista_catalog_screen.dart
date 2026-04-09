import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/material_model.dart';
import '../../services/material_service.dart';

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
      _filtered = items;
      _loading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _search = query;
      if (query.isEmpty) {
        _filtered = _all;
      } else {
        final q = query.toLowerCase();
        _filtered = _all
            .where((m) =>
                m.name.toLowerCase().contains(q) ||
                m.sku.toLowerCase().contains(q) ||
                (m.categoryName?.toLowerCase().contains(q) ?? false) ||
                (m.locationName?.toLowerCase().contains(q) ?? false))
            .toList();
      }
    });
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
                    itemBuilder: (_, i) =>
                        _MaterialCard(material: _filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialItem material;
  const _MaterialCard({required this.material});

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

    return Container(
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
