import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../models/earnings_model.dart';
import '../models/job_models.dart';
import '../widgets/debug_console.dart';
import 'auth_repository.dart';

class VendorJobsSnapshot {
  final List<Job> newJobs;
  final List<Job> myJobs;
  VendorJobsSnapshot({required this.newJobs, required this.myJobs});
}

class JobActionException implements Exception {
  final String message;
  JobActionException(this.message);
  @override
  String toString() => message;
}

class JobsRepository {
  Future<VendorJobsSnapshot> fetchJobs(String vendorId) async {
    final console = DebugConsole();
    console.log('Fetching jobs for vendor: $vendorId');

    try {
      // Fetch NEW JOBS (available matching jobs)
      print('[DEBUG] [JobsRepository] Calling /get-matching-jobs.php...');
      final newJobsResponse = await http.get(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/get-matching-jobs.php')
            .replace(queryParameters: {'vendor_id': vendorId}),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      );

      console.log('New jobs response status: ${newJobsResponse.statusCode}');
      final newJobsData = _decode(newJobsResponse.body);

      if (newJobsResponse.statusCode != 200) {
        console.error('Failed to load new jobs', newJobsData['error'] ?? 'Unknown error');
        throw JobActionException(newJobsData['error']?.toString() ?? 'Could not load jobs');
      }

      final newJobsList = ((newJobsData['jobs'] as List?) ?? [])
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
      console.log('Loaded ${newJobsList.length} available jobs');

      // Fetch VENDOR'S OWN JOBS (accepted, in progress, completed)
      print('[DEBUG] [JobsRepository] Calling /get-vendor-jobs.php...');
      final myJobsResponse = await http.get(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/get-vendor-jobs.php')
            .replace(queryParameters: {'vendor_id': vendorId}),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      );

      console.log('My jobs response status: ${myJobsResponse.statusCode}');
      final myJobsData = _decode(myJobsResponse.body);

      if (myJobsResponse.statusCode != 200) {
        console.log('Note: Could not load vendor jobs, continuing with empty list');
      }

      print('[DEBUG] [JobsRepository] Raw my_jobs data: ${myJobsData['my_jobs']}');
      final myJobsList = ((myJobsData['my_jobs'] as List?) ?? [])
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
      console.log('Loaded ${myJobsList.length} vendor jobs');
      print('[DEBUG] [JobsRepository] Parsed ${myJobsList.length} vendor jobs');
      for (var job in myJobsList) {
        print('[DEBUG] [JobsRepository] Job: id=${job.id}, status=${job.status}, amount=${job.amount}');
      }

      return VendorJobsSnapshot(newJobs: newJobsList, myJobs: myJobsList);
    } catch (e) {
      console.error('Exception while fetching jobs', e);
      rethrow;
    }
  }

  Future<void> respondToJob(String vendorId, String orderId, {required bool accept, String? reason}) async {
    print('[DEBUG] [JobsRepository] respondToJob() called');
    print('[DEBUG] [JobsRepository] vendorId: $vendorId, orderId: $orderId, accept: $accept');

    final requestBody = {
      'vendor_id': vendorId,
      'booking_id': orderId,
      'action': accept ? 'accept' : 'reject',
      if (!accept && reason != null && reason.isNotEmpty) 'reason': reason,
    };

    print('[DEBUG] [JobsRepository] Request body: ${jsonEncode(requestBody)}');
    print('[DEBUG] [JobsRepository] URL: ${KycBackendConfig.backendBaseUrl}/respond-to-job.php');

    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/respond-to-job.php'),
      headers: SupabaseAuthRepository.staticAuthHeaders,
      body: jsonEncode(requestBody),
    );

    print('[DEBUG] [JobsRepository] Response status: ${response.statusCode}');
    print('[DEBUG] [JobsRepository] Response body: ${response.body}');

    final data = _decode(response.body);
    print('[DEBUG] [JobsRepository] Decoded response: $data');

    if (response.statusCode != 200 || data['success'] != true) {
      final errorMsg = data['message']?.toString() ?? 'Could not respond to job';
      print('[DEBUG] [JobsRepository] ❌ Error: $errorMsg');
      throw JobActionException(errorMsg);
    }

