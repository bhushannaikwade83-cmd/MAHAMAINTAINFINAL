import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/available_job_model.dart';
import '../models/vendor_profile_model.dart';
import 'package:logger/logger.dart';
import 'auth_repository.dart';

class JobMatchingRepository {
  final logger = Logger();
  static const String _baseUrl = 'https://digitrixmedia.com/mahamaintainpro/api'; // Files at /api/ not /api/vendor/

  /// Fetch available jobs for vendor via PHP API
  /// Calls: GET /api/get-matching-jobs.php?vendor_id=123
  Future<List<AvailableJob>> getAvailableJobsForVendor(
    VendorProfile vendor,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/get-matching-jobs.php?vendor_id=${vendor.id}');

      logger.i('Fetching jobs from: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        logger.w('API returned error: ${data['error']}');
        return [];
      }

      final jobsList = (data['jobs'] as List?) ?? [];

      logger.i('Fetched ${jobsList.length} available jobs for vendor ${vendor.id}');

      final jobs = jobsList
          .map((jobData) {
            try {
              return _mapToAvailableJob(jobData, vendor);
            } catch (e) {
              logger.e('Error mapping job data: $e');
              return null;
            }
          })
          .whereType<AvailableJob>()
          .where((job) => !job.isExpired)
          .toList();

      return jobs;
    } catch (e) {
      logger.e('Error fetching available jobs: $e');
      throw Exception('Failed to fetch available jobs: $e');
    }
  }

  /// Get a single available job by ID
  Future<AvailableJob?> getAvailableJob(int jobId, VendorProfile vendor) async {
    try {
      final url = Uri.parse('$_baseUrl/vendor/get-matching-jobs.php?vendor_id=${vendor.id}');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final jobsList = (data['jobs'] as List?) ?? [];

      // Find the specific job
      final jobData = jobsList.firstWhere(
        (j) => j['id'] == jobId,
        orElse: () => null,
      );

      if (jobData == null) return null;

      return _mapToAvailableJob(jobData, vendor);
    } catch (e) {
      logger.e('Error fetching job $jobId: $e');
      return null;
    }
  }

  /// Accept a job via PHP API
  /// POST /api/respond-to-job.php
  Future<bool> acceptJob(
    String orderId,
    String vendorId,
    String? deviceToken,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/respond-to-job.php');

      final requestBody = {
        'booking_id': orderId,
        'vendor_id': vendorId,
        'action': 'accept',
      };

      print('[DEBUG] [JobMatchingRepository] acceptJob() called');
      print('[DEBUG] [JobMatchingRepository] URL: $url');
      print('[DEBUG] [JobMatchingRepository] Request body: ${jsonEncode(requestBody)}');
      print('[DEBUG] [JobMatchingRepository] Order ID type: ${orderId.runtimeType}');
      print('[DEBUG] [JobMatchingRepository] Vendor ID type: ${vendorId.runtimeType}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('[DEBUG] [JobMatchingRepository] Response status: ${response.statusCode}');
      print('[DEBUG] [JobMatchingRepository] Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('[DEBUG] [JobMatchingRepository] ❌ Accept job failed: ${response.statusCode}');
        logger.e('Accept job failed: ${response.statusCode} - ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body);
      print('[DEBUG] [JobMatchingRepository] Decoded response: $data');

      if (data['success'] != true) {
        print('[DEBUG] [JobMatchingRepository] ❌ API returned success=false');
        print('[DEBUG] [JobMatchingRepository] API message: ${data['message']}');
        logger.e('API error: ${data['message']}');
        return false;
      }

      print('[DEBUG] [JobMatchingRepository] ✅ Job accepted successfully!');
      logger.i('Vendor $vendorId accepted job $orderId');
      return true;
    } catch (e) {
      print('[DEBUG] [JobMatchingRepository] ❌ Exception: $e');
      print('[DEBUG] [JobMatchingRepository] Stack trace: $e');
      logger.e('Error accepting job: $e');
      return false;
    }
  }

  /// Reject a job via PHP API
  /// POST /api/respond-to-job.php
  Future<bool> rejectJob(String orderId, String vendorId, {String reason = ''}) async {
    try {
      final url = Uri.parse('$_baseUrl/respond-to-job.php');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'booking_id': orderId,
          'vendor_id': vendorId,
          'action': 'reject',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        logger.e('Reject job failed: ${response.statusCode}');
        return false;
      }

      final data = jsonDecode(response.body);

      logger.i('Vendor $vendorId rejected job $jobId');
      return data['success'] == true;
    } catch (e) {
      logger.e('Error rejecting job: $e');
      return false;
    }
  }

  /// Get vendor's profile with enrolled services
  Future<VendorProfile?> getVendorProfile(String vendorId) async {
    try {
      // For now, this should be fetched from your vendor table
      // You may need a separate PHP endpoint for this
      // This is a placeholder - implement based on your needs
      logger.w('getVendorProfile needs implementation with PHP API');
      return null;
    } catch (e) {
      logger.e('Error fetching vendor profile: $e');
      return null;
    }
  }

  /// Update vendor's enrolled services via PHP API
  Future<bool> updateEnrolledServices(
    String vendorId,
    List<int> serviceIds,
  ) async {
    try {
      // TODO: Implement PHP endpoint for this
      logger.w('updateEnrolledServices needs PHP API implementation');
      return false;
    } catch (e) {
      logger.e('Error updating enrolled services: $e');
      return false;
    }
  }

  /// Update vendor's device token for push notifications via PHP API
  Future<bool> updateDeviceToken(String vendorId, String deviceToken) async {
    try {
      // TODO: Implement PHP endpoint for this
      final url = Uri.parse('$_baseUrl/vendor/update-device-token.php');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          ...SupabaseAuthRepository.staticAuthHeaders,
        },
        body: jsonEncode({
          'vendor_id': int.tryParse(vendorId) ?? vendorId,
          'device_token': deviceToken,
        }),
      ).timeout(const Duration(seconds: 10));

      logger.i('Updated device token for vendor $vendorId');
      return response.statusCode == 200;
    } catch (e) {
      logger.e('Error updating device token: $e');
      return false;
    }
  }

  /// Helper method to map API response to AvailableJob
  AvailableJob _mapToAvailableJob(Map<String, dynamic> data, VendorProfile vendor) {
    // Handle nested user data (legacy format)
    String customerName = data['customer_name'] ?? 'Unknown Customer';
    String customerPhone = data['customer_phone'] ?? '';

    if (data['users'] != null) {
      final userData = data['users'];
      if (userData is Map) {
        customerName = userData['name'] ?? customerName;
        customerPhone = userData['phone_number'] ?? customerPhone;
      }
    }

    // Handle nested service category data (legacy format)
    String serviceName = data['service_name'] ?? 'Service';
    if (data['service_categories'] != null) {
      final serviceData = data['service_categories'];
      if (serviceData is Map) {
        serviceName = serviceData['name'] ?? serviceName;
      }
    }

    return AvailableJob(
      id: data['id'] ?? 0,
      orderId: data['order_id'] ?? '',
      customerName: customerName,
      customerPhone: customerPhone,
      serviceName: serviceName,
      serviceCategoryId: data['service_category_id'] ?? 0,
      address: data['location_address'] ?? data['address'] ?? '',
      pincode: data['pincode'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      amount: data['budget']?.toInt() ?? data['amount']?.toInt() ?? 0,
      scheduledDate: data['scheduled_date'],
      scheduledTime: data['scheduled_time'],
      description: data['description'],
      bookingType: data['booking_type'] ?? 'instant',
      customerId: data['customer_id'] ?? 0,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      expiresAt: data['expires_at'] != null
          ? DateTime.parse(data['expires_at'])
          : _calculateExpiryTime(data['created_at']),
    );
  }

  /// Calculate expiry time (jobs expire after 10 minutes if not accepted)
  DateTime _calculateExpiryTime(dynamic createdAt) {
    try {
      if (createdAt == null) return DateTime.now().add(const Duration(minutes: 10));
      return DateTime.parse(createdAt).add(const Duration(minutes: 10));
    } catch (e) {
      return DateTime.now().add(const Duration(minutes: 10));
    }
  }
}
