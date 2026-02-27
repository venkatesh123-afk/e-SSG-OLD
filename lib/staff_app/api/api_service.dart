import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../api/api_collection.dart';
import '../model/non_hostel_student_model.dart';
import '../model/hostel_student_model.dart';
import '../model/room_attendance_model.dart';
import '../model/hostel_grid_model.dart';
import '../utils/get_storage.dart';

class ApiService {
  ApiService._();

  static final GetStorage _box = GetStorage();

  // ================= HEADERS =================

  static Map<String, String> _authHeaders(String token) => {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    // 🔥 IMPORTANT: credentials in URL (NOT body)
    final Uri url = Uri.parse(
      ApiCollection.baseUrl +
          ApiCollection.login(username: username, password: password),
    );

    try {
      // clear old session (multi-user safe)
      _box.remove("token");
      _box.remove("user_id");

      final response = await http
          .post(
            url,
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
            },
          )
          .timeout(const Duration(seconds: 20));

      // Handle non-200 status codes
      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      // Parse JSON response
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("LOGIN JSON PARSE ERROR: ${response.body}");
        throw Exception("Invalid server response format");
      }

      // 🔍 DEBUG: Log the full response
      debugPrint("LOGIN API RESPONSE: ${response.body}");
      debugPrint("LOGIN PARSED DATA: $data");

      // Check if login was successful
      final isSuccess =
          data["success"] == true ||
          data["success"] == "true" ||
          data["success"] == 1;

      debugPrint(
        "LOGIN SUCCESS CHECK: isSuccess=$isSuccess, hasToken=${data["access_token"] != null}",
      );

      if (isSuccess && data["access_token"] != null) {
        AppStorage.saveToken(data["access_token"]);
        AppStorage.saveUserId(data["userid"]);

        // 🔥 STORE NEW FIELDS (LOGIN TYPE, ROLE, PERMISSIONS)
        if (data["login_type"] != null) {
          AppStorage.saveLoginType(data["login_type"]);
        }
        if (data["role"] != null) {
          AppStorage.saveUserRole(data["role"]);
        }
        if (data["permissions"] != null && data["permissions"] is List) {
          AppStorage.savePermissions(List<String>.from(data["permissions"]));
        }

        return data;
      }

      // Extract error message from response
      final errorMessage =
          data["message"] ??
          data["error"] ??
          data["msg"] ??
          data["errors"]?.toString() ??
          "Invalid credentials";

