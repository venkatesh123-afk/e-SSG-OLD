import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_app/staff_app/api/api_service.dart';
import 'package:student_app/staff_app/model/outing_model.dart';
import 'package:student_app/staff_app/model/OutingInfo.dart';
import 'package:student_app/staff_app/controllers/branch_controller.dart';

class OutingController extends GetxController {
  // ================= LOADING =================
  final RxBool isLoading = false.obs;

  // ================= OUTING LIST =================
  final RxList<OutingModel> outingList = <OutingModel>[].obs;
  final RxList<OutingModel> filteredList = <OutingModel>[].obs;
  final RxList<OutingModel> selectedStudentOutings = <OutingModel>[].obs;

  // ================= FILTER STATES =================
  final RxString selectedBranch = "All".obs;
  final RxString selectedStatus = "All".obs;
  final RxBool isTodayFilter = false.obs;
  final RxString searchQuery = "".obs;

  DateTime? fromDate;
  DateTime? toDate;

  // ================= SUMMARY (TOP CARDS) =================
  final Rx<OutingInfo?> outPassInfo = Rx<OutingInfo?>(null);
  final Rx<OutingInfo?> homePassInfo = Rx<OutingInfo?>(null);
  final Rx<OutingInfo?> selfOutingInfo = Rx<OutingInfo?>(null);
  final Rx<OutingInfo?> selfHomeInfo = Rx<OutingInfo?>(null);

  @override
  void onInit() {
    super.onInit();
    // Pre-load branches to ensure we can resolve IDs to names for filtering
    Get.find<BranchController>().loadBranches();
    fetchOutings();
  }

  // ================= FETCH OUTINGS =================

