class ApiCollection {
  static const String baseUrl = "https://stage.srisaraswathigroups.in/api";

  // ================= LOGIN =================
  static String login({required String username, required String password}) {
    return "/login"
        "?user_login=${Uri.encodeQueryComponent(username)}"
        "&password=${Uri.encodeQueryComponent(password)}";
  }

  // ================= COMMON =================
  static const String branchList = "/branchlist";
  static String groupsByBranch(int branchId) => "/groupslistbybranch/$branchId";
  static String coursesByGroup(int groupId) => "/courselistbygroup/$groupId";
  static String batchesByCourse(int courseId) => "/batchlistbycourse/$courseId";
  static String shiftsByBranch(int branchId) => "/shiftlistbybranch/$branchId";
  static String studentByAdmNo(String admNo) =>
      "/getstudentdetailsbysearch/$admNo";
  static const String categoryList = "/categorylist";

  // ================= OUTING =================
  static String outingList({
    String? branch,
    String? reportType,
    String? daybookFilter,
    String? firstDate,
    String? nextDate,
  }) {
    return "/outinglist"
        "?branch[]=${Uri.encodeQueryComponent(branch ?? "All")}"
        "&report_type=${Uri.encodeQueryComponent(reportType ?? "All")}"
        "&daybookfilter=${Uri.encodeQueryComponent(daybookFilter ?? "All")}"
        "&firstdate=${Uri.encodeQueryComponent(firstDate ?? "")}"
        "&nextdate=${Uri.encodeQueryComponent(nextDate ?? "")}";
  }

  static const String pendingOutingList = "/getpendingoutinglist";
  static String outingDetails(int id) => "/getoutinglist/$id";

  static String outingSearch(String identifier) =>
      "/outing-search/${Uri.encodeComponent(identifier)}";

  static const String addOutingRemarks = "/add-outing-remarks";
  static const String updateOutingLetter = "/stduent_outing_letter_update";
  static const String updateOutingPhoto = "/stduent_outing_photo_update";
  static const String storeOuting = "/storeouting";
  static String inreportOuting(int id) => "/inreport_outing/$id";
  static String approveOuting(int id) => "/approve_outing/$id";

  // ================= HR =================
  static const String departmentsList = "/departmentslist";
  static const String designationsList = "/designationslist";
  static const String examsList = "/exams_list";
  static const String myProfile = "/myprofile";
  static String addHostelMember = "/addhostelmember";
  static String editHostelMember = "/edithostelmember";
  static String deleteHostelMember = "/deletehostelmember";
  static const String assignIncharges = "/assignincharges";

  static String feeHeadsByBranch(int branchId) => "/feeheadsbybranch/$branchId";
  static String getHostelsByBranch(int branchId) =>
      "/gethostelsbybranch/$branchId";
  static const String saveHostel = "/savehostel";

  // ================= CLASS STUDENTS LIST =================
  static String getStudentsAttendanceList({
    required int shiftId,
    required String date,
    required int batchId,
  }) {
    return "/get_students_attendance_list"
        "?shift=$shiftId"
        "&date=$date"
        "&batchid=$batchId";
  }

  static String getClassStudents({
    required int branchId,
    required int groupId,
    required int courseId,
    required int batchId,
    required int shiftId,
  }) {
    return "/monthlyattendanceList"
        "?branchid=$branchId"
        "&groupid=$groupId"
        "&courseid=$courseId"
        "&batchid=$batchId"
        "&month=" // empty month to just get students
        "&shift=$shiftId";
  }

  // ================= STORE CLASS ATTENDANCE =================
  /// NOTE: Backend endpoint has a typo "store_student_attendace"
  static String storeStudentAttendance({
    required int branchId,
    required int groupId,
    required int courseId,
    required int batchId,
    required int shiftId,
    required List<int> sidList,
    required List<String> statusList,
  }) {
    final sids = sidList.map((e) => "sid[]=$e").join("&");
    final status = statusList.map((e) => "at_status[]=$e").join("&");

    return "/store_student_attendace"
        "?branch_id=$branchId"
        "&group_id=$groupId"
        "&course_id=$courseId"
        "&batch_id=$batchId"
        "&shift=$shiftId"
        "&$sids"
        "&$status";
  }