      debugPrint("LOGIN ERROR MESSAGE: $errorMessage");
      throw Exception(errorMessage);
    } on http.ClientException {
      throw Exception("Network error: Please check your internet connection");
    } on FormatException {
      throw Exception("Invalid server response format");
    } catch (e) {
      // If it's already an Exception, rethrow it
      if (e is Exception) {
        rethrow;
      }
      // Otherwise wrap it
      throw Exception(e.toString());
    }
  }

  // ================= AUTH GET =================
  static Future<dynamic> getRequest(String endpoint) async {
    final String? token = _box.read<String>("token");

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(ApiCollection.baseUrl + endpoint);

    try {
      final response = await http
          .get(url, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 20));

      // 🔍 DEBUG: Log raw response
      debugPrint("API GET RESPONSE [$endpoint]: ${response.body}");

      if (response.body.trim().isEmpty) {
        if (response.statusCode == 200)
          return {"success": false, "message": "Empty response from server"};
        throw Exception(
          "Server returned empty body with status ${response.statusCode}",
        );
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded;
      }

      if (response.statusCode == 401) {
        _box.remove("token");
        _box.remove("user_id");
        throw Exception("Unauthorized");
      }

      if (response.body.length > 500) {
        throw Exception(
          "API Error ${response.statusCode}: ${response.body.substring(0, 500)}...",
        );
      }
      throw Exception("API Error ${response.statusCode}: ${response.body}");
    } catch (e) {
      debugPrint("API GET ERROR [$endpoint]: $e");
      rethrow;
    }
  }

  // ================= AUTH POST =================
  static Future<dynamic> postRequest(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final String? token = _box.read<String>("token");

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(ApiCollection.baseUrl + endpoint);

    try {
      final response = await http
          .post(
            url,
            headers: _authHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 20));

      // 🔍 DEBUG: Log raw response
      debugPrint("API POST RESPONSE [$endpoint]: ${response.body}");

      if (response.body.trim().isEmpty) {
        if (response.statusCode == 200)
          return {"success": false, "message": "Empty response from server"};
        throw Exception(
          "Server returned empty body with status ${response.statusCode}",
        );
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decoded;
      }

      if (response.statusCode == 401) {
        _box.remove("token");
        _box.remove("user_id");
        throw Exception("Unauthorized");
      }

      throw Exception("API Error ${response.statusCode}: ${response.body}");
    } catch (e) {
      debugPrint("API POST ERROR [$endpoint]: $e");
      rethrow;
    }
  }

  // ================= STUDENT SEARCH =================
  static Future<List<Map<String, dynamic>>> searchStudentByAdmNo(
    String admNo,
  ) async {
    final res = await getRequest(ApiCollection.studentByAdmNo(admNo));

    if ((res["success"] == true || res["success"] == "true") &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    throw Exception("Student not found");
  }

  // ================= GET FULL STUDENT DETAILS =================
  static Future<Map<String, dynamic>> getStudentDetailsByAdmNo(
    String admNo,
  ) async {
    final res = await getRequest(ApiCollection.studentByAdmNo(admNo));

    if ((res["success"] == true || res["success"] == "true") &&
        res["indexdata"] != null &&
        res["indexdata"] is List &&
        (res["indexdata"] as List).isNotEmpty) {
      return (res["indexdata"] as List<dynamic>).first as Map<String, dynamic>;
    }

    throw Exception("Student not found");
  }

  static Future<List<Map<String, dynamic>>> searchOutingsByName(
    String identifier,
  ) async {
    final res = await postRequest(ApiCollection.outingSearch(identifier));

    if ((res["success"] == true || res["success"] == "true")) {
      final List? data = res["indexdata"] ?? res["outings"];
      if (data != null) {
        return List<Map<String, dynamic>>.from(data);
      }
    }

    return [];
  }

  // ================= ADD OUTING REMARKS =================
  static Future<void> addOutingRemarks({
    required int outingId,
    required String remarks,
  }) async {
    final res = await postRequest(
      ApiCollection.addOutingRemarks,
      body: {"id": outingId, "remarks": remarks},
    );

    final bool isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (!isSuccess) {
      throw Exception(res["message"] ?? "Failed to add outing remarks");
    }
  }

  // ================= UPLOAD OUTING LETTER =================
  static Future<String?> uploadOutingLetter(
    File imageFile, {
    String? admNo,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final Map<String, dynamic> body = {
        "image": "data:image/jpeg;base64,$base64Image",
      };
      if (admNo != null) {
        body["adm_no"] = admNo;
      }

      final res = await postRequest(
        ApiCollection.updateOutingLetter,
        body: body,
      );

      // 🔍 DEBUG: Log raw response for outing letter update
      debugPrint("UPLOAD LETTER RESPONSE: $res");

      final bool isSuccess =
          res["success"] == true ||
          res["success"] == "true" ||
          res["success"] == "ture" || // Common backend typo
          res["success"] == 1;

      if (isSuccess) {
        // Try various common URL fields if "url" is missing
        final url = res["url"] ?? res["image_url"] ?? res["data"]?["url"];
        if (url != null && url.toString().isNotEmpty) {
          return url.toString();
        }
        // If success but no URL, return a placeholder to indicate success
        return "SUCCESS_NO_URL";
      }
      throw Exception(res["message"] ?? "Failed to upload letter photo");
    } catch (e) {
      debugPrint("UPLOAD LETTER ERROR: $e");
      rethrow;
    }
  }

  static Future<String?> uploadOutingPhoto(
    File imageFile, {
    required int outingId,
  }) async {
    try {
      final String? token = _box.read<String>("token");
      if (token == null || token.isEmpty) {
        throw Exception("Session expired. Please login again.");
      }

      final Uri url = Uri.parse(
        ApiCollection.baseUrl + ApiCollection.updateOutingPhoto,
      );

      final request = http.MultipartRequest("POST", url)
        ..headers["Accept"] = "application/json"
        ..headers["Authorization"] = "Bearer $token"
        ..fields["id"] = outingId.toString()
        ..files.add(
          await http.MultipartFile.fromPath(
            "photo", // changed from "pic" as per Postman screenshot
            imageFile.path,
          ),
        );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final body = await streamed.stream.bytesToString();
      debugPrint("UPLOAD PHOTO [${streamed.statusCode}]: $body");

      if (streamed.statusCode == 401) {
        _box.remove("token");
        throw Exception("Unauthorized");
      }
      if (streamed.statusCode != 200) {
        throw Exception("Upload Error ${streamed.statusCode}: $body");
      }

      final res = jsonDecode(body);

      final bool isSuccess =
          res["success"] == true ||
          res["success"] == "true" ||
          res["success"] == "ture" ||
          res["success"] == 1;

      if (isSuccess) {
        final photoUrl =
            res["url"] ?? res["image_url"] ?? res["pic"] ?? res["data"]?["url"];
        return photoUrl?.toString() ?? "SUCCESS_NO_URL";
      }
      throw Exception(
        res["message"] ?? res["errors"] ?? "Failed to upload photo",
      );
    } catch (e) {
      debugPrint("UPLOAD PHOTO ERROR: $e");
      rethrow;
    }
  }

  // ================= STORE OUTING =================
  static Future<void> storeOuting({
    required int sid,
    required String admNo,
    required String studentName,
    required String outDate,
    required String outTime,
    required String outingType,
    required String purpose,
    required String letterPhoto,
  }) async {
    final String? token = _box.read<String>("token");
    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(
      ApiCollection.baseUrl + ApiCollection.storeOuting,
    );

    // Backend expects multipart/form-data with these exact field names (from Postman)
    final request = http.MultipartRequest("POST", url)
      ..headers["Accept"] = "application/json"
      ..headers["Authorization"] = "Bearer $token"
      ..fields["sid"] = sid.toString()
      ..fields["admno"] = admNo
      ..fields["name"] = studentName
      ..fields["outing_date"] = outDate
      ..fields["outtime"] = outTime
      ..fields["passtype"] = outingType
      ..fields["purpose"] = purpose
      ..fields["letterpic"] = letterPhoto;

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final body = await streamed.stream.bytesToString();
    debugPrint("STORE OUTING [${streamed.statusCode}]: $body");

    if (body.trim().isEmpty) {
      if (streamed.statusCode == 200) return;
      throw Exception("Empty response (${streamed.statusCode})");
    }

    if (streamed.statusCode == 401) {
      _box.remove("token");
      throw Exception("Unauthorized");
    }

    if (streamed.statusCode != 200) {
      throw Exception("API Error ${streamed.statusCode}: $body");
    }

    final res = jsonDecode(body);
    final bool isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (!isSuccess) {
      throw Exception(res["message"] ?? "Failed to store outing");
    }
  }

  // ================= INREPORT OUTING =================
  static Future<void> inreportOuting(int outingId) async {
    final res = await getRequest(ApiCollection.inreportOuting(outingId));

    final bool isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (!isSuccess) {
      throw Exception(res["message"] ?? "Failed to report in");
    }
  }

  // ================= APPROVE OUTING =================
  static Future<void> approveOuting(int outingId) async {
    final res = await getRequest(ApiCollection.approveOuting(outingId));

    final bool isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (!isSuccess) {
      throw Exception(res["message"] ?? "Failed to approve outing");
    }
  }

  // ================= DEPARTMENTS =================
  static Future<List<Map<String, dynamic>>> getDepartmentsList() async {
    final res = await getRequest(ApiCollection.departmentsList);

    if ((res["success"] == true || res["success"] == "true") &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    throw Exception("Failed to load departments");
  }

  // ================= EXAM CATEGORIES =================
  static Future<List<Map<String, dynamic>>> getExamCategories() async {
    final res = await getRequest(ApiCollection.categoryList);

    if ((res["success"] == true || res["success"] == "true") &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    throw Exception("Failed to load exam categories");
  }

  // ================= HOSTELS BY BRANCH =================
  static Future<List<Map<String, dynamic>>> getHostelsByBranch(
    int branchId,
  ) async {
    final res = await getRequest(ApiCollection.getHostelsByBranch(branchId));

    debugPrint("HOSTELS API RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    throw Exception("Failed to load hostels");
  }

  // ================= DESIGNATIONS =================
  static Future<List<Map<String, dynamic>>> getDesignationsList() async {
    final res = await getRequest(ApiCollection.designationsList);

    if ((res["success"] == true || res["success"] == "true") &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    throw Exception("Failed to load designations");
  }

  // ================= ADD HOSTEL MEMBER =================
  static Future<void> addHostelMember({
    required String sid,
    required String branch,
    required String hostel,
    required String floor,
    required String room,
    required String month,
  }) async {
    final String? token = _box.read<String>("token");

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(
      ApiCollection.baseUrl + ApiCollection.addHostelMember,
    );

    final Map<String, dynamic> body = {
      "sid": sid,
      "branch": branch,
      "hostel": hostel,
      "floor": floor,
      "room": room,
      "month": month,
    };

    debugPrint("ADD HOSTEL MEMBER REQUEST: $body");

    final response = await http
        .post(url, headers: _authHeaders(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    debugPrint("ADD HOSTEL MEMBER RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);

    final isSuccess =
        decoded["success"] == true ||
        decoded["success"] == "true" ||
        decoded["success"] == 1;

    if (!isSuccess) {
      throw Exception(
        decoded["indexdata"] ??
            decoded["message"] ??
            "Failed to add hostel member",
      );
    }
  }

  // ================= EDIT HOSTEL MEMBER =================
  static Future<void> editHostelMember({
    required String sid,
    required String branch,
    required String hostel,
    required String floor,
    required String room,
    required String month,
  }) async {
    final String? token = _box.read<String>("token");

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(
      ApiCollection.baseUrl + ApiCollection.editHostelMember,
    );

    final Map<String, dynamic> body = {
      "sid": sid,
      "branch": branch,
      "hostel": hostel,
      "floor": floor,
      "room": room,
      "month": month,
    };

    debugPrint("EDIT HOSTEL MEMBER REQUEST: $body");

    final response = await http
        .post(url, headers: _authHeaders(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    debugPrint("EDIT HOSTEL MEMBER RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);

    final isSuccess =
        decoded["success"] == true ||
        decoded["success"] == "true" ||
        decoded["success"] == 1;

    if (!isSuccess) {
      throw Exception(
        decoded["indexdata"] ??
            decoded["message"] ??
            "Failed to update hostel member",
      );
    }
  }

  // ================= DELETE HOSTEL MEMBER =================
  static Future<void> deleteHostelMember({required String sid}) async {
    final String? token = _box.read<String>("token");

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(
      ApiCollection.baseUrl + ApiCollection.deleteHostelMember,
    );

    final Map<String, dynamic> body = {"sid": sid};

    debugPrint("DELETE HOSTEL MEMBER REQUEST: $body");

    final response = await http
        .post(url, headers: _authHeaders(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    debugPrint("DELETE HOSTEL MEMBER RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);

    final isSuccess =
        decoded["success"] == true ||
        decoded["success"] == "true" ||
        decoded["success"] == 1;

    if (!isSuccess) {
      throw Exception(
        decoded["indexdata"] ??
            decoded["message"] ??
            "Failed to delete hostel member",
      );
    }
  }

  // ================= HOSTEL MEMBERS LIST =================
  static Future<List<Map<String, dynamic>>> getHostelMembers({
    required String type, // hostel | floor | room | batch
    required String param, // id / room no / batch id
  }) async {
    final res = await getRequest(
      ApiCollection.hostelMembersList(type: type, param: param),
    );

    debugPrint("HOSTEL MEMBERS RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    throw Exception("Failed to load hostel members");
  }

  // ================= VERIFY ATTENDANCE =================
  static Future<List<Map<String, dynamic>>> getVerifyAttendance({
    required int branchId,
    required int shiftId,
  }) async {
    final res = await getRequest(
      ApiCollection.getVerifyAttendance(branchId: branchId, shiftId: shiftId),
    );

    debugPrint("VERIFY ATTENDANCE RESPONSE: $res");

    final List? data = res["indexdata"] ?? res["data"];
    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        data != null) {
      return List<Map<String, dynamic>>.from(data);
    }

    return []; // 👈 empty list is valid (same as Postman)
  }

  static Future<List<Map<String, dynamic>>> getVerifyAttendanceDetailed({
    required int branchId,
    required int shiftId,
  }) async {
    final res = await getRequest(
      ApiCollection.getVerifyAttendanceDetailed(
        branchId: branchId,
        shiftId: shiftId,
      ),
    );

    debugPrint("VERIFY ATTENDANCE DETAILED RESPONSE: $res");

    final List? data = res["indexdata"] ?? res["data"];
    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        data != null) {
      return List<Map<String, dynamic>>.from(data);
    }

    return [];
  }

  static Future<dynamic> storeVerifyAttendance({
    required List<int> branchIds,
    required List<int> groupIds,
    required List<int> courseIds,
    required List<int> batchIds,
    required List<int> totalStrengths,
    required List<int> totalPresents,
    required List<int> totalAbsents,
  }) async {
    final endpoint = ApiCollection.verifyStoreAttendance(
      branchIds: branchIds,
      groupIds: groupIds,
      courseIds: courseIds,
      batchIds: batchIds,
      totalStrengths: totalStrengths,
      totalPresents: totalPresents,
      totalAbsents: totalAbsents,
    );

    final res = await getRequest(endpoint);

    debugPrint("STORE VERIFY ATTENDANCE RESPONSE: $res");

    final bool isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (!isSuccess) {
      throw Exception(res["message"] ?? "Failed to store verified attendance");
    }

    return res;
  }

  // ================= MONTHLY CLASS ATTENDANCE =================
  static Future<List<Map<String, dynamic>>> getMonthlyClassAttendance({
    required int branchId,
    required int groupId,
    required int courseId,
    required int batchId,
    required String month, // "01" to "12"
    required int shiftId,
  }) async {
    final res = await getRequest(
      ApiCollection.monthlyAttendance(
        branchId: branchId,
        groupId: groupId,
        courseId: courseId,
        batchId: batchId,
        month: month,
        shiftId: shiftId, // ✅ maps to `shift` query param
      ),
    );

    debugPrint("MONTHLY ATTENDANCE RESPONSE: $res");

    // ✅ Handle all backend success formats
    final bool isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (isSuccess && res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    return [];
  }

  // ================= STORE CLASS ATTENDANCE =================
  static Future<dynamic> storeStudentAttendance({
    required int branchId,
    required int groupId,
    required int courseId,
    required int batchId,
    required int shiftId,
    required List<int> sidList,
    required List<String> statusList,
  }) async {
    final endpoint = ApiCollection.storeStudentAttendance(
      branchId: branchId,
      groupId: groupId,
      courseId: courseId,
      batchId: batchId,
      shiftId: shiftId,
      sidList: sidList,
      statusList: statusList,
    );

    final res = await getRequest(endpoint);

    debugPrint("STORE STUDENT ATTENDANCE RESPONSE: $res");

    final isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (!isSuccess) {
      throw Exception(res["message"] ?? "Failed to save class attendance");
    }

    return res;
  }

  // ================= OUTING LIST (RAW RESPONSE) =================
  static Future<Map<String, dynamic>> getOutingListRaw({
    String? branch,
    String? reportType,
    String? daybookFilter,
    String? firstDate,
    String? nextDate,
  }) async {
    final res = await getRequest(
      ApiCollection.outingList(
        branch: branch,
        reportType: reportType,
        daybookFilter: daybookFilter,
        firstDate: firstDate,
        nextDate: nextDate,
      ),
    );

    if ((res["success"] == true || res["success"] == "true")) {
      return res;
    }

    throw Exception("Failed to load outing list");
  }

  // ================= PENDING OUTING =================
  static Future<List<Map<String, dynamic>>> getPendingOutingList() async {
    final res = await getRequest(ApiCollection.pendingOutingList);

    if ((res["success"] == true || res["success"] == "true") &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    throw Exception("Failed to load pending outing list");
  }

  static Future<Map<String, dynamic>> getOutingDetails(int id) async {
    final res = await getRequest(ApiCollection.outingDetails(id));

    if (res["success"] == true || res["success"] == "true") {
      return res;
    }

    throw Exception(res["message"] ?? "Failed to load outing details");
  }

  // ================= HOSTEL ATTENDANCE (NEW) =================

  /// 1️⃣ Get students for a room (to mark attendance)
  static Future<List<HostelStudentModel>> getRoomStudentsAttendance({
    required String shift,
    required String date,
    required String param, // room id
  }) async {
    final res = await getRequest(
      ApiCollection.getRoomStudentsAttendance(
        shift: shift,
        date: date,
        param: param,
      ),
    );

    debugPrint("ROOM STUDENTS ATTENDANCE RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["hostelData"] != null) {
      return (res["hostelData"] as List)
          .map((e) => HostelStudentModel.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 2️⃣ Store hostel attendance
  static Future<void> storeHostelAttendance({
    required String branchId,
    required String hostel,
    required String floor,
    required String room,
    required String shift,
    required List<int> sidList,
    required List<String> statusList,
  }) async {
    final endpoint = ApiCollection.storeHostelAttendance(
      branchId: branchId,
      hostel: hostel,
      floor: floor,
      room: room,
      shift: shift,
      sidList: sidList,
      statusList: statusList,
    );

    debugPrint("GET REQUEST [/store_hostel_attendace] URL: $endpoint");

    final res = await getRequest(endpoint);

    debugPrint("STORE HOSTEL ATTENDANCE RESPONSE: $res");

    final isSuccess =
        res["success"] == true ||
        res["success"] == "true" ||
        res["success"] == 1;

    if (!isSuccess) {
      throw Exception(res["message"] ?? "Failed to save attendance");
    }
  }

  static Future<List<Map<String, dynamic>>> getRoomsAttendanceSummary({
    required String branch,
    required String date,
    required String hostel,
    required String floor,
    required String room,
  }) async {
    final endpoint = ApiCollection.roomsAttendance();
    final body = {
      "branch": branch,
      "date": date,
      "hostel": hostel,
      "floor": floor,
      "room": room,
    };

    debugPrint("POST REQUEST [/rooms-attendance] BODY: $body");

    final res = await postRequest(endpoint, body: body);

    debugPrint("FULL API RESPONSE [/rooms-attendance]: $res");

    if (res["rooms"] != null && res["rooms"] is List) {
      return List<Map<String, dynamic>>.from(res["rooms"]);
    }

    if (res["indexdata"] != null && res["indexdata"] is List) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    if (res["data"] != null && res["data"] is List) {
      return List<Map<String, dynamic>>.from(res["data"]);
    }

    return [];
  }

  /// 4️⃣ Get detailed room attendance (student-wise)
  static Future<List<RoomAttendanceModel>> getRoomAttendanceDetails({
    required String roomId,
  }) async {
    final res = await getRequest(
      ApiCollection.getRoomAttendance(roomId: roomId),
    );

    debugPrint("ROOM ATTENDANCE DETAILS RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] ==
                "ture" || // Backend typo "ture" in Postman screenshot 3
            res["success"] == 1) &&
        res["attendanceData"] != null) {
      return (res["attendanceData"] as List)
          .map((e) => RoomAttendanceModel.fromJson(e))
          .toList();
    }

    return [];
  }

  /// 5️⃣ Get hostel attendance grid for a student
  static Future<List<HostelGridModel>> getHostelAttendanceGrid(int sid) async {
    final res = await getRequest(ApiCollection.hostelAttendanceGrid(sid));

    debugPrint("HOSTEL ATTENDANCE GRID RESPONSE: $res");

    if (res["attendance"] != null && res["attendance"] is List) {
      return (res["attendance"] as List)
          .map((e) => HostelGridModel.fromJson(e))
          .toList();
    }

    return [];
  }

  // ================= GET ROOMS BY FLOOR =================
  static Future<List<Map<String, dynamic>>> getRoomsByFloor(int floorId) async {
    final res = await getRequest(ApiCollection.getRoomsByFloor(floorId));

    debugPrint("GET ROOMS BY FLOOR RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    return [];
  }

  // ================= GET FLOOR INCHARGES =================
  static Future<List<Map<String, dynamic>>> getFloorIncharges(
    int buildingId,
  ) async {
    final res = await getRequest(ApiCollection.getFloorIncharges(buildingId));

    debugPrint("GET FLOOR INCHARGES RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    return [];
  }

  // ================= ASSIGN INCHARGES =================
  static Future<void> assignIncharge({
    required int branchId,
    required int hostelId,
    required int staffId,
    required int floorId,
    required String rooms,
  }) async {
    final String? token = _box.read<String>("token");

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(
      ApiCollection.baseUrl + ApiCollection.assignIncharges,
    );

    final Map<String, dynamic> body = {
      "branch_id": branchId,
      "hostel": hostelId,
      "incharge": staffId,
      "floor": floorId,
      "rooms": rooms,
    };

    debugPrint("ASSIGN INCHARGE REQUEST: $body");

    final response = await http
        .post(url, headers: _authHeaders(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    debugPrint("ASSIGN INCHARGE RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);

    final isSuccess =
        decoded["success"] == true ||
        decoded["success"] == "true" ||
        decoded["success"] == 1;

    if (!isSuccess) {
      throw Exception(decoded["message"] ?? "Failed to assign incharge");
    }
  }

  // ================= GET FLOORS BY INCHARGE =================
  static Future<List<Map<String, dynamic>>> getFloorsByIncharge(
    int inchargeId,
  ) async {
    final res = await getRequest(ApiCollection.getFloorsByIncharge(inchargeId));

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    return [];
  }

  // ================= GET FLOORS BY HOSTEL =================
  static Future<List<Map<String, dynamic>>> getFloorsByHostel(
    int hostelId,
  ) async {
    final res = await getRequest(ApiCollection.getFloorsByHostel(hostelId));

    debugPrint("GET FLOORS BY HOSTEL RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    return [];
  }

  // ================= NON HOSTEL STUDENTS =================
  static Future<List<NonHostelStudentModel>> getNonHostelStudents(
    int branchId,
  ) async {
    final res = await getRequest(ApiCollection.getNonHostelStudents(branchId));

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return (res["indexdata"] as List)
          .map((e) => NonHostelStudentModel.fromJson(e))
          .toList();
    }

    throw Exception("Failed to load non-hostel students");
  }

  // ================= SAVE HOSTEL BUILDING =================
  static Future<void> saveHostelBuilding({
    required String buildingName,
    required String category,
    required String address,
    required int inchargeId,
    required int branchId,
    required int status, // 1 for Active, 0 for Inactive
  }) async {
    final String? token = _box.read<String>("token");

    if (token == null || token.isEmpty) {
      throw Exception("Session expired. Please login again.");
    }

    final Uri url = Uri.parse(ApiCollection.baseUrl + ApiCollection.saveHostel);

    final Map<String, dynamic> body = {
      "buildingname": buildingName,
      "category": category,
      "address": address,
      "incharge": inchargeId,
      "branch_id": branchId,
      "status": status,
    };

    debugPrint("SAVE HOSTEL REQUEST: $body");

    final response = await http
        .post(url, headers: _authHeaders(token), body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));

    debugPrint("SAVE HOSTEL RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);

    final isSuccess =
        decoded["success"] == true ||
        decoded["success"] == "true" ||
        decoded["success"] == 1;

    if (!isSuccess) {
      throw Exception(decoded["message"] ?? "Failed to save hostel building");
    }
  }

  // ================= GET STUDENTS BY FLOOR =================
  static Future<List<Map<String, dynamic>>> getStudentsByFloor(
    int floorId,
  ) async {
    final res = await getRequest(ApiCollection.getStudentsByFloor(floorId));

    debugPrint("STUDENTS BY FLOOR RESPONSE: $res");

    if ((res["success"] == true ||
            res["success"] == "true" ||
            res["success"] == 1) &&
        res["indexdata"] != null) {
      return List<Map<String, dynamic>>.from(res["indexdata"]);
    }

    return [];
  }
}
