class OutingModel {
  final int id;
  final String admno;
  final String studentName;
  final String outingType;
  final String outDate;
  final String outingTime;
  final String purpose;
  final String status;
  final String permission;
  final String branch;

  OutingModel({
    required this.id,
    required this.admno,
    required this.studentName,
    required this.outingType,
    required this.outDate,
    required this.outingTime,
    required this.purpose,
    required this.status,
    required this.permission,
    required this.branch,
  });

  factory OutingModel.fromJson(Map<String, dynamic> json) {
    return OutingModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      admno: (json['admno'] ?? json['adm_no'] ?? '').toString(),
      studentName:
          (json['student_name'] ??
                  json['sname'] ??
                  json['studentname'] ??
                  json['name'] ??
                  '')
              .toString(),
      outingType:
          (json['passtype'] ??
                  json['pass_type'] ??
                  json['outingtype'] ??
                  json['outing_type'] ??
                  json['type'] ??
                  '')
              .toString(),
      outDate:
          (json['outing_date'] ??
                  json['out_date'] ??
                  json['outdate'] ??
                  json['date'] ??
                  '')
              .toString(),
      outingTime:
          (json['outtime'] ??
                  json['out_time'] ??
                  json['out_time'] ??
                  json['outing_time'] ??
                  json['time'] ??
                  '')
              .toString(),
      purpose: (json['purpose'] ?? json['outpurpuse'] ?? '').toString(),
      status: (json['status'] ?? json['at_status'] ?? '').toString(),
      permission: (json['permission'] ?? json['approved_by'] ?? '').toString(),
      branch: (json['branch'] ?? json['branch_name'] ?? '').toString(),
    );
  }
}