  // ================= MONTHLY ATTENDANCE (ACADEMIC) =================
  static String monthlyAttendance({
    required int branchId,
    required int groupId,
    required int courseId,
    required int batchId,
    required String month,
    required int shiftId,
  }) {
    return "/monthlyattendanceList"
        "?branchid=$branchId"
        "&groupid=$groupId"
        "&courseid=$courseId"
        "&batchid=$batchId"
        "&month=$month"
        "&shift=$shiftId";
  }

  // ============================================================
  // 🏨 HOSTEL ATTENDANCE (NEW – IMPORTANT)
  // ============================================================

  /// 1️⃣ Get students in a hostel room
  static String getRoomStudentsAttendance({
    required String shift,
    required String date,
    required String param, // room id
  }) {
    return "/getroomstudents_attendance"
        "?shift=$shift"
        "&date=$date"
        "&param=$param";
  }

  static String hostelMembersList({
    required String type,
    required String param,
  }) {
    return "/hostelmemberslist?type=$type&param=$param";
  }

  /// 2️⃣ Store hostel attendance (GET as per backend)
  static String storeHostelAttendance({
    required String branchId,
    required String hostel, // building_id
    required String floor,
    required String room,
    required String shift,
    required List<int> sidList,
    required List<String> statusList,
  }) {
    final sids = sidList.map((e) => "sid[]=$e").join("&");
    final status = statusList.map((e) => "at_status[]=$e").join("&");

    // NOTE: Backend endpoint has a typo "store_hostel_attendace"
    return "/store_hostel_attendace"
        "?branch_id=$branchId"
        "&hostel=$hostel"
        "&floor=$floor"
        "&room=$room"
        "&shift=$shift"
        "&$sids"
        "&$status";
  }

  /// 3️⃣ Get room attendance (student-wise)
  static String getRoomAttendance({required String roomId}) {
    return "/getroomattendance?param=$roomId";
  }

  static String getVerifyAttendance({
    required int branchId,
    required int shiftId,
  }) {
    return "/verify_attendance?branch=$branchId&shift=$shiftId";
  }

  static String getVerifyAttendanceDetailed({
    required int branchId,
    required int shiftId,
  }) {
    return "/getverify_attendance?branch_id=$branchId&shift=$shiftId";
  }

  static String verifyStoreAttendance({
    required List<int> branchIds,
    required List<int> groupIds,
    required List<int> courseIds,
    required List<int> batchIds,
    required List<int> totalStrengths,
    required List<int> totalPresents,
    required List<int> totalAbsents,
  }) {
    final bIds = branchIds.map((e) => "branch_id[]=$e").join("&");
    final gIds = groupIds.map((e) => "group_id[]=$e").join("&");
    final cIds = courseIds.map((e) => "course_id[]=$e").join("&");
    final batIds = batchIds.map((e) => "batch_id[]=$e").join("&");
    final strengths = totalStrengths
        .map((e) => "total_strength[]=$e")
        .join("&");
    final presents = totalPresents.map((e) => "total_present[]=$e").join("&");
    final absents = totalAbsents.map((e) => "total_absent[]=$e").join("&");

    return "/verify_store_attendance"
        "?$bIds"
        "&$gIds"
        "&$cIds"
        "&$batIds"
        "&$strengths"
        "&$presents"
        "&$absents";
  }

  /// 4️⃣ Rooms attendance summary (POST)
  static String roomsAttendance() {
    return "/rooms-attendance";
  }

  static const String roomsAttendanceEndpoint = "/rooms-attendance";

  /// 5️⃣ Hostel attendance monthly grid
  static String hostelAttendanceGrid(int sid) {
    return "/hostel-attendance-grid/$sid";
  }

  static String getRoomsByFloor(int floorId) => "/getroomsbyfloor/$floorId";

  static String getFloorIncharges(int buildingId) =>
      "/getfloorincharges/$buildingId";

  static String getFloorsByIncharge(int inchargeId) =>
      "/getfloorsbyincharge/$inchargeId";

  static String getFloorsByHostel(int hostelId) =>
      "/getfloorsbyhostel/$hostelId";

  static String getNonHostelStudents(int branchId) =>
      "/getnonhostelstudents/$branchId";

  static String getStudentsByFloor(int floorId) =>
      "/getstudentsbyfloor/$floorId";
}
