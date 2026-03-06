class ProDashboardModel {
  final int target;
  final int totalAdmissions;
  final int today;
  final int yesterday;
  final int thisWeek;
  final int thisMonth;
  final int lastMonth;
  final int boys;
  final int girls;
  final int paid;
  final int notPaid;
  final int hostel;
  final int day;
  final int nonLocal;
  final int local;
  final List<CourseWiseData> courseWise;

  ProDashboardModel({
    required this.target,
    required this.totalAdmissions,
    required this.today,
    required this.yesterday,
    required this.thisWeek,
    required this.thisMonth,
    required this.lastMonth,
    required this.boys,
    required this.girls,
    required this.paid,
    required this.notPaid,
    required this.hostel,
    required this.day,
    required this.nonLocal,
    required this.local,
    required this.courseWise,
  });

  factory ProDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProDashboardModel(
      target: json['target'] ?? 0,
      totalAdmissions: json['total_admissions'] ?? 0,
      today: json['today'] ?? 0,
      yesterday: json['yesterday'] ?? 0,
      thisWeek: json['thisweek'] ?? 0,
      thisMonth: json['thismonth'] ?? 0,
      lastMonth: json['lastmonth'] ?? 0,
      boys: json['boys'] ?? 0,
      girls: json['girls'] ?? 0,
      paid: json['paid'] ?? 0,
      notPaid: json['not_paid'] ?? 0,
      hostel: json['hostel'] ?? 0,
      day: json['day'] ?? 0,
      nonLocal: json['non_local'] ?? 0,
      local: json['local'] ?? 0,
      courseWise: (json['coursewise'] as List? ?? [])
          .map((e) => CourseWiseData.fromJson(e))
          .toList(),
    );
  }
}

class CourseWiseData {
  final String branchName;
  final String groupName;
  final String courseName;
  final int courses;
  final int converted;

  CourseWiseData({
    required this.branchName,
    required this.groupName,
    required this.courseName,
    required this.courses,
    required this.converted,
  });

  factory CourseWiseData.fromJson(Map<String, dynamic> json) {
    return CourseWiseData(
      branchName: json['branch_name'] ?? '',
      groupName: json['groupname'] ?? '',
      courseName: json['coursename'] ?? '',
      courses: json['courses'] ?? 0,
      converted: json['CONVERTED'] ?? 0,
    );
  }
}
