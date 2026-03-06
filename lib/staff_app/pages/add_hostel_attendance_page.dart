import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/hostel_controller.dart';
import '../controllers/branch_controller.dart';
import '../widgets/skeleton.dart';
import '../widgets/success_dialog.dart';

class AddHostelAttendancePage extends StatefulWidget {
  final String? branch;
  final String? hostel;
  final String? floor;
  final String? room;
  final String? month;
  final String? date;

  const AddHostelAttendancePage({
    super.key,
    this.branch,
    this.hostel,
    this.floor,
    this.room,
    this.month,
    this.date,
  });

  @override
  State<AddHostelAttendancePage> createState() =>
      _AddHostelAttendancePageState();
}

class _AddHostelAttendancePageState extends State<AddHostelAttendancePage> {
  final HostelController hostelCtrl = Get.find<HostelController>();

  // Mock student data - replace with actual API data
  final List<Map<String, dynamic>> students = [];
  final Map<int, String> attendanceStatus = {};

  bool isLoading = false;
  String selectedDate = DateTime.now().toIso8601String().split('T')[0];

  // Attendance status options
  final List<String> statusOptions = [
    'Present',
    'Missing',
    'Outing',
    'Home Pass',
    'Self Outing',
    'Self Home',
  ];

  // DARK COLORS (matching dashboard)
  static const Color dark1 = Color(0xFF1a1a2e);
  static const Color dark2 = Color(0xFF16213e);
  static const Color dark3 = Color(0xFF0f3460);
  static const Color purpleDark = Color(0xFF533483);

  @override
  void initState() {
    super.initState();
    if (widget.date != null) {
      selectedDate = widget.date!;
    }
    // Initialize all students as 'Present' by default
    for (int i = 0; i < students.length; i++) {
      attendanceStatus[i] = 'Present';
    }
  }

  Future<void> _getStudents() async {
    await hostelCtrl.loadRoomStudents(
      shift: '1', // Default shift
      date: selectedDate,
      roomId: widget.room ?? '',
    );

    // Initialize attendance status to 'Present' for all students
    for (final student in hostelCtrl.roomStudents) {
      attendanceStatus[student.sid] = 'Present';
    }
  }

