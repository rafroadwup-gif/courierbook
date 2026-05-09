import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_navigation.dart';
import '../../models/booking.dart';
import '../../repositories/booking_repository.dart';
import './widgets/booking_card_widget.dart';
import './widgets/booking_filter_chips_widget.dart';
import './widgets/section_header_widget.dart';
import './widgets/summary_banner_widget.dart';

// ─── Data Model (Display) ───────────────────────────────────────
enum SyncStatus { synced, pending, offline }

class BookingDisplayModel {
  final String id;
  final String consignmentNumber;
  final String customerName;
  final String mobileNumber;
  final double weight;
  final double chargedAmount;
  final double costAmount;
  final double profit;
  final PaymentType paymentType;
  final double codAmount;
  final String courierName;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  BookingDisplayModel({
    required this.id,
    required this.consignmentNumber,
    required this.customerName,
    required this.mobileNumber,
    required this.weight,
    required this.chargedAmount,
    required this.costAmount,
    required this.profit,
    required this.paymentType,
    required this.codAmount,
    required this.courierName,
    required this.createdAt,
    required this.syncStatus,
  });

  factory BookingDisplayModel.fromBooking(Booking booking) {
    return BookingDisplayModel(
      id: booking.id,
      consignmentNumber: booking.consignmentNumber,
      customerName: booking.customerName,
      mobileNumber: booking.mobileNumber,
      weight: booking.weight,
      chargedAmount: booking.chargedAmount,
      costAmount: booking.costAmount,
      profit: booking.profit,
      paymentType: booking.paymentType,
      codAmount: booking.codAmount,
      courierName: booking.courierName,
      createdAt: booking.createdAt,
      syncStatus: SyncStatus.synced,
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────
class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen> {
  final _repository = BookingRepository();
  List<BookingDisplayModel> _allBookings = [];
  List<BookingDisplayModel> _filteredBookings = [];
  String _activeFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSyncing = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _repository.getAllBookings();
      setState(() {
        _allBookings =
            bookings.map(BookingDisplayModel.fromBooking).toList();
      });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _applyFilters();
      }
    }
  }

  void _applyFilters() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    List<BookingDisplayModel> result = List.from(_allBookings);

