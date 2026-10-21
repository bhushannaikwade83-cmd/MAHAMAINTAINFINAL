import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../widgets/debug_console.dart';
import 'auth_repository.dart';

class JobCategory {
  final int id;
  final String name;
  final String? description;
  final int jobCount;

  JobCategory({
    required this.id,
    required this.name,
    this.description,
    required this.jobCount,
  });

  factory JobCategory.fromJson(Map<String, dynamic> json) {
    return JobCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      jobCount: json['job_count'] ?? 0,
    );
  }
}

class JobCategoriesRepository {
  Future<List<JobCategory>> fetchCategoriesWithJobs(String vendorId) async {
    final console = DebugConsole();
    console.log('Fetching job categories for vendor: $vendorId');
    console.log('URL: ${KycBackendConfig.backendBaseUrl}/get-vendor-job-categories.php');

    try {
      final response = await http.get(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/get-vendor-job-categories.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      );

      console.log('Response status: ${response.statusCode}');
      console.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final categories = ((data['categories'] as List?) ?? [])
              .map((e) => JobCategory.fromJson(e as Map<String, dynamic>))
              .toList();
          console.log('Loaded ${categories.length} categories with ${data['total_jobs']} total jobs');
          return categories;
        } else {
          console.error('Failed to load categories', data['error']);
          throw Exception(data['error'] ?? 'Failed to load categories');
        }
      } else {
        console.error('Failed to load categories: ${response.statusCode}');
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      console.error('Exception while fetching categories', e);
      rethrow;
    }
  }
}