    print('[DEBUG] [JobsRepository] ✅ Response successful!');
  }

  Future<void> markOnTheWay(String vendorId, String orderId) async {
    await _updateStatus(vendorId, orderId, 'on_the_way');
  }

  Future<void> startJob(String vendorId, String orderId, {File? beforePhoto}) async {
    await _updateStatus(vendorId, orderId, 'start', photoField: 'before_photo', photo: beforePhoto);
  }

  Future<void> completeJob(
    String vendorId,
    String orderId,
    String completionOtp, {
    File? afterPhoto,
    File? customerSignature,
    String? workDescription,
    String? partsUsed,
    double? additionalCharges,
    String? technicianRemarks,
  }) async {
    await _updateStatus(
      vendorId,
      orderId,
      'complete',
      photoField: 'after_photo',
      photo: afterPhoto,
      extraFileField: customerSignature != null ? 'customer_signature' : null,
      extraFile: customerSignature,
      extraFields: {
        'completion_otp': completionOtp,
        if (workDescription != null && workDescription.isNotEmpty) 'work_description': workDescription,
        if (partsUsed != null && partsUsed.isNotEmpty) 'parts_used': partsUsed,
        if (additionalCharges != null) 'additional_charges': additionalCharges.toString(),
        if (technicianRemarks != null && technicianRemarks.isNotEmpty) 'technician_remarks': technicianRemarks,
      },
    );
  }

  Future<void> cancelJob(String vendorId, String orderId) async {
    await _updateStatus(vendorId, orderId, 'cancel');
  }

  Future<void> _updateStatus(
    String vendorId,
    String orderId,
    String action, {
    String? photoField,
    File? photo,
    String? extraFileField,
    File? extraFile,
    Map<String, String>? extraFields,
  }) async {
    print('[DEBUG] [_updateStatus] Starting: vendorId=$vendorId, orderId=$orderId, action=$action');
    final uri = Uri.parse('${KycBackendConfig.backendBaseUrl}/update-job-status.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['vendor_id'] = vendorId
      ..fields['booking_id'] = orderId
      ..fields['action'] = action;
    print('[DEBUG] [_updateStatus] Request fields: vendor_id=$vendorId, booking_id=$orderId, action=$action');

    final authToken = SupabaseAuthRepository.currentToken;
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
      print('[DEBUG] [_updateStatus] Auth header added');
    }
    if (extraFields != null) request.fields.addAll(extraFields);
    if (photoField != null && photo != null) {
      print('[DEBUG] [_updateStatus] Adding photo: $photoField from ${photo.path}');
      request.files.add(await http.MultipartFile.fromPath(photoField, photo.path));
    }
    if (extraFileField != null && extraFile != null) {
      request.files.add(await http.MultipartFile.fromPath(extraFileField, extraFile.path));
    }

    print('[DEBUG] [_updateStatus] Sending request to $uri');
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('[DEBUG] [_updateStatus] Response status: ${response.statusCode}');
    print('[DEBUG] [_updateStatus] Response body: ${response.body}');

    final data = _decode(response.body);
    print('[DEBUG] [_updateStatus] Decoded response: $data');

    if (response.statusCode != 200 || data['success'] != true) {
      final errMsg = data['message']?.toString() ?? 'Could not update job';
      print('[DEBUG] [_updateStatus] ❌ Error: $errMsg');
      throw JobActionException(errMsg);
    }
    print('[DEBUG] [_updateStatus] ✅ Success!');
  }

  Future<VendorEarnings> fetchEarnings(String vendorId) async {
    final response = await http.get(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/get-vendor-earnings.php')
          .replace(queryParameters: {'vendor_id': vendorId}),
      headers: SupabaseAuthRepository.staticAuthHeaders,
    );
    final data = _decode(response.body);
    if (response.statusCode != 200) {
      throw JobActionException(data['error']?.toString() ?? 'Could not load earnings');
    }
    return VendorEarnings.fromJson(data);
  }

  Future<void> setOnlineStatus(String vendorId, bool isOnline) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/set-vendor-online-status.php'),
      headers: SupabaseAuthRepository.staticAuthHeaders,
      body: jsonEncode({'vendor_id': vendorId, 'is_online': isOnline}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw JobActionException(data['message']?.toString() ?? 'Could not update online status');
    }
  }

  Future<void> withdraw(String vendorId, double amount) async {
    final response = await http.post(
      Uri.parse('${KycBackendConfig.backendBaseUrl}/withdraw-earnings.php'),
      headers: SupabaseAuthRepository.staticAuthHeaders,
      body: jsonEncode({'vendor_id': vendorId, 'amount': amount}),
    );
    final data = _decode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw JobActionException(data['message']?.toString() ?? 'Could not process withdrawal');
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
