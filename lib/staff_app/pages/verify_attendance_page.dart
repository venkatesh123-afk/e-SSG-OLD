import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_app/staff_app/api/api_service.dart';
import 'package:student_app/staff_app/controllers/shift_controller.dart';
import 'package:student_app/staff_app/model/attendance_record_model.dart';
import '../controllers/branch_controller.dart';
import '../model/branch_model.dart';
import '../widgets/skeleton.dart';

class VerifyAttendancePage extends StatefulWidget {
  const VerifyAttendancePage({super.key});

  @override
  State<VerifyAttendancePage> createState() => _VerifyAttendancePageState();
}

class _VerifyAttendancePageState extends State<VerifyAttendancePage>
    with SingleTickerProviderStateMixin {
  String? selectedBranch;
  String? selectedShift;

  bool isLoading = false;
  bool isSubmitting = false;
  List<AttendanceRecord> attendanceData = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ================= CONTROLLERS =================
  final BranchController branchCtrl = Get.put(BranchController());
  final ShiftController shiftCtrl = Get.put(ShiftController());

  List<String> branches = [];

  // ================= DARK COLORS =================
  final Color darkBg1 = const Color(0xFF1a1a2e);
  final Color darkBg2 = const Color(0xFF16213e);
  final Color darkBg3 = const Color(0xFF0f3460);
  final Color darkBg4 = const Color(0xFF533483);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // LOAD BRANCHES
    branchCtrl.loadBranches();

    ever(branchCtrl.branches, (_) {
      branches = branchCtrl.branches
          .map<String>((BranchModel b) => b.branchName)
          .toList();

      // AUTO SELECT FIRST BRANCH + LOAD SHIFTS
      if (branches.isNotEmpty && selectedBranch == null) {
        selectedBranch = branches.first;

        final branch = branchCtrl.branches.first;
        shiftCtrl.loadShifts(branch.id);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ================= FETCH =================
  Future<void> _fetchAttendanceData() async {
    if (selectedBranch == null || selectedShift == null) {
      _showSnackBar('Please select Branch & Shift', Colors.orange);
      return;
    }

    try {
      setState(() {
        isLoading = true;
        attendanceData.clear();
      });

      // get selected branch id
      final branch = branchCtrl.branches.firstWhere(
        (b) => b.branchName == selectedBranch,
      );

      // get selected shift id
      final shift = shiftCtrl.shifts.firstWhere(
        (s) => s.shiftName == selectedShift,
      );

      // 🔥 API CALL (same as Postman)
      final result = await ApiService.getVerifyAttendance(
        branchId: branch.id,
        shiftId: shift.id,
      );

      setState(() {
        attendanceData = result
            .map((e) => AttendanceRecord.fromJson(e))
            .toList();
        isLoading = false;
      });

      _animationController.forward(from: 0);

      if (attendanceData.isEmpty) {
        _showSnackBar('No attendance found', Colors.orange);
      } else {
        _showSnackBar('Attendance Loaded', Colors.green);
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar(e.toString(), Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [darkBg1, darkBg2, darkBg3, darkBg4],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Verify Attendance",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFilterCard(isDark),
                const SizedBox(height: 20),
                _buildVerifyButton(isDark),
                const SizedBox(height: 25),
                if (isLoading) _buildLoadingState(),
                if (!isLoading && attendanceData.isEmpty)
                  _buildEmptyState(isDark),
                if (attendanceData.isNotEmpty) _buildAttendanceCards(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= FILTER CARD =================
  Widget _buildFilterCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white24 : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              isDark: isDark,
              label: 'Branch',
              icon: Icons.account_tree,
              iconColor: Colors.cyanAccent,
              value: selectedBranch,
              items: branches,
              onChanged: (v) {
                setState(() {
                  selectedBranch = v;
                  selectedShift = null;
                });

                final branch = branchCtrl.branches.firstWhere(
                  (b) => b.branchName == v,
                );

                shiftCtrl.loadShifts(branch.id);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => _buildDropdown(
                isDark: isDark,
                label: 'Shift',
                icon: Icons.access_time,
                iconColor: Colors.greenAccent,
                value: selectedShift,
                items: shiftCtrl.shifts.map((e) => e.shiftName).toList(),
                onChanged: (v) => setState(() => selectedShift = v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DROPDOWN =================
  Widget _buildDropdown({
    required bool isDark,
    required String label,
    required IconData icon,
    required Color iconColor,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white24 : Theme.of(context).dividerColor,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                "Select",
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              dropdownColor: isDark ? darkBg1 : Theme.of(context).cardColor,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 13,
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ================= BUTTON =================
  Widget _buildVerifyButton(bool isDark) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _fetchAttendanceData,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? const Color(0xFF1FFFE0)
              : Theme.of(context).primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? null
            : const Text(
                "VERIFY ATTENDANCE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  // ================= DATA =================
  Widget _buildAttendanceCards(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: attendanceData.map((record) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey.shade200,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.batch,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    _badge(
                      label: "Shift Wise",
                      color: isDark
                          ? const Color(0xFF1FFFE0)
                          : Theme.of(context).primaryColor,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                // 📊 STATS GRID
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  children: [
                    _statItem("TOTAL", record.total, Colors.blue, isDark),
                    _statItem("PRESENT", record.present, Colors.green, isDark),
                    _statItem("ABSENT", record.absent, Colors.red, isDark),
                    _statItem(
                      "OUTING",
                      record.totalOuting,
                      Colors.orange,
                      isDark,
                    ),
                    _statItem(
                      "HOME PASS",
                      record.totalHomePass,
                      Colors.purple,
                      isDark,
                    ),
                    _statItem(
                      "SELF OUTING",
                      record.totalSelfOuting,
                      Colors.teal,
                      isDark,
                    ),
                    _statItem(
                      "SELF HOME",
                      record.totalSelfHome,
                      Colors.indigo,
                      isDark,
                    ),
                    _statItem(
                      "MISSING",
                      record.totalMissing,
                      Colors.redAccent,
                      isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: isDark ? Colors.white10 : Colors.grey.shade100),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "TOTAL MARKED",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      record.totalMarked.toString(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _badge({
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statItem(String label, int value, Color color, bool isDark) {
    return SizedBox(
      width: 80, // Fixed width for consistent grid look in Wrap
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            color: isDark ? Colors.white54 : Colors.black38,
            size: 60,
          ),
          const SizedBox(height: 12),
          Text(
            "No Data Available",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: SkeletonList(itemCount: 3),
    );
  }
}
