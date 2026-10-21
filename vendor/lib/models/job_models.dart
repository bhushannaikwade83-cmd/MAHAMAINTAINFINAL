enum JobStatus { newJob, accepted, inProgress, completed, cancelled }

enum BookingType { instant, slot }

JobStatus jobStatusFromString(String s) {
  switch (s) {
    case 'new':
      return JobStatus.newJob;
    case 'accepted':
      return JobStatus.accepted;
    case 'in_progress':
      return JobStatus.inProgress;
    case 'completed':
      return JobStatus.completed;
    case 'cancelled':
      return JobStatus.cancelled;
  }
  return JobStatus.newJob;
}

BookingType bookingTypeFromString(String s) {
  return s.toUpperCase() == 'SLOT' ? BookingType.slot : BookingType.instant;
}

class Job {
  final int id;
  final String orderId; // String identifier from API (e.g., "ORD1790794062902")
  final String customer;
  final String address;
  final String phone;
  final String service;
  final String type;
  final String duration;
  final int amount;
  JobStatus status;
  final String time;
  final String notes;
  final String distance;
  final String paymentMode;
  final BookingType bookingType;
  int? rating;
  String? beforePhoto;
  String? afterPhoto;
  String? otp;
  final double? latitude;
  final double? longitude;
  double? customerRating;

  Job({
    required this.id,
    this.orderId = '',
    required this.customer,
    required this.address,
    required this.phone,
    required this.service,
    required this.type,
    required this.duration,
    required this.amount,
    required this.status,
    required this.time,
    this.notes = '',
    required this.distance,
    required this.paymentMode,
    this.bookingType = BookingType.instant,
    this.rating,
    this.beforePhoto,
    this.afterPhoto,
    this.otp,
    this.latitude,
    this.longitude,
    this.customerRating,
  });

  String get timeShort {
    final parts = time.split('•');
    return parts.length > 1 ? parts[1].trim() : time;
  }

  String get addressShort => address.split(',').first;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      orderId: (json['order_id'] as String?) ?? '',
      customer: (json['customer_name'] as String?) ?? '',
      address: (json['full_address'] as String?) ?? (json['location_address'] as String?) ?? (json['address'] as String?) ?? '',
      phone: (json['customer_phone'] as String?) ?? (json['phone_number'] as String?) ?? '',
      service: (json['category_name'] as String?) ?? (json['service_name'] as String?) ?? (json['services'] as String?) ?? '',
      type: (json['service_type'] as String?) ?? '',
      duration: '',
      amount: _parseAmount(json['amount'] ?? json['budget'] ?? 0),
      status: _bookingStatusToJobStatus((json['order_status'] as String?) ?? (json['status'] as String?) ?? 'REQUESTED'),
      time: (json['scheduled_at'] as String?) ?? (json['created_at'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      distance: (json['pincode'] as String?) ?? '',
      paymentMode: (json['payment_mode'] as String?) ?? '',
      bookingType: bookingTypeFromString((json['booking_type'] as String?) ?? 'INSTANT'),
      rating: json['rating'] as int?,
      beforePhoto: json['before_photo_url'] as String?,
      afterPhoto: json['after_photo_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      customerRating: (json['customer_rating'] as num?)?.toDouble(),
    );
  }
}

JobStatus _bookingStatusToJobStatus(String status) {
  switch (status.toLowerCase()) {
    case 'requested':
    case 'pending':
    case 'new':
      return JobStatus.newJob;
    case 'accepted':
      return JobStatus.accepted;
    case 'in_progress':
    case 'service_started':
      return JobStatus.inProgress;
    case 'completed':
    case 'service_completed':
      return JobStatus.completed;
    case 'cancelled':
    case 'rejected':
      return JobStatus.cancelled;
  }
  return JobStatus.newJob;
}

int _parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) {
    try {
      return double.parse(value).round();
    } catch (e) {
      return 0;
    }
  }
  if (value is num) return value.round();
  return 0;
}