  Future<void> _submitAttendance() async {
    final List<int> sids = [];
    final List<String> statuses = [];

    for (final student in hostelCtrl.roomStudents) {
      sids.add(student.sid);
      // Map full status names to single chars if needed by backend (API usually expects 'P', 'A', 'O', etc.)
      // Assuming backend accepts full words or we map them here.
      // Based on screenshot 3, it sends "A" for Absent.
      // Let's map them.
      String status = attendanceStatus[student.sid] ?? 'Present';
      String statusCode = 'P';
      switch (status) {
        case 'Present':
          statusCode = 'P';
          break;
        case 'Missing':
          statusCode =
              'A'; // or 'M'? Screenshot shows 'A' button, table has 'Missing'. Let's use 'A' for Absent/Missing
          break;
        case 'Outing':
          statusCode = 'O';
          break;
        case 'Home Pass':
          statusCode = 'H';
          break;
        case 'Self Outing':
          statusCode = 'SO';
          break;
        case 'Self Home':
          statusCode = 'SH';
          break;
        default:
          statusCode = 'P';
      }
      statuses.add(statusCode);
    }

    // 1. Find Branch ID
    final BranchController branchCtrl = Get.put(BranchController());
    // If branches aren't loaded, we might need to load them first or rely on pre-loaded data
    if (branchCtrl.branches.isEmpty) {
      await branchCtrl.loadBranches();
    }

    final branchName = widget.branch;
    final branchObj = branchCtrl.branches.firstWhereOrNull(
      (b) => b.branchName == branchName,
    );
    final String branchId =
        branchObj?.id.toString() ?? '1'; // Default to 1 or handle error

    // 2. Find Hostel ID (Building ID)
    // Ensure hostels are loaded for the branch
    if (hostelCtrl.hostels.isEmpty) {
      // We might need to load them if not present, but usually they are if we are here.
      // If not, we can try to load them if we have a branch ID
      if (branchObj != null) {
        await hostelCtrl.loadHostelsByBranch(branchObj.id);
      }
    }

    final hostelName = widget.hostel;
    final hostelObj = hostelCtrl.hostels.firstWhereOrNull(
      (h) => h.buildingName == hostelName,
    );
    final String hostelId = hostelObj?.id.toString() ?? '1';

    // 3. Find Floor ID and Room ID
    final floorId = hostelCtrl.getFloorIdFromName(widget.floor ?? '');
    final roomId = hostelCtrl.getRoomIdFromName(widget.room ?? '');

    final success = await hostelCtrl.submitAttendance(
      branchId: branchId,
      hostel: hostelId, // Building ID
      floor: floorId,
      room: roomId,
      shift: '1',
      sidList: sids,
      statusList: statuses,
    );

    if (success) {
      final int total = hostelCtrl.roomStudents.length;
      final int present = attendanceStatus.values
          .where((s) => s == 'Present')
          .length;

      final Map<String, int> extraStats = {
        'Missing': attendanceStatus.values.where((s) => s == 'Missing').length,
        'Outing': attendanceStatus.values.where((s) => s == 'Outing').length,
        'Home Pass': attendanceStatus.values
            .where((s) => s == 'Home Pass')
            .length,
        'Self Outing': attendanceStatus.values
            .where((s) => s == 'Self Outing')
            .length,
        'Self Home': attendanceStatus.values
            .where((s) => s == 'Self Home')
            .length,
      };

      Get.dialog(
        SuccessDialog(
          title: "Success",
          message: "Attendance has been submitted successfully!",
          total: total,
          present: present,
          extraStats: extraStats,
          onConfirm: () {
            // Close both dialog and add page to return to Summary List
            Get.close(2);

            // Refresh summary for the whole floor in background
            // Use the floor name (widget.floor) for the summary API
            hostelCtrl.loadRoomAttendanceSummary(
              branch: branchId,
              date: selectedDate,
              hostel: hostelId,
              floor: widget.floor ?? hostelCtrl.activeFloor.value,
              room: 'All',
            );
          },
        ),
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF16213e),

        // ---------------- APP BAR ----------------
        appBar: AppBar(
          backgroundColor: isDark
              ? Colors.black.withOpacity(0.4)
              : Colors.white.withOpacity(0.9),
          elevation: 0,
          title: Text(
            "Add Hostel Attendance",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        // ---------------- BODY ----------------
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [dark1, dark2, dark3, purpleDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFF5F6FA), Color(0xFFE8ECF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Filter Summary Cards
                _buildFilterSummary(isDark),

                // Get Students Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Obx(
                      () => ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.cyanAccent
                              : const Color(0xFF533483),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: hostelCtrl.isLoading.value
                            ? null
                            : const Icon(Icons.search),
                        label: Text(
                          hostelCtrl.isLoading.value
                              ? "Loading..."
                              : "Get Students",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: hostelCtrl.isLoading.value
                            ? null
                            : _getStudents,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Obx(() {
                    if (hostelCtrl.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SkeletonList(itemCount: 5),
                      );
                    }
                    if (hostelCtrl.roomStudents.isEmpty) {
                      return Center(
                        child: Text(
                          'Click "Get Students" to load student list',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    return _buildStudentTable(isDark);
                  }),
                ),

                // Submit Button
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
        ),
      ),
    );
  }

  Widget _buildFilterSummary(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip(isDark, 'Branch', widget.branch ?? 'Not Selected'),
              _filterChip(isDark, 'Hostel', widget.hostel ?? 'Not Selected'),
              _filterChip(isDark, 'Floor', widget.floor ?? 'Not Selected'),
              _filterChip(isDark, 'Room', widget.room ?? 'Not Selected'),
              _filterChip(isDark, 'Date', selectedDate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(bool isDark, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213e) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.cyanAccent : const Color(0xFF533483),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStudentTable(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16213e) : Colors.grey.shade200,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      'S No.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Attendance Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Admission No.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Student Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Phone Number',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Table Rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hostelCtrl.roomStudents.length,
              itemBuilder: (context, index) {
                final student = hostelCtrl.roomStudents[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: attendanceStatus[student.sid] ?? 'Present',
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: isDark ? dark2 : Colors.white,
                            style: TextStyle(
                              color: _getStatusColor(
                                attendanceStatus[student.sid] ?? 'Present',
                                isDark,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            items: statusOptions.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: _getStatusColor(status, isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                attendanceStatus[student.sid] = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          student.admno,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () {
                            // TODO: Navigate to student details
                          },
                          child: Text(
                            student.studentName,
                            style: const TextStyle(
                              color: Color(0xFFE040FB), // Vibrant pink/purple
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          student.phone ?? '',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPER METHODS ----------------

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'Present':
        return Colors.greenAccent;
      case 'Missing':
        return Colors.redAccent;
      case 'Outing':
        return Colors.orangeAccent;
      case 'Home Pass':
        return Colors.lightBlueAccent;
      case 'Self Outing':
        return Colors.cyanAccent;
      case 'Self Home':
        return Colors.pinkAccent;
      default:
        return isDark ? Colors.white : Colors.black;
    }
  }
}
