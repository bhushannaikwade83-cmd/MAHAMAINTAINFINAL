import 'dart:async';
import 'package:flutter/material.dart';
import '../models/job_models.dart';
import '../state/partner_app_state.dart';
import '../widgets/job_card.dart';

class BookingsTab extends StatefulWidget {
  final Function(int) onJobTap;
  const BookingsTab({required this.onJobTap, Key? key}) : super(key: key);

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  JobStatus? _filter;
  bool _todayOnly = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      partnerAppState.refreshJobs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isToday(Job job) {
    final date = DateTime.tryParse(job.time);
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final allJobs = [...partnerAppState.newJobs, ...partnerAppState.jobs];
    var filtered = _filter == null ? allJobs : allJobs.where((j) => j.status == _filter).toList();
    if (_todayOnly) {
      filtered = filtered.where(_isToday).toList();
    }

    return RefreshIndicator(
      onRefresh: () => partnerAppState.refreshJobs(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and total count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Bookings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${filtered.length} active booking${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${partnerAppState.jobs.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Today', null, _todayOnly),
                  const SizedBox(width: 10),
                  _filterChip('All', null, _filter == null && !_todayOnly),
                  const SizedBox(width: 10),
                  _filterChip('New (${partnerAppState.newJobs.length})', JobStatus.newJob, _filter == JobStatus.newJob),
                  const SizedBox(width: 10),
                  _filterChip('Accepted', JobStatus.accepted, _filter == JobStatus.accepted),
                  const SizedBox(width: 10),
                  _filterChip('In Progress', JobStatus.inProgress, _filter == JobStatus.inProgress),
                  const SizedBox(width: 10),
                  _filterChip('Done', JobStatus.completed, _filter == JobStatus.completed),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Jobs list
            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.inbox_rounded,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookings yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accept jobs to see them here',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: filtered.map((job) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: BookingCard(job: job, onTap: () => widget.onJobTap(job.id)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, JobStatus? status, bool active) {
    Color getGradientColor() {
      switch (status) {
        case JobStatus.newJob:
          return Color(0xFFFF9D00);
        case JobStatus.accepted:
          return Color(0xFF059669);
        case JobStatus.inProgress:
          return Color(0xFF3B82F6);
        case JobStatus.completed:
          return Color(0xFF8B5CF6);
        case JobStatus.cancelled:
          return Color(0xFFEF4444);
        default:
          return Color(0xFF1E40AF);
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (label.startsWith('Today')) {
            _todayOnly = !_todayOnly;
            _filter = null;
          } else if (label == 'All') {
            _filter = null;
            _todayOnly = false;
          } else {
            _filter = status;
            _todayOnly = false;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [
                    getGradientColor(),
                    getGradientColor().withOpacity(0.8),
                  ],
                )
              : null,
          color: active ? null : Colors.grey.shade100,
          border: Border.all(
            color: active ? Colors.transparent : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: getGradientColor().withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
