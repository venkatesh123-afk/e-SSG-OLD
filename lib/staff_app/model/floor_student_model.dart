class FloorStudentModel {
  final int studentId;
  final String admno;
  final String sfname;
  final String slname;
  final String roomname;
  final int floorId;
  final int roomId;
  final int memberId;

  FloorStudentModel({
    required this.studentId,
    required this.admno,
    required this.sfname,
    required this.slname,
    required this.roomname,
    required this.floorId,
    required this.roomId,
    required this.memberId,
  });

  String get fullName => "$sfname $slname".trim();

  factory FloorStudentModel.fromJson(Map<String, dynamic> json) {
    return FloorStudentModel(
      studentId: int.tryParse(json['student_id']?.toString() ?? '0') ?? 0,
      admno: json['admno']?.toString() ?? '',
      sfname: json['sfname']?.toString() ?? '',
      slname: json['slname']?.toString() ?? '',
      roomname: json['roomname']?.toString() ?? '',
      floorId: int.tryParse(json['floor_id']?.toString() ?? '0') ?? 0,
      roomId: int.tryParse(json['room_id']?.toString() ?? '0') ?? 0,
      memberId: int.tryParse(json['member_id']?.toString() ?? '0') ?? 0,
    );
  }
}
