import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_app/staff_app/utils/get_storage.dart';
import 'package:student_app/student_app/services/student_profile_service.dart';
import '../api/api_service.dart';
import 'profile_controller.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;

  // ================= LOGIN =================
  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;

      final dynamic response;
      final String loginType;

      if (username.length == 6) {
        loginType = "staff";
        response = await ApiService.login(
          username: username,
          password: password,
        );
      } else if (username.length == 10) {
        loginType = "student";
        response = await ApiService.studentLogin(
          mobile: username,
          password: password,
        );
      } else {
        throw Exception(
          "Invalid username length. Use 6 digits for staff or 10 digits for student.",
        );
      }

      // ✅ SUCCESS CHECK - Handle different success formats
      final isSuccess =
          response["success"] == true ||
          response["success"] == "true" ||
          response["success"] == 1;

      final token =
          response["access_token"] ??
          (response["data"] != null ? response["data"]["token"] : null);
      final userId =
          response["userid"] ??
          (response["data"] != null ? response["data"]["sid"] : null);

      if (isSuccess && token != null) {
        // 🔥 CLEAR PREVIOUS USER'S PROFILE DATA (MULTI-USER SUPPORT)
        _clearProfileController();

        // 🔐 SAVE SESSION (Staff App Storage - GetStorage)
        AppStorage.saveToken(token);
        AppStorage.saveUserId(
          userId is int ? userId : int.tryParse(userId.toString()) ?? 0,
        );
        AppStorage.setLoggedIn(true);
        AppStorage.saveLoginType(response["login_type"] ?? loginType);

        // 🔥 SAVE MULTI-USER SESSION
        AppStorage.saveUserSession({
          'user_login': username,
          'userid': userId,
          'login_type': response['login_type'] ?? loginType,
          'role': response['role'] ?? (loginType == 'student' ? 'Student' : ''),
          'permissions': response['permissions'] ?? [],
        }, token);

        if (loginType == 'student') {
          // 🎓 STUDENT-SPECIFIC STORAGE (SharedPreferences - to support student app services)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("access_token", token);
          await prefs.setString("student_id", userId.toString());

          // 🎓 INITIALIZE STUDENT PROFILE
          StudentProfileService.fetchAndSetProfileData().catchError((e) {
            debugPrint("STUDENT PROFILE FETCH FAILED: $e");
          });

          // 🚀 GO TO STUDENT DASHBOARD
          Get.offAllNamed('/studentDashboard');
        } else {
          // 👨‍🏫 STAFF-SPECIFIC INITIALIZATION
          final profileController = Get.isRegistered<ProfileController>()
              ? Get.find<ProfileController>()
              : Get.put(ProfileController());

          profileController.fetchProfile().catchError((e) {
            debugPrint("PROFILE FETCH FAILED AFTER LOGIN: $e");
          });

          // 🚀 GO TO STAFF DASHBOARD
          Get.offAllNamed('/dashboard');
        }
      } else {
        // Extract error message
        final errorMsg =
            response["message"] ??
            response["error"] ??
            response["msg"] ??
            "Invalid credentials";

        Get.snackbar(
          "Login Failed",
          errorMsg,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("LOGIN ERROR => $e");

      // Extract error message from exception
      String errorMessage = "Server connection failed";
      final errorString = e.toString();

      if (errorString.contains("Invalid") ||
          errorString.contains("credentials") ||
          errorString.contains("Invalid credentials")) {
        errorMessage = "Invalid credentials";
      } else if (errorString.contains("Network") ||
          errorString.contains("connection")) {
        errorMessage = "Network error: Please check your internet connection";
      } else if (errorString.contains("timeout") ||
          errorString.contains("Timeout")) {
        errorMessage = "Connection timeout: Please try again";
      } else if (errorString.contains("Server error")) {
        errorMessage = "Server error: Please try again later";
      } else {
        errorMessage = errorString.replaceFirst("Exception: ", "").trim();
        if (errorMessage.isEmpty) {
          errorMessage = "Login failed: Please try again";
        }
      }

      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ================= CLEAR PROFILE CONTROLLER =================
  void _clearProfileController() {
    if (Get.isRegistered<ProfileController>()) {
      final profileController = Get.find<ProfileController>();
      profileController.profile.value = null;
      profileController.isLoading.value = true;
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    // 🚀 1. Clear Staff Storage
    AppStorage.clear();

    // 🚀 2. Clear Student Storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 🚀 3. Reset Student Services
    StudentProfileService.resetProfileData();

    // 🧹 4. Clear related controllers
    if (Get.isRegistered<ProfileController>()) {
      Get.delete<ProfileController>(force: true);
    }

    // 🚪 5. BACK TO LOGIN
    Get.offAllNamed('/login');
  }
}