  Future<void> fetchStudentOutings(String identifier, {String? sid}) async {
    try {
      isLoading.value = true;
      debugPrint("🔍 FETCHING HISTORY FOR IDENTIFIER: $identifier (SID: $sid)");

      List<Map<String, dynamic>> data = [];

      try {
        data = await ApiService.searchOutingsByName(identifier);
        debugPrint("📦 API HISTORY (ID) RECEIVED: ${data.length} items");

        // 💡 If ID search is empty but SID is available, try searching by SID
        if (data.isEmpty && sid != null && sid.isNotEmpty) {
          debugPrint("🔍 TRYING SID SEARCH: $sid");
          data = await ApiService.searchOutingsByName(sid);
          debugPrint("📦 API HISTORY (SID) RECEIVED: ${data.length} items");
        }
      } catch (apiErr) {
        debugPrint("❌ API ERROR IN SEARCH: $apiErr");
      }

      if (data.isNotEmpty) {
        debugPrint("📦 FIRST ITEM: ${data.first}");
      }

      List<OutingModel> apiList = data
          .map((e) => OutingModel.fromJson(e))
          .toList();

      debugPrint("📦 MAPPED LIST SIZE: ${apiList.length}");

      // 🔗 FALLBACK: If API is empty, search local outingList by identifier (admNo or name)
      if (apiList.isEmpty) {
        debugPrint("🔗 FALLBACK: Searching local list for ID: $identifier");
        final localHistory = outingList
            .where(
              (o) =>
                  o.admno.toLowerCase().trim() ==
                      identifier.toLowerCase().trim() ||
                  o.studentName.toLowerCase().contains(
                    identifier.toLowerCase().trim(),
                  ) ||
                  (sid != null && o.id.toString() == sid),
            )
            .toList();
        debugPrint("🔗 FALLBACK FOUND: ${localHistory.length} items");
        selectedStudentOutings.assignAll(localHistory);
      } else {
        selectedStudentOutings.assignAll(apiList);
      }
    } catch (e) {
      debugPrint("❌ FETCH STUDENT OUTINGS CRITICAL ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ================= FETCH OUTINGS =================
  final RxString selectedDateFilterType = "All".obs;

  Future<void> fetchOutings({
    String? branch,
    String? reportType,
    String? daybookFilter,
    String? firstDate,
    String? nextDate,
  }) async {
    try {
      isLoading.value = true;

      // Use provided params or fall back to current state
      final String targetBranch = branch ?? selectedBranch.value;
      final String targetStatus = reportType ?? selectedStatus.value;
      final String targetDaybook =
          daybookFilter ?? selectedDateFilterType.value;
      final String targetFirstDate =
          firstDate ??
          (fromDate != null ? fromDate!.toString().substring(0, 10) : "");
      final String targetNextDate =
          nextDate ??
          (toDate != null ? toDate!.toString().substring(0, 10) : "");

      final Map<String, dynamic> res = await ApiService.getOutingListRaw(
        branch: targetBranch,
        reportType: targetStatus,
        daybookFilter: targetDaybook,
        firstDate: targetFirstDate,
        nextDate: targetNextDate,
      );

      // ===== LIST DATA =====
      final List listData = res['indexdata'] ?? [];
      final list = listData.map((e) => OutingModel.fromJson(e)).toList();

      outingList.assignAll(list);
      applyFilters(); // Apply search if any

      // ===== SUMMARY DATA =====
      final info = res['outing_info'];
      if (info != null) {
        if (info['outpass']?.isNotEmpty == true) {
          outPassInfo.value = OutingInfo.fromJson(info['outpass'][0]);
        }
        if (info['homepass']?.isNotEmpty == true) {
          homePassInfo.value = OutingInfo.fromJson(info['homepass'][0]);
        }
        if (info['selfouting']?.isNotEmpty == true) {
          selfOutingInfo.value = OutingInfo.fromJson(info['selfouting'][0]);
        }
        if (info['selfhome']?.isNotEmpty == true) {
          selfHomeInfo.value = OutingInfo.fromJson(info['selfhome'][0]);
        }
      }
    } catch (e) {
      print("❌ OutingController error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ================= APPLY ALL FILTERS (CLIENT SIDE) =================
  void applyFilters() {
    List<OutingModel> temp = outingList.toList();

    // 1️⃣ STRICT STATUS FILTERING
    if (selectedStatus.value != "All") {
      temp = temp
          .where(
            (o) =>
                o.status.toLowerCase().trim() ==
                selectedStatus.value.toLowerCase().trim(),
          )
          .toList();
    }

    // 2️⃣ STRICT BRANCH FILTERING
    if (selectedBranch.value != "All") {
      final bController = Get.find<BranchController>();
      final String selectedId = selectedBranch.value;

      // Find the branch name for the selected ID
      final branchModel = bController.branches.firstWhereOrNull(
        (b) => b.id.toString() == selectedId,
      );
      final String? selectedName = branchModel?.branchName.toLowerCase().trim();

      temp = temp.where((o) {
        final String recordBranch = o.branch.toLowerCase().trim();
        // Match if:
        // 1. Record branch matches selected name
        // 2. Record branch matches selected ID (if record stores ID)
        return (selectedName != null && recordBranch == selectedName) ||
            recordBranch == selectedId;
      }).toList();
    }

    // 3️⃣ SEARCH FILTERING (Checks Name, Adm No, and Outing Type)
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase().trim();
      temp = temp
          .where(
            (o) =>
                o.studentName.toLowerCase().contains(q) ||
                o.admno.toLowerCase().contains(q) ||
                o.outingType.toLowerCase().contains(q),
          )
          .toList();
    }

    filteredList.assignAll(temp);
  }

  // ================= FILTER ACTIONS (STATE UPDATES ONLY) =================
  void search(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void updateBranch(String branch) {
    selectedBranch.value = branch;
  }

  void updateStatus(String status) {
    selectedStatus.value = status;
  }

  void updateDateFilter(String type) {
    selectedDateFilterType.value = type;
    final now = DateTime.now();

    if (type == "Last7Days") {
      fromDate = now.subtract(const Duration(days: 7));
      toDate = now;
      selectedDateFilterType.value = "Custom";
    } else if (type == "ThisMonth") {
      fromDate = DateTime(now.year, now.month, 1);
      toDate = now;
      selectedDateFilterType.value = "Custom";
    } else if (type == "LastMonth") {
      fromDate = DateTime(now.year, now.month - 1, 1);
      toDate = DateTime(now.year, now.month, 0); // Last day of previous month
      selectedDateFilterType.value = "Custom";
    } else if (type != "Custom") {
      fromDate = null;
      toDate = null;
    }
  }

  void updateCustomDates(DateTime from, DateTime to) {
    fromDate = from;
    toDate = to;
    selectedDateFilterType.value = "Custom";
  }

  // ================= RESET =================
  void filterAll() {
    selectedBranch.value = "All";
    selectedStatus.value = "All";
    selectedDateFilterType.value = "All";
    isTodayFilter.value = false;
    searchQuery.value = "";
    fromDate = null;
    toDate = null;
    fetchOutings();
  }

  // ================= COUNTS =================
  int countApproved() =>
      filteredList.where((o) => o.status == "Approved").length;

  int countPending() => filteredList.where((o) => o.status == "Pending").length;

  int countNotReported() =>
      filteredList.where((o) => o.status == "Not Reported").length;

  // ================= ACTIONS =================
  Future<bool> addOutingRemarks(int outingId, String remarks) async {
    try {
      isLoading.value = true;
      await ApiService.addOutingRemarks(outingId: outingId, remarks: remarks);

      // Refresh the list after successful update
      await fetchOutings();

      Get.snackbar(
        "Success",
        "Remarks updated successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString().replaceFirst("Exception: ", ""),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}



// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:student_app/staff_app/api/api_service.dart';
// import 'package:student_app/staff_app/model/outing_model.dart';
// import 'package:student_app/staff_app/model/OutingInfo.dart';
// import 'package:student_app/staff_app/controllers/branch_controller.dart';

// class OutingController extends GetxController {

//   // ================= LOADING STATES =================

//   final RxBool isSummaryLoading = false.obs; // Top cards
//   final RxBool isListLoading = false.obs; // Student list
//   final RxBool isActionLoading = false.obs; // Remarks / actions

//   // ================= OUTING LIST =================

//   final RxList<OutingModel> outingList = <OutingModel>[].obs;
//   final RxList<OutingModel> filteredList = <OutingModel>[].obs;
//   final RxList<OutingModel> selectedStudentOutings = <OutingModel>[].obs;

//   // ================= FILTER STATES =================

//   final RxString selectedBranch = "All".obs;
//   final RxString selectedStatus = "All".obs;
//   final RxString selectedDateFilterType = "All".obs;
//   final RxBool isTodayFilter = false.obs;
//   final RxString searchQuery = "".obs;

//   DateTime? fromDate;
//   DateTime? toDate;

//   // ================= SUMMARY (TOP CARDS) =================

//   final Rx<OutingInfo?> outPassInfo = Rx<OutingInfo?>(null);
//   final Rx<OutingInfo?> homePassInfo = Rx<OutingInfo?>(null);
//   final Rx<OutingInfo?> selfOutingInfo = Rx<OutingInfo?>(null);
//   final Rx<OutingInfo?> selfHomeInfo = Rx<OutingInfo?>(null);

//   @override
//   void onInit() {
//     super.onInit();

//     // Load branches first
//     Get.find<BranchController>().loadBranches();

//     // Load outing data
//     fetchOutings();
//   }

//   // ================= FETCH STUDENT HISTORY =================

//   Future<void> fetchStudentOutings(String identifier, {String? sid}) async {
//     try {
//       isListLoading.value = true;

//       List<Map<String, dynamic>> data = [];

//       try {
//         data = await ApiService.searchOutingsByName(identifier);

//         if (data.isEmpty && sid != null && sid.isNotEmpty) {
//           data = await ApiService.searchOutingsByName(sid);
//         }
//       } catch (apiErr) {
//         debugPrint("API ERROR: $apiErr");
//       }

//       List<OutingModel> apiList =
//           data.map((e) => OutingModel.fromJson(e)).toList();

//       if (apiList.isEmpty) {
//         final localHistory = outingList.where((o) {
//           return o.admno.toLowerCase().trim() ==
//                   identifier.toLowerCase().trim() ||
//               o.studentName
//                   .toLowerCase()
//                   .contains(identifier.toLowerCase().trim()) ||
//               (sid != null && o.id.toString() == sid);
//         }).toList();

//         selectedStudentOutings.assignAll(localHistory);
//       } else {
//         selectedStudentOutings.assignAll(apiList);
//       }
//     } catch (e) {
//       debugPrint("FETCH STUDENT ERROR: $e");
//     } finally {
//       isListLoading.value = false;
//     }
//   }

//   // ================= FETCH OUTINGS =================

//   Future<void> fetchOutings({
//     String? branch,
//     String? reportType,
//     String? daybookFilter,
//     String? firstDate,
//     String? nextDate,
//   }) async {
//     try {
//       isSummaryLoading.value = true;
//       isListLoading.value = true;

//       final String targetBranch = branch ?? selectedBranch.value;
//       final String targetStatus = reportType ?? selectedStatus.value;
//       final String targetDaybook =
//           daybookFilter ?? selectedDateFilterType.value;

//       final String targetFirstDate =
//           firstDate ??
//           (fromDate != null ? fromDate!.toString().substring(0, 10) : "");

//       final String targetNextDate =
//           nextDate ??
//           (toDate != null ? toDate!.toString().substring(0, 10) : "");

//       final Map<String, dynamic> res = await ApiService.getOutingListRaw(
//         branch: targetBranch,
//         reportType: targetStatus,
//         daybookFilter: targetDaybook,
//         firstDate: targetFirstDate,
//         nextDate: targetNextDate,
//       );

//       // ===== LIST DATA =====

//       final List listData = res['indexdata'] ?? [];

//       final list = listData.map((e) => OutingModel.fromJson(e)).toList();

//       outingList.assignAll(list);

//       applyFilters();

//       // ===== SUMMARY DATA =====

//       final info = res['outing_info'];

//       if (info != null) {
//         if (info['outpass']?.isNotEmpty == true) {
//           outPassInfo.value = OutingInfo.fromJson(info['outpass'][0]);
//         }

//         if (info['homepass']?.isNotEmpty == true) {
//           homePassInfo.value = OutingInfo.fromJson(info['homepass'][0]);
//         }

//         if (info['selfouting']?.isNotEmpty == true) {
//           selfOutingInfo.value = OutingInfo.fromJson(info['selfouting'][0]);
//         }

//         if (info['selfhome']?.isNotEmpty == true) {
//           selfHomeInfo.value = OutingInfo.fromJson(info['selfhome'][0]);
//         }
//       }
//     } catch (e) {
//       print("OutingController error: $e");
//     } finally {
//       isSummaryLoading.value = false;
//       isListLoading.value = false;
//     }
//   }

//   // ================= APPLY FILTERS =================

//   void applyFilters() {
//     List<OutingModel> temp = outingList.toList();

//     // Status filter
//     if (selectedStatus.value != "All") {
//       temp = temp
//           .where((o) =>
//               o.status.toLowerCase().trim() ==
//               selectedStatus.value.toLowerCase().trim())
//           .toList();
//     }

//     // Branch filter
//     if (selectedBranch.value != "All") {
//       final bController = Get.find<BranchController>();

//       final branchModel = bController.branches.firstWhereOrNull(
//           (b) => b.id.toString() == selectedBranch.value);

//       final selectedName = branchModel?.branchName.toLowerCase().trim();

//       temp = temp.where((o) {
//         final recordBranch = o.branch.toLowerCase().trim();

//         return (selectedName != null && recordBranch == selectedName) ||
//             recordBranch == selectedBranch.value;
//       }).toList();
//     }

//     // Search filter
//     if (searchQuery.value.isNotEmpty) {
//       final q = searchQuery.value.toLowerCase().trim();

//       temp = temp.where((o) {
//         return o.studentName.toLowerCase().contains(q) ||
//             o.admno.toLowerCase().contains(q) ||
//             o.outingType.toLowerCase().contains(q);
//       }).toList();
//     }

//     filteredList.assignAll(temp);
//   }

//   // ================= FILTER ACTIONS =================

//   void search(String query) {
//     searchQuery.value = query;
//     applyFilters();
//   }

//   void updateBranch(String branch) {
//     selectedBranch.value = branch;
//   }

//   void updateStatus(String status) {
//     selectedStatus.value = status;
//   }

//   void updateDateFilter(String type) {
//     selectedDateFilterType.value = type;

//     final now = DateTime.now();

//     if (type == "Last7Days") {
//       fromDate = now.subtract(const Duration(days: 7));
//       toDate = now;
//       selectedDateFilterType.value = "Custom";
//     } else if (type == "ThisMonth") {
//       fromDate = DateTime(now.year, now.month, 1);
//       toDate = now;
//       selectedDateFilterType.value = "Custom";
//     } else if (type == "LastMonth") {
//       fromDate = DateTime(now.year, now.month - 1, 1);
//       toDate = DateTime(now.year, now.month, 0);
//       selectedDateFilterType.value = "Custom";
//     } else if (type != "Custom") {
//       fromDate = null;
//       toDate = null;
//     }
//   }

//   void updateCustomDates(DateTime from, DateTime to) {
//     fromDate = from;
//     toDate = to;
//     selectedDateFilterType.value = "Custom";
//   }

//   // ================= RESET =================

//   void filterAll() {
//     selectedBranch.value = "All";
//     selectedStatus.value = "All";
//     selectedDateFilterType.value = "All";
//     isTodayFilter.value = false;
//     searchQuery.value = "";
//     fromDate = null;
//     toDate = null;

//     fetchOutings();
//   }

//   // ================= COUNTS =================

//   int countApproved() =>
//       filteredList.where((o) => o.status == "Approved").length;

//   int countPending() =>
//       filteredList.where((o) => o.status == "Pending").length;

//   int countNotReported() =>
//       filteredList.where((o) => o.status == "Not Reported").length;

//   // ================= ACTIONS =================

//   Future<bool> addOutingRemarks(int outingId, String remarks) async {
//     try {
//       isActionLoading.value = true;

//       await ApiService.addOutingRemarks(
//         outingId: outingId,
//         remarks: remarks,
//       );

//       await fetchOutings();

//       Get.snackbar(
//         "Success",
//         "Remarks updated successfully",
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//       );

//       return true;
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         e.toString().replaceFirst("Exception: ", ""),
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );

//       return false;
//     } finally {
//       isActionLoading.value = false;
//     }
//   }
// }