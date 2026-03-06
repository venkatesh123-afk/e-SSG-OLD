import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/hostel_controller.dart';
import 'hostel_attendance_grid_page.dart';
import '../widgets/skeleton.dart';
import '../widgets/success_dialog.dart';

class HostelAttendanceMarkPage extends StatefulWidget {
  const HostelAttendanceMarkPage({super.key});

  @override
  State<HostelAttendanceMarkPage> createState() =>
      _HostelAttendanceMarkPageState();
}

class _HostelAttendanceMarkPageState extends State<HostelAttendanceMarkPage> {
  final HostelController hostelCtrl = Get.find<HostelController>();
  final Map<String, dynamic> args = Get.arguments;

  // COLORS
  static const Color neon = Color(0xFF00FFF5);
  static const Color darkNavy = Color(0xFF1a1a2e);
  static const Color darkBlue = Color(0xFF16213e);
  static const Color midBlue = Color(0xFF0f3460);
  static const Color purpleDark = Color(0xFF533483);

  // State for attendance marking
  final Map<int, String> _statuses = {}; // sid -> status (P/A)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  Future<void> _loadStudents() async {
    // Note: Adjust params based on what's available in args
    // We need shift and date. For now, using defaults.
    final roomId = hostelCtrl.getRoomIdFromName(
      args['room_id']?.toString() ?? '',
    );
    await hostelCtrl.loadRoomStudents(
      shift: '1', // Default shift
      date: args['date'] ?? hostelCtrl.activeDate.value,
      roomId: roomId,
    );

    // Initialize statuses to Present by default
    for (final s in hostelCtrl.roomStudents) {
      _statuses[s.sid] = 'P';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomName = args['room_name'] ?? 'Room';

    return Scaffold(
      backgroundColor: const Color(0xFF16213e),
      appBar: AppBar(
        title: Text(
          "Mark Attendance - $roomName",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? Colors.black.withOpacity(0.35)
            : Colors.white.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.until(
            (route) => route.settings.name == '/hostelAttendanceFilter',
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [darkNavy, darkBlue, midBlue, purpleDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isDark ? null : Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (hostelCtrl.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonList(itemCount: 5),
                  );
                }

                if (hostelCtrl.roomStudents.isEmpty) {
                  return const Center(
                    child: Text(
                      "No students found in this room",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Shortcut Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              for (final s in hostelCtrl.roomStudents) {
                                _statuses[s.sid] = 'P';
                              }
                              setState(() {});
                            },
                            icon: const Icon(Icons.done_all, size: 16),
                            label: const Text("All Present"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              foregroundColor: Colors.greenAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: hostelCtrl.roomStudents.length,
                        itemBuilder: (context, index) {
                          final student = hostelCtrl.roomStudents[index];
                          final sid = student.sid;
                          final currentStatus = _statuses[sid] ?? 'P';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? null
                                  : Theme.of(context).cardColor,
                              gradient: isDark
                                  ? const LinearGradient(
                                      colors: [midBlue, purpleDark],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? neon.withOpacity(0.35)
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.studentName,
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            "Adm: ${student.admno}",
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.history,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => Get.to(
                                        () => HostelAttendanceGridPage(
                                          sid: student.sid,
                                          studentName: student.studentName,
                                          admNo: student.admno,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Status Options Wrap
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _statusButton(
                                      'P',
                                      'Present',
                                      Colors.greenAccent,
                                      currentStatus == 'P',
                                      () =>
                                          setState(() => _statuses[sid] = 'P'),
                                    ),
                                    _statusButton(
                                      'A',
                                      'Missing',
                                      Colors.redAccent,
                                      currentStatus == 'A',
                                      () =>
                                          setState(() => _statuses[sid] = 'A'),
                                    ),
                                    _statusButton(
                                      'O',
                                      'Outing',
                                      Colors.orangeAccent,
                                      currentStatus == 'O',
                                      () =>
                                          setState(() => _statuses[sid] = 'O'),
                                    ),
                                    _statusButton(
                                      'H',
                                      'Home',
                                      Colors.purpleAccent,
                                      currentStatus == 'H',
                                      () =>
                                          setState(() => _statuses[sid] = 'H'),
                                    ),
                                    _statusButton(
                                      'SO',
                                      'S.Out',
                                      Colors.tealAccent,
                                      currentStatus == 'SO',
                                      () =>
                                          setState(() => _statuses[sid] = 'SO'),
                                    ),
                                    _statusButton(
                                      'SH',
                                      'S.Home',
                                      Colors.brown,
                                      currentStatus == 'SH',
                                      () =>
                                          setState(() => _statuses[sid] = 'SH'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
            Obx(
              () => hostelCtrl.roomStudents.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submitAttendance,
                          child: const Text(
                            'Submit Attendance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final List<int> sids = [];
    final List<String> statuses = [];

    for (final student in hostelCtrl.roomStudents) {
      sids.add(student.sid);
      statuses.add(_statuses[student.sid] ?? 'P');
    }

    final branchId = hostelCtrl.activeBranch.value;
    final hostelId = hostelCtrl.activeHostel.value;
    final floorId = hostelCtrl.getFloorIdFromName(args['floor_name'] ?? '');
    final roomId = hostelCtrl.getRoomIdFromName(
      args['room_id']?.toString() ?? '',
    );

    final success = await hostelCtrl.submitAttendance(
      branchId: branchId,
      hostel: hostelId,
      floor: floorId,
      room: roomId,
      shift: '1',
      sidList: sids,
      statusList: statuses,
    );

    if (success) {
      final int total = hostelCtrl.roomStudents.length;
      final int present = _statuses.values.where((s) => s == 'P').length;

      final Map<String, int> extraStats = {
        'Missing': _statuses.values.where((s) => s == 'A').length,
        'Outing': _statuses.values.where((s) => s == 'O').length,
        'Home Pass': _statuses.values.where((s) => s == 'H').length,
        'Self Outing': _statuses.values.where((s) => s == 'SO').length,
        'Self Home': _statuses.values.where((s) => s == 'SH').length,
      };

      Get.dialog(
        SuccessDialog(
          title: "Success",
          message: "Attendance has been submitted successfully!",
          total: total,
          present: present,
          extraStats: extraStats,
          onConfirm: () {
            // Close only the success dialog
            Get.back();

            // Refresh summary for the whole floor to reflect the newly marked attendance
            // We use the floor name (args['floor_name']) for the summary API
            hostelCtrl.loadRoomAttendanceSummary(
              branch: branchId,
              date: args['date'] ?? hostelCtrl.activeDate.value,
              hostel: hostelId,
              floor: args['floor_name'] ?? hostelCtrl.activeFloor.value,
              room: 'All',
            );
          },
        ),
        barrierDismissible: false,
      );
    }
  }

  Widget _statusButton(
    String code,
    String label,
    Color color,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
