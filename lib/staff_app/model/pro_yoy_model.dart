class ProYoyModel {
  final bool success;
  final List<String> sessions;
  final List<ProYoyData> data;

  ProYoyModel({
    required this.success,
    required this.sessions,
    required this.data,
  });

  factory ProYoyModel.fromJson(Map<String, dynamic> json) {
    return ProYoyModel(
      success: json['success'] ?? false,
      sessions: List<String>.from(json['sessions'] ?? []),
      data: (json['data'] as List? ?? [])
          .map((e) => ProYoyData.fromJson(e))
          .toList(),
    );
  }
}

class ProYoyData {
  final String proName;
  final List<ProHistory> history;

  ProYoyData({required this.proName, required this.history});

  factory ProYoyData.fromJson(Map<String, dynamic> json) {
    return ProYoyData(
      proName: json['proname'] ?? '',
      history: (json['history'] as List? ?? [])
          .map((e) => ProHistory.fromJson(e))
          .toList(),
    );
  }
}

class ProHistory {
  final String sessionName;
  final int admissions;

  ProHistory({required this.sessionName, required this.admissions});

  factory ProHistory.fromJson(Map<String, dynamic> json) {
    return ProHistory(
      sessionName: json['session_name'] ?? '',
      admissions: json['admissions'] ?? 0,
    );
  }
}
