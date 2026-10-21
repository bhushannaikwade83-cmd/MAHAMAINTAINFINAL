import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../main.dart' show authRepositoryProvider;
import '../models/job_models.dart';
import '../state/partner_app_state.dart';
import '../widgets/job_card.dart';
import '../repositories/job_categories_repository.dart';
import '../widgets/debug_console.dart';

class HomeTab extends ConsumerStatefulWidget {
  final Function(int) onJobTap;
  const HomeTab({required this.onJobTap, Key? key}) : super(key: key);

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  late JobCategoriesRepository _categoriesRepository;
  List<JobCategory> _categories = [];
  bool _loadingCategories = true;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _categoriesRepository = JobCategoriesRepository();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final vendorId = ref.read(authRepositoryProvider).getCurrentUserId();
    if (vendorId == null) return;

    setState(() => _loadingCategories = true);
    try {
      final categories = await _categoriesRepository.fetchCategoriesWithJobs(vendorId);
      if (mounted) {
        setState(() {
          _categories = categories;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorName = ref.watch(authRepositoryProvider).getCurrentVendorName() ?? 'Partner';
    final claimedJobs = partnerAppState.jobs;
    final completedCount = claimedJobs.where((j) => j.status == JobStatus.completed).length;

    return RefreshIndicator(
      onRefresh: () => partnerAppState.refreshJobs(),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back,', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(vendorName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Partner', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.trending_up_rounded,
                  label: "Today's Earnings",
                  value: '₹${partnerAppState.todayEarnings}',
                  gradient: [Color(0xFF10B981), Color(0xFF059669)],
                  context: context,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.work_outline_rounded,
                  label: 'My Jobs',
                  value: '$completedCount / ${claimedJobs.length}',
                  gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  subtitle: '$completedCount Completed',
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Category Filter
          if (!_loadingCategories && _categories.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    const Text('Filter by Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(null, 'All (${partnerAppState.newJobs.length})'),
                      ..._categories.map((cat) => _buildCategoryChip(cat.id, '${cat.name} (${cat.jobCount})')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),

          // New Job Requests Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded, size: 20, color: Color(0xFFE97316)),
                  const SizedBox(width: 8),
                  const Text('New Job Requests', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFFF9D00), Color(0xFFE97316)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${partnerAppState.newJobs.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (partnerAppState.newJobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFFD1D5DB)),
                    const SizedBox(height: 12),
                    const Text('All caught up!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            )
          else
            ...partnerAppState.newJobs.take(3).map((job) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NewJobCard(
                  job: job,
                  onTap: () => widget.onJobTap(job.id),
                  onAccept: () async {
                    print('[DEBUG] [HomeTab-NewJob] ===== ACCEPT BUTTON CLICKED =====');
                    print('[DEBUG] [HomeTab-NewJob] Job ID: ${job.id}');
                    print('[DEBUG] [HomeTab-NewJob] Order ID: ${job.orderId}');
                    print('[DEBUG] [HomeTab-NewJob] Order ID is null: ${job.orderId == null}');
                    print('[DEBUG] [HomeTab-NewJob] Order ID is empty: ${job.orderId?.isEmpty}');
                    print('[DEBUG] [HomeTab-NewJob] Customer: ${job.customer}');
                    print('[DEBUG] [HomeTab-NewJob] Service: ${job.service}');
                    print('[DEBUG] [HomeTab-NewJob] Amount: ${job.amount}');
                    print('[DEBUG] [HomeTab-NewJob] Address: ${job.address}');
                    try {
                      print('[DEBUG] [HomeTab-NewJob] Calling partnerAppState.acceptJob("${job.orderId}")...');
                      await partnerAppState.acceptJob(job.orderId ?? '');
                      if (!context.mounted) return;
                      print('[DEBUG] [HomeTab-NewJob] ✅ Job accepted successfully!');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Job accepted! ${job.customer}')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      print('[DEBUG] [HomeTab-NewJob] ❌ Error accepting job: $e');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
                    }
                  },
                ),
              );
            }),

          if (partnerAppState.newJobs.isNotEmpty) const SizedBox(height: 28),

          // Upcoming Today Section
          if (partnerAppState.upcomingJobs.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 20, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    const Text('Scheduled Today', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 12),
                ...partnerAppState.upcomingJobs.map((job) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: UpcomingJobRow(job: job, onTap: () => widget.onJobTap(job.id)),
                  );
                }),
              ],
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
    String? subtitle,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500, letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(int? categoryId, String label) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [AppTheme.saffron, Color(0xFFE97316)])
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _selectedCategoryId = isSelected ? null : categoryId);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
