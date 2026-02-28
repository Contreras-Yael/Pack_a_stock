import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../scanner/qr_scanner_screen.dart';
import '../cart/cart_screen.dart';
import '../history/history_screen.dart';
import '../loans/loans_screen.dart';
import '../notifications/notifications_screen.dart';
import '../stats/stats_screen.dart';
import '../../widgets/app_drawer.dart';
import '../../services/auth_Service.dart';
import '../../services/order_service.dart';
import '../../services/loan_service.dart';
import '../../services/notification_service.dart';
import '../../services/cart_service.dart';
import '../../models/order_model.dart';
import '../../models/loan_model.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  final LoanService _loanService = LoanService();

  User? _user;
  List<Order> _allOrders = [];
  List<Loan> _loans = [];
  bool _loading = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _authService.getProfile(),
      _orderService.getMyRequests(),
      _loanService.getMyLoans(),
    ]);
    if (!mounted) return;
    NotificationService().startPolling();
    setState(() {
      _user = results[0] as User?;
      _allOrders = results[1] as List<Order>;
      _loans = results[2] as List<Loan>;
      _loading = false;
    });
    _animCtrl.forward(from: 0);
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  List<Loan> get _activeLoans =>
      _loans.where((l) => l.status == 'active').toList()
        ..sort((a, b) => a.expectedReturnDate.compareTo(b.expectedReturnDate));
  List<Loan> get _overdueLoans =>
      _loans.where((l) => l.status == 'overdue').toList();
  int get _pendingRequests =>
      _allOrders.where((o) => o.status == 'pending').length;
  List<Order> get _recentOrders => _allOrders.take(3).toList();
  bool get _isBlocked => _user?.isBlocked == true;

  // Score: 100 base, -20 per overdue, min 0
  int get _trustScore =>
      (_overdueLoans.isEmpty ? 100 : (100 - _overdueLoans.length * 20).clamp(0, 100));

  // Time-based gradient
  List<Color> get _heroGradient {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) {
      return [const Color(0xFF78350F), const Color(0xFF1C1625)]; // mañana — ámbar
    } else if (h >= 12 && h < 17) {
      return [const Color(0xFF1E3A5F), const Color(0xFF0F0F1E)]; // tarde — azul
    } else if (h >= 17 && h < 21) {
      return [const Color(0xFF3B0764), const Color(0xFF1A1A2E)]; // noche — púrpura
    } else {
      return [const Color(0xFF0F172A), const Color(0xFF0F0F1E)]; // madrugada — índigo
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _trustLabel {
    if (_trustScore >= 90) return 'Excelente ✦';
    if (_trustScore >= 70) return 'Bueno';
    if (_trustScore >= 40) return 'Regular';
    return 'En riesgo';
  }

  Color get _trustColor {
    if (_trustScore >= 90) return const Color(0xFF10B981);
    if (_trustScore >= 70) return const Color(0xFF3B82F6);
    if (_trustScore >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      drawer: const AppDrawer(currentRoute: 'home'),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFF1A1A2E),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildHero(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  if (!_loading && _isBlocked) ...[
                    _buildPenaltyBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildScanButton(),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED), strokeWidth: 2))
                  else ...[
                    _buildAnimatedRings(),
                    if (_overdueLoans.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildOverdueBanner(),
                    ],
                    if (_activeLoans.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _buildSectionTitle('Préstamos activos', onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoansScreen()));
                      }),
                      const SizedBox(height: 14),
                      _buildLoanCards(),
                    ],
                    const SizedBox(height: 28),
                    _buildSectionTitle('Solicitudes recientes', onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoryScreen()));
                    }),
                    const SizedBox(height: 12),
                    _buildRecentOrders(),
                    const SizedBox(height: 28),
                    _buildQuickActions(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    final firstName = _user?.fullName.split(' ').first ?? 'Empleado';
    final today = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        ListenableBuilder(
          listenable: NotificationService(),
          builder: (_, __) {
            final count = NotificationService().unreadCount;
            return GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 22),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle),
                          constraints: const BoxConstraints(
                              minWidth: 16, minHeight: 16),
                          child: Text('$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Greeting — bottom-left
              Positioned(
                left: 20,
                right: 110,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _greeting,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      today,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.55)),
                    ),
                  ],
                ),
              ),

              // Trust score ring — bottom-right, perfectly aligned
              if (!_loading)
                Positioned(
                  right: 20,
                  bottom: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const StatsScreen())),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 0.0,
                                    end: _trustScore / 100),
                                duration:
                                    const Duration(milliseconds: 1400),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => CircularProgressIndicator(
                                  value: v,
                                  strokeWidth: 5,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.15),
                                  valueColor:
                                      AlwaysStoppedAnimation(_trustColor),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              TweenAnimationBuilder<int>(
                                tween: IntTween(begin: 0, end: _trustScore),
                                duration:
                                    const Duration(milliseconds: 1400),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => Text(
                                  '$v',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _trustColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _trustLabel,
                          style: TextStyle(
                              color: _trustColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Animated rings row ────────────────────────────────────────────────────
  Widget _buildAnimatedRings() {
    final rings = [
      (
        label: 'Activos',
        value: _activeLoans.length,
        maxVal: (_activeLoans.length + 1).clamp(1, 20),
        color: const Color(0xFF7C3AED),
        icon: Icons.inventory_2_outlined,
      ),
      (
        label: 'Pendientes',
        value: _pendingRequests,
        maxVal: (_pendingRequests + 1).clamp(1, 20),
        color: const Color(0xFFF59E0B),
        icon: Icons.hourglass_top_rounded,
      ),
      (
        label: 'Vencidos',
        value: _overdueLoans.length,
        maxVal: (_overdueLoans.length + 1).clamp(1, 20),
        color: _overdueLoans.isEmpty
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        icon: _overdueLoans.isEmpty
            ? Icons.check_circle_outline_rounded
            : Icons.warning_rounded,
      ),
    ];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Row(
        children: rings.map((r) {
          final idx = rings.indexOf(r);
          return Expanded(
            child: Container(
              margin: idx < rings.length - 1
                  ? const EdgeInsets.only(right: 10)
                  : EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: r.color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                              begin: 0.0,
                              end: r.value / r.maxVal),
                          duration: Duration(milliseconds: 900 + idx * 150),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => CircularProgressIndicator(
                            value: v,
                            strokeWidth: 4.5,
                            backgroundColor: r.color.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation(r.color),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: r.value),
                          duration: Duration(milliseconds: 900 + idx * 150),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => Text(
                            '$v',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: r.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(r.icon, color: r.color, size: 14),
                  const SizedBox(height: 3),
                  Text(
                    r.label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Loan cards carousel ───────────────────────────────────────────────────
  Widget _buildLoanCards() {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: _activeLoans.length,
        itemBuilder: (_, i) => _buildLoanCard(_activeLoans[i], i),
      ),
    );
  }

  Widget _buildLoanCard(Loan loan, int idx) {
    final diff = loan.expectedReturnDate.difference(DateTime.now());
    final totalDiff =
        loan.expectedReturnDate.difference(loan.issuedAt);
    final progress = totalDiff.inMinutes > 0
        ? (1 - diff.inMinutes / totalDiff.inMinutes).clamp(0.0, 1.0)
        : 1.0;

    final Color c1, c2;
    final String timeLabel;

    if (diff.isNegative || diff.inDays == 0) {
      c1 = const Color(0xFF7F1D1D);
      c2 = const Color(0xFF991B1B);
      timeLabel = diff.isNegative ? 'Vencido' : 'Hoy';
    } else if (diff.inDays <= 2) {
      c1 = const Color(0xFF78350F);
      c2 = const Color(0xFF92400E);
      timeLabel = diff.inDays == 1
          ? '1 día restante'
          : '${diff.inDays} días restantes';
    } else {
      c1 = const Color(0xFF1E1B4B);
      c2 = const Color(0xFF312E81);
      timeLabel = '${diff.inDays} días restantes';
    }

    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (_, __) => Opacity(
        opacity: _fadeAnim.value,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c1, c2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: c2.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loan.materialName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'x${loan.quantity}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Ring
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: Duration(
                          milliseconds: 1200 + idx * 100),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) =>
                          CircularProgressIndicator(
                        value: v,
                        strokeWidth: 5,
                        backgroundColor:
                            Colors.white.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(
                          diff.isNegative
                              ? const Color(0xFFEF4444)
                              : diff.inDays <= 2
                                  ? const Color(0xFFF59E0B)
                                  : Colors.white,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(Icons.inventory_2_outlined,
                        color: Colors.white.withOpacity(0.7),
                        size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scan button ───────────────────────────────────────────────────────────
  Widget _buildScanButton() {
    final blocked = _isBlocked;
    return GestureDetector(
      onTap: () {
        if (blocked) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No puedes solicitar materiales mientras tengas una penalización activa.'),
            backgroundColor: Color(0xFFEA580C),
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()));
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: blocked
              ? const LinearGradient(
                  colors: [Color(0xFF374151), Color(0xFF4B5563)])
              : const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: blocked
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      blocked ? Icons.lock_rounded : Icons.qr_code_scanner,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blocked ? 'Acceso bloqueado' : 'Escanear QR',
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      Text(
                        blocked
                            ? 'Penalización activa'
                            : 'Solicita o recibe materiales',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.75)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Penalty banner ────────────────────────────────────────────────────────
  Widget _buildPenaltyBanner() {
    final until = _user?.blockedUntil;
    String timeText = '';
    if (until != null) {
      final diff = until.difference(DateTime.now());
      if (diff.inDays > 0) {
        timeText = '${diff.inDays} día${diff.inDays != 1 ? 's' : ''} restantes';
      } else if (diff.inHours > 0) {
        timeText = '${diff.inHours} hora${diff.inHours != 1 ? 's' : ''} restantes';
      } else if (diff.inMinutes > 0) {
        timeText = 'Menos de 1 hora restante';
      } else {
        timeText = 'Expirada — contacta a tu administrador';
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEA580C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_rounded,
                color: Color(0xFFEA580C), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cuenta penalizada',
                    style: TextStyle(
                        color: Color(0xFFEA580C),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                if (_user?.blockedReason != null &&
                    _user!.blockedReason!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_user!.blockedReason!,
                      style: TextStyle(
                          color: const Color(0xFFEA580C).withOpacity(0.85),
                          fontSize: 12)),
                ],
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(timeText,
                      style: TextStyle(
                          color: const Color(0xFFEA580C).withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Overdue banner ────────────────────────────────────────────────────────
  Widget _buildOverdueBanner() {
    final count = _overdueLoans.length;
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoansScreen())),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded,
                color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tienes $count préstamo${count > 1 ? 's' : ''} vencido${count > 1 ? 's' : ''}. Devuelve los materiales.',
                style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFEF4444), size: 18),
          ],
        ),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text('Ver todo',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  // ── Recent orders ─────────────────────────────────────────────────────────
  Widget _buildRecentOrders() {
    if (_recentOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 32, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text('Sin solicitudes recientes',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: _recentOrders.map((order) {
        final info = _statusInfo(order.status);
        final color = info['color'] as Color;
        final title = order.items.isNotEmpty
            ? order.items.map((i) => i.materialName).join(', ')
            : 'Solicitud #${order.id}';
        final time = DateFormat('dd MMM', 'es').format(order.createdAt);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: [
                Container(
                    width: 4,
                    height: 34,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(time,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(info['label'] as String,
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    final blocked = _isBlocked;
    return ListenableBuilder(
      listenable: CartService(),
      builder: (context, _) {
        final cartCount = CartService().itemCount;
        final actions = [
          (
            icon: blocked
                ? Icons.remove_shopping_cart_outlined
                : Icons.shopping_cart_outlined,
            label: 'Carrito',
            color: blocked
                ? const Color(0xFF6B7280)
                : const Color(0xFF10B981),
            badge: (!blocked && cartCount > 0) ? cartCount : 0,
            onTap: () {
              if (blocked) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'No puedes realizar pedidos mientras tengas una penalización activa.'),
                  backgroundColor: Color(0xFFEA580C),
                  behavior: SnackBarBehavior.floating,
                ));
                return;
              }
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
          (
            icon: Icons.history_rounded,
            label: 'Historial',
            color: const Color(0xFF3B82F6),
            badge: 0,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
          (
            icon: Icons.swap_horiz_rounded,
            label: 'Préstamos',
            color: const Color(0xFF7C3AED),
            badge: 0,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoansScreen())),
          ),
        ];

        return Row(
          children: actions.asMap().entries.map((entry) {
            final idx = entry.key;
            final a = entry.value;
            return Expanded(
              child: GestureDetector(
                onTap: a.onTap,
                child: Container(
                  margin: idx < actions.length - 1
                      ? const EdgeInsets.only(right: 10)
                      : EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(a.icon, color: a.color, size: 24),
                          if (a.badge > 0)
                            Positioned(
                              right: -7,
                              top: -7,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${a.badge}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(a.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Map<String, dynamic> _statusInfo(String status) {
    const map = {
      'pending': {'label': 'Pendiente', 'color': Color(0xFFF59E0B)},
      'approved': {'label': 'Aprobado', 'color': Color(0xFF3B82F6)},
      'rejected': {'label': 'Rechazado', 'color': Color(0xFFEF4444)},
      'completed': {'label': 'Completado', 'color': Color(0xFF10B981)},
      'returned': {'label': 'Devuelto', 'color': Color(0xFF6B7280)},
      'cancelled': {'label': 'Cancelado', 'color': Color(0xFF9CA3AF)},
    };
    return (map[status] ?? {'label': status, 'color': Colors.grey})
        as Map<String, dynamic>;
  }
}
