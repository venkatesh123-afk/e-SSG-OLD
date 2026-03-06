class ProMomModel {
  final bool success;
  final List<String> months;
  final List<SessionData> data;

  ProMomModel({
    required this.success,
    required this.months,
    required this.data,
  });

  factory ProMomModel.fromJson(Map<String, dynamic> json) {
    return ProMomModel(
      success: json['success'] ?? false,
      months: List<String>.from(json['months'] ?? []),
      data: (json['data'] as List? ?? [])
          .map((e) => SessionData.fromJson(e))
          .toList(),
    );
  }
}

class SessionData {
  final String sessionName;
  final List<MonthCount> months;

  SessionData({required this.sessionName, required this.months});

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      sessionName: json['session_name'] ?? '',
      months: (json['months'] as List? ?? [])
          .map((e) => MonthCount.fromJson(e))
          .toList(),
    );
  }
}

class MonthCount {
  final String month;
  final int count;

  MonthCount({required this.month, required this.count});

  factory MonthCount.fromJson(Map<String, dynamic> json) {
    return MonthCount(month: json['month'] ?? '', count: json['count'] ?? 0);
  }
}
