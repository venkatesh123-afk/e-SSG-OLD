import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../api/api_service.dart';
import '../model/floor_student_model.dart';

class FloorStudentController extends GetxController {
  var isLoading = false.obs;
  var students = <FloorStudentModel>[].obs;

  Future<void> fetchStudentsByFloor(int floorId) async {
    try {
      isLoading(true);
      final List<Map<String, dynamic>> data =
          await ApiService.getStudentsByFloor(floorId);
      students.value = data.map((e) => FloorStudentModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("Error fetching floor students: $e");
      Get.snackbar("Error", "Failed to fetch student list");
    } finally {
      isLoading(false);
    }
  }
}
