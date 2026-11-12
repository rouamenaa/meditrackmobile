import '../../auth/services/api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final result = await _api.get('/users/doctors');
    if (result is! List) return const [];
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final result = await _api.get('/appointments');
    if (result is! List) return const [];
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> createAppointment(Map<String, dynamic> appointment) async {
    await _api.post('/appointments', appointment);
  }

  Future<void> updateAppointment(
    String id,
    Map<String, dynamic> appointment,
  ) async {
    await _api.put('/appointments/$id', appointment);
  }

  Future<void> deleteAppointment(String id) async {
    await _api.delete('/appointments/$id');
  }
}
