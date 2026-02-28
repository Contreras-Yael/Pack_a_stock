import 'package:flutter/material.dart';
import '../../models/material_model.dart';
import '../../services/material_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/app_drawer.dart';
import '../material/material_detail_screen.dart';

// ─── Shimmer pulse widget ────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.35, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3E),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

// ─── Filter & Sort enums ────────────────────────────────────────────────────

enum _StatusFilter { all, available, unavailable, consumable, lowStock, favorites }

enum _SortOption { nameAsc, nameDesc, stockDesc, stockAsc }

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final MaterialService _materialService = MaterialService();
  final TextEditingController _searchController = TextEditingController();

  List<MaterialItem> _allMaterials = [];
  List<MaterialItem> _filtered = [];
  bool _loading = true;

  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortOption _sortOption = _SortOption.nameAsc;
  String? _categoryFilter;

  List<String> get _categories {
    final cats = _allMaterials
        .map((m) => m.categoryName)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  @override
  void initState() {
    super.initState();
    FavoritesService().load().then((_) => _applyFilters());
    FavoritesService().addListener(_applyFilters);
    _loadMaterials();
  }

  @override
  void dispose() {
    FavoritesService().removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() => _loading = true);
    final materials = await _materialService.getMaterials();
    if (!mounted) return;
    setState(() {
      _allMaterials = materials;
      _loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();

    List<MaterialItem> result = _allMaterials.where((m) {
      if (q.isNotEmpty) {
        final match = m.name.toLowerCase().contains(q) ||
            m.sku.toLowerCase().contains(q) ||
            m.description.toLowerCase().contains(q) ||
            (m.categoryName?.toLowerCase().contains(q) ?? false);
        if (!match) return false;
      }
      if (_categoryFilter != null && m.categoryName != _categoryFilter) {
        return false;
      }
      switch (_statusFilter) {
        case _StatusFilter.available:
          return m.isAvailable;
        case _StatusFilter.unavailable:
          return !m.isAvailable;
        case _StatusFilter.consumable:
          return m.isConsumable;
        case _StatusFilter.lowStock:
          return m.isLowStock;
        case _StatusFilter.favorites:
          return FavoritesService().isFavorite(m.id);
        case _StatusFilter.all:
          return true;
      }
    }).toList();

    switch (_sortOption) {
      case _SortOption.nameAsc:
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case _SortOption.nameDesc:
        result.sort((a, b) => b.name.compareTo(a.name));
        break;
      case _SortOption.stockDesc:
        result.sort((a, b) => b.availableQuantity.compareTo(a.availableQuantity));
        break;
      case _SortOption.stockAsc:
        result.sort((a, b) => a.availableQuantity.compareTo(b.availableQuantity));
        break;
    }

    setState(() => _filtered = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'catalog'),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Catálogo'),
        elevation: 0,
        actions: [
          _buildSortButton(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMaterials,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildResultCount(),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, SKU, categoría...',
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF7C3AED), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.grey, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1A1A2E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('Todos',
              _statusFilter == _StatusFilter.all && _categoryFilter == null,
              onTap: () => setState(() {
                    _statusFilter = _StatusFilter.all;
                    _categoryFilter = null;
                    _applyFilters();
                  })),
          ListenableBuilder(
            listenable: FavoritesService(),
            builder: (_, __) => _chip(
              'Favoritos',
              _statusFilter == _StatusFilter.favorites,
              color: const Color(0xFFF59E0B),
              icon: Icons.star_rounded,
              onTap: () => setState(() {
                _statusFilter = _statusFilter == _StatusFilter.favorites
                    ? _StatusFilter.all
                    : _StatusFilter.favorites;
                _categoryFilter = null;
                _applyFilters();
              }),
            ),
          ),
          _chip('Disponibles', _statusFilter == _StatusFilter.available,
              color: const Color(0xFF10B981),
              onTap: () => setState(() {
                    _statusFilter = _StatusFilter.available;
                    _categoryFilter = null;
                    _applyFilters();
                  })),
          _chip('No disponibles', _statusFilter == _StatusFilter.unavailable,
              color: const Color(0xFFEF4444),
              onTap: () => setState(() {
                    _statusFilter = _StatusFilter.unavailable;
                    _categoryFilter = null;
                    _applyFilters();
                  })),
          _chip('Consumibles', _statusFilter == _StatusFilter.consumable,
              color: const Color(0xFFF59E0B),
              onTap: () => setState(() {
                    _statusFilter = _StatusFilter.consumable;
                    _categoryFilter = null;
                    _applyFilters();
                  })),
          if (_allMaterials.any((m) => m.isLowStock))
            _chip('Stock bajo', _statusFilter == _StatusFilter.lowStock,
                color: const Color(0xFFEF4444),
                icon: Icons.warning_amber_rounded,
                onTap: () => setState(() {
                      _statusFilter = _StatusFilter.lowStock;
                      _categoryFilter = null;
                      _applyFilters();
                    })),
          if (_categories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: VerticalDivider(
                  color: Colors.white.withOpacity(0.15), width: 1),
            ),
          ..._categories.map((cat) => _chip(
                cat,
                _categoryFilter == cat,
                color: const Color(0xFF3B82F6),
                onTap: () => setState(() {
                  _categoryFilter = _categoryFilter == cat ? null : cat;
                  _statusFilter = _StatusFilter.all;
                  _applyFilters();
                }),
              )),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    bool selected, {
    Color color = const Color(0xFF7C3AED),
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 10 : 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? color.withOpacity(0.2) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13, color: selected ? color : Colors.grey[500]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sort popup ─────────────────────────────────────────────────────────────
  Widget _buildSortButton() {
    const options = {
      _SortOption.nameAsc: 'A → Z',
      _SortOption.nameDesc: 'Z → A',
      _SortOption.stockDesc: 'Más stock',
      _SortOption.stockAsc: 'Menos stock',
    };
    return PopupMenuButton<_SortOption>(
      icon: const Icon(Icons.sort_rounded),
      color: const Color(0xFF1A1A2E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (opt) {
        setState(() => _sortOption = opt);
        _applyFilters();
      },
      itemBuilder: (_) => options.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    if (_sortOption == e.key)
                      const Icon(Icons.check,
                          size: 16, color: Color(0xFF7C3AED))
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(e.value,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ── Result count + clear ───────────────────────────────────────────────────
  Widget _buildResultCount() {
    if (_loading) return const SizedBox.shrink();
    final hasFilters = _statusFilter != _StatusFilter.all ||
        _categoryFilter != null ||
        _searchController.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Text(
            '${_filtered.length} resultado${_filtered.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _statusFilter = _StatusFilter.all;
                  _categoryFilter = null;
                  _sortOption = _SortOption.nameAsc;
                });
                _applyFilters();
              },
              child: const Row(
                children: [
                  Icon(Icons.close_rounded,
                      size: 12, color: Color(0xFF7C3AED)),
                  SizedBox(width: 3),
                  Text('Limpiar',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Skeleton loader ────────────────────────────────────────────────────────
  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: _ShimmerBox(
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(height: 13, width: double.infinity),
                  const SizedBox(height: 6),
                  _ShimmerBox(height: 10, width: 80),
                  const Spacer(),
                  _ShimmerBox(height: 10, width: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid ───────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
    if (_loading) {
      return _buildSkeletonGrid();
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty ||
                      _statusFilter != _StatusFilter.all ||
                      _categoryFilter != null
                  ? 'Sin resultados para este filtro'
                  : 'No hay materiales disponibles',
              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMaterials,
      color: const Color(0xFF7C3AED),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: _filtered.length,
        itemBuilder: (context, index) => _buildCard(_filtered[index]),
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────
  Widget _buildCard(MaterialItem m) {
    final available = m.isAvailable;
    final statusColor =
        available ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MaterialDetailScreen(material: m)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: m.isLowStock
                ? const Color(0xFFF59E0B).withOpacity(0.35)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  m.imageUrl != null && m.imageUrl!.isNotEmpty
                      ? Image.network(
                          m.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),

                  // Gradient at bottom of image
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF1A1A2E),
                            const Color(0xFF1A1A2E).withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Status badge — top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        available ? 'Disponible' : 'No disponible',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Consumable / low-stock icon — top left
                  if (m.isConsumable || m.isLowStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: m.isLowStock
                              ? const Color(0xFFF59E0B).withOpacity(0.9)
                              : const Color(0xFF3B82F6).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          m.isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.layers_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // Favorite star — bottom right
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: ListenableBuilder(
                      listenable: FavoritesService(),
                      builder: (_, __) {
                        final isFav = FavoritesService().isFavorite(m.id);
                        return GestureDetector(
                          onTap: () => FavoritesService().toggle(m.id),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isFav
                                  ? const Color(0xFFF59E0B).withOpacity(0.9)
                                  : Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 14,
                              color: isFav ? Colors.white : Colors.white70,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (m.categoryName != null &&
                        m.categoryName!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        m.categoryName!,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${m.availableQuantity} disponibles',
                          style: TextStyle(
                            color: available
                                ? const Color(0xFF10B981)
                                : Colors.grey[600],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF0F0F1E),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 42,
          color: const Color(0xFF7C3AED).withOpacity(0.25),
        ),
      ),
    );
  }
}
