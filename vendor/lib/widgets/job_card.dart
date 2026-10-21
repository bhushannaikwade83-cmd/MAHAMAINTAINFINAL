import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/job_models.dart';

const Color kEmerald = Color(0xFF059669);
const Color kEmeraldBg = Color(0xFFD1FAE5);
const Color kSlateText = Color(0xFF64748B);
const Color kSlateBorder = Color(0xFFF1F5F9);

Widget statusBadge(JobStatus status) {
  late Color bg;
  late Color fg;
  late String label;
  switch (status) {
    case JobStatus.newJob:
      bg = const Color(0xFFFFE3D1);
      fg = AppTheme.saffronDark;
      label = 'NEW REQUEST';
      break;
    case JobStatus.accepted:
      bg = kEmeraldBg;
      fg = kEmerald;
      label = 'ACCEPTED';
      break;
    case JobStatus.inProgress:
      bg = const Color(0xFFFFF3EC);
      fg = AppTheme.saffron;
      label = 'IN PROGRESS';
      break;
    case JobStatus.completed:
      bg = const Color(0xFFE2E8F0);
      fg = const Color(0xFF475569);
      label = 'COMPLETED';
      break;
    case JobStatus.cancelled:
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      label = 'CANCELLED';
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.w700)),
  );
}

/// New job request card (Home screen).
class NewJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  const NewJobCard({required this.job, required this.onTap, required this.onAccept, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(
            left: BorderSide(
              color: AppTheme.saffron.withOpacity(0.6),
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Customer name + Service badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.customer,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF9D00), Color(0xFFE97316)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          job.service,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Accept button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.gold, Color(0xFFE97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAccept,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Location & Amount
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: kSlateText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.addressShort,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kSlateText, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Amount & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${job.amount}',
                    style: const TextStyle(
                      color: kEmerald,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: kSlateText),
                    const SizedBox(width: 4),
                    Text(
                      job.timeShort,
                      style: const TextStyle(color: kSlateText, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.navigation_rounded, size: 14, color: Color(0xFFFF9D00)),
                    const SizedBox(width: 3),
                    Text(
                      job.distance,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF9D00),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact upcoming job row (Home screen).
class UpcomingJobRow extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const UpcomingJobRow({required this.job, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border(
            left: BorderSide(
              color: Color(0xFF3B82F6).withOpacity(0.5),
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        job.customer,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 8),
                      statusBadge(job.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.build_rounded, size: 13, color: kSlateText),
                      const SizedBox(width: 4),
                      Text(
                        job.type,
                        style: const TextStyle(color: kSlateText, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kEmeraldBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₹${job.amount}',
                    style: const TextStyle(color: kEmerald, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      job.timeShort,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full booking card (Bookings screen).
class BookingCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const BookingCard({required this.job, required this.onTap, Key? key}) : super(key: key);

  Color _statusGradientStart(JobStatus status) {
    switch (status) {
      case JobStatus.newJob:
        return const Color(0xFFFF9D00);
      case JobStatus.accepted:
        return const Color(0xFF059669);
      case JobStatus.inProgress:
        return const Color(0xFF3B82F6);
      case JobStatus.completed:
        return const Color(0xFF8B5CF6);
      case JobStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  Color _statusGradientEnd(JobStatus status) {
    switch (status) {
      case JobStatus.newJob:
        return const Color(0xFFE97316);
      case JobStatus.accepted:
        return const Color(0xFF10B981);
      case JobStatus.inProgress:
        return const Color(0xFF06B6D4);
      case JobStatus.completed:
        return const Color(0xFFA78BFA);
      case JobStatus.cancelled:
        return const Color(0xFFF87171);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                color: _statusGradientStart(job.status).withOpacity(0.6),
                width: 5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Customer + Status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.customer,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 13, color: kSlateText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kSlateText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _statusGradientStart(job.status),
                              _statusGradientEnd(job.status),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₹${job.amount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      statusBadge(job.status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Service info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.build_circle_rounded, size: 14, color: _statusGradientStart(job.status)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.service,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (job.type.isNotEmpty) ...[
                      Text(
                        '${job.type}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: kSlateText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Footer: Time + View details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: kSlateText),
                      const SizedBox(width: 4),
                      Text(
                        job.time,
                        style: TextStyle(
                          color: kSlateText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'View details',
                        style: TextStyle(
                          color: _statusGradientStart(job.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: _statusGradientStart(job.status),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nearby job row (Map screen).
class NearbyJobRow extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final String? distanceOverride;
  const NearbyJobRow(
      {required this.job, required this.onTap, required this.onAccept, this.distanceOverride, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kSlateBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(job.type,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kSlateText, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(color: kEmeraldBg, borderRadius: BorderRadius.circular(4)),
                        child: Text('₹${job.amount}',
                            style: const TextStyle(color: kEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      if ((distanceOverride ?? job.distance).isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(distanceOverride ?? job.distance, style: TextStyle(color: AppTheme.saffronDark, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('ACCEPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