    // Filter
    switch (_activeFilter) {
      case 'COD':
        result = result
            .where((b) => b.paymentType == PaymentType.cod)
            .toList();
        break;
      case 'Prepaid':
        result = result
            .where((b) => b.paymentType == PaymentType.prepaid)
            .toList();
        break;
      case 'Today':
        result = result.where((b) => b.createdAt.isAfter(todayStart)).toList();
        break;
      case 'Synced':
        result =
            result.where((b) => b.syncStatus == SyncStatus.synced).toList();
        break;
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (b) =>
                b.consignmentNumber.toLowerCase().contains(q) ||
                b.customerName.toLowerCase().contains(q) ||
                b.mobileNumber.contains(q) ||
                b.courierName.toLowerCase().contains(q),
          )
          .toList();
    }

    setState(() => _filteredBookings = result);
  }

  void _onFilterChanged(String filter) {
    setState(() => _activeFilter = filter);
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  Future<void> _onRefresh() async {
    setState(() => _isSyncing = true);
    await _loadBookings();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Bookings refreshed',
              style: GoogleFonts.ibmPlexSans(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Group bookings by date
  Map<String, List<BookingDisplayModel>> get _groupedBookings {
    final Map<String, List<BookingDisplayModel>> groups = {};
    final now = DateTime.now();
    for (final b in _filteredBookings) {
      final d = b.createdAt;
      String label;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        label = 'Today';
      } else if (d.year == now.year &&
          d.month == now.month &&
          d.day == now.day - 1) {
        label = 'Yesterday';
      } else {
        label =
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
      groups.putIfAbsent(label, () => []).add(b);
    }
    return groups;
  }

  // Today's stats
  List<BookingDisplayModel> get _todayBookings {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return _allBookings.where((b) => b.createdAt.isAfter(start)).toList();
  }

  double get _todayTotalCharged =>
      _todayBookings.fold(0, (sum, b) => sum + b.chargedAmount);
  double get _todayTotalProfit =>
      _todayBookings.fold(0, (sum, b) => sum + b.profit);
  double get _todayCodPending => _todayBookings
      .where((b) => b.paymentType == PaymentType.cod)
      .fold(0, (sum, b) => sum + b.codAmount);

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final groups = _groupedBookings;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: const Color(0x1A1565C0),
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CourierBook',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A2340),
              ),
            ),
            Text(
              'All Bookings',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF546E7A),
              ),
            ),
          ],
        ),
        actions: [
          // Sync button
          IconButton(
            onPressed: _isSyncing ? null : _onRefresh,
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Icon(
                    Icons.sync_rounded,
                    color: AppTheme.primary,
                    size: 22,
                  ),
            tooltip: 'Refresh bookings',
          ),
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.signUpLoginScreen),
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF90A4AE),
              size: 22,
            ),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      // Summary Banner
                      SummaryBannerWidget(
                        bookingCount: _todayBookings.length,
                        totalCharged: _todayTotalCharged,
                        totalProfit: _todayTotalProfit,
                        codPending: _todayCodPending,
                      ),
                      const SizedBox(height: 14),

                      // Search Bar
                      _SearchBarWidget(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips
                      BookingFilterChipsWidget(
                        activeFilter: _activeFilter,
                        onFilterChanged: _onFilterChanged,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // Content
              if (_isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const BookingCardSkeletonWidget(),
                    childCount: 5,
                  ),
                )
              else if (_filteredBookings.isEmpty)
                SliverFillRemaining(
                  child: EmptyStateWidget(
                    iconName: 'local_shipping',
                    title: 'No bookings found',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'No results for "$_searchQuery". Try a different search.'
                        : 'No bookings match the selected filter. Create a new booking to get started.',
                    actionLabel: 'New Booking',
                    onAction: () => Navigator.pushNamed(
                      context,
                      AppRoutes.bookingFormScreen,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 4,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final keys = groups.keys.toList();
                        int itemIndex = 0;
                        for (final key in keys) {
                          if (index == itemIndex) {
                            // Section header
                            return Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: SectionHeaderWidget(
                                label: key,
                                count: groups[key]!.length,
                              ),
                            );
                          }
                          itemIndex++;
                          final groupItems = groups[key]!;
                          for (int i = 0; i < groupItems.length; i++) {
                            if (index == itemIndex) {
                              return _AnimatedBookingCard(
                                booking: groupItems[i],
                                animationIndex: itemIndex,
                              );
                            }
                            itemIndex++;
                          }
                        }
                        return null;
                      },
                      childCount: groups.entries.fold<int>(
                        0,
                        (sum, e) => sum + 1 + e.value.length,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.bookingFormScreen),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'New Booking',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: const AppNavigation(currentIndex: 0),
    );
  }
}

class _AnimatedBookingCard extends StatefulWidget {
  final BookingDisplayModel booking;
  final int animationIndex;

  const _AnimatedBookingCard({
    required this.booking,
    required this.animationIndex,
  });

  @override
  State<_AnimatedBookingCard> createState() => _AnimatedBookingCardState();
}

class _AnimatedBookingCardState extends State<_AnimatedBookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(
      milliseconds: (widget.animationIndex * 40).clamp(0, 400),
    );
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BookingCardWidget(booking: widget.booking),
        ),
      ),
    );
  }
}

class _SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBarWidget({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.outlineVariantLight),
        boxShadow: [
          BoxShadow(
            color: const Color(0x061565C0),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF90A4AE)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                color: const Color(0xFF1A2340),
              ),
              decoration: InputDecoration(
                hintText: 'Search by consignment, customer, courier...',
                hintStyle: GoogleFonts.ibmPlexSans(
                  fontSize: 13,
                  color: const Color(0xFF90A4AE),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFF90A4AE),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
