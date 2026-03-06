class ProAdmissionsChartModel {
  final bool success;
  final List<ProAdmissionPerformance> data;

  ProAdmissionsChartModel({required this.success, required this.data});

  factory ProAdmissionsChartModel.fromJson(Map<String, dynamic> json) {
    return ProAdmissionsChartModel(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((e) => ProAdmissionPerformance.fromJson(e))
          .toList(),
    );
  }
}

class ProAdmissionPerformance {
  final String proName;
  final int target;
  final int totalAdmissions;
  final int converted;
  final double reachedPercent;

  ProAdmissionPerformance({
    required this.proName,
    required this.target,
    required this.totalAdmissions,
    required this.converted,
    required this.reachedPercent,
  });

  factory ProAdmissionPerformance.fromJson(Map<String, dynamic> json) {
    return ProAdmissionPerformance(
      proName: json['proname'] ?? '',
      target: json['target'] ?? 0,
      totalAdmissions: json['total_admissions'] ?? 0,
      converted: json['converted'] ?? 0,
      reachedPercent: (json['reached_percent'] is int)
          ? (json['reached_percent'] as int).toDouble()
          : (json['reached_percent'] ?? 0.0),
    );
  }
}
