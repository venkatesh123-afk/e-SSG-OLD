import 'package:get/get.dart';
import 'package:student_app/staff_app/controllers/student_controller.dart';
import 'package:student_app/staff_app/controllers/outing_controller.dart';
import 'package:student_app/staff_app/controllers/branch_controller.dart';

import 'package:student_app/staff_app/model/student_model.dart';
import 'package:student_app/staff_app/api/api_service.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:student_app/staff_app/widgets/skeleton.dart';
import 'outing_pending_listPage.dart';
import 'package:student_app/staff_app/controllers/outing_pending_controller.dart';

class IssueOutingPage extends StatefulWidget {
  final String studentName;
  final String outingType;

  const IssueOutingPage({
    super.key,
    required this.studentName,
    required this.outingType,
  });

  @override
  State<IssueOutingPage> createState() => _IssueOutingPageState();
}

class _IssueOutingPageState extends State<IssueOutingPage> {
  String passType = "";

  static const Color dark1 = Color(0xFF1a1a2e);
  static const Color dark2 = Color(0xFF16213e);
  static const Color dark3 = Color(0xFF0f3460);
  static const Color purpleDark = Color(0xFF533483);

  // ---------------- DROPDOWN ----------------
  String selectedPurpose = "Personal"; // Default value

  // ---------------- DATE & TIME ----------------
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final StudentController studentCtrl = Get.put(StudentController());
  final BranchController branchCtrl = Get.put(BranchController());
  final OutingController outingCtrl = Get.put(OutingController());

  // ---------------- SEARCH ----------------
  final TextEditingController _admNoController = TextEditingController();
  StudentModel? _selectedStudent;
  bool _showSuggestions = false;

  // ---------------- IMAGE PICKER ----------------
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  String? _letterPhotoUrl;
  bool _isUploadingPhoto = false;
  bool _ignoreNextAdmNoChange = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _admNoController.dispose();
    super.dispose();
  }

  // ---------------- STUDENT OUTING LIST ----------------
  final List<Map<String, String>> studentOutingList = [
    {
      "studentName": "John Doe",
      "passType": "Outing Pass",
      "outingDate": "18-02-2026",
      "outingTime": "12:33 PM",
      "purpose": "Personal",
      "permissionBy": "Mr. Smith",
    },
    {
      "studentName": "Jane Smith",
      "passType": "Home Pass",
      "outingDate": "18-02-2026",
      "outingTime": "10:00 AM",
      "purpose": "Health Problem",
      "permissionBy": "Mrs. Johnson",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final headingStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Issue Outing",
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
        actions: const [],
      ),

      // ---------------- BODY ----------------
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [dark1, dark2, dark3, purpleDark],
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [_buildFormCard(isDark, headingStyle)]),
          ),
        ),
      ),
    );
  }

  // ---------------- HISTORY DIALOG ----------------
  void _showHistoryDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 40,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1e1e2e) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF439A94), Color(0xFF3366E8)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Student Outing List",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Obx(() {
                    if (outingCtrl.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: SkeletonList(itemCount: 5)),
                      );
                    }

                    final filtered = outingCtrl.selectedStudentOutings;

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          "No outing history",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        final o = filtered[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF242F48)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.shade300,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Tag & Date Row ---
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (o.outingType.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTagColor(
                                          o.outingType,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        o.outingType,
                                        style: TextStyle(
                                          color: _getTagColor(o.outingType),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (o.outDate.isNotEmpty ||
                                      o.outingTime.isNotEmpty)
                                    Text(
                                      "${o.outDate}${o.outDate.isNotEmpty && o.outingTime.isNotEmpty ? " | " : ""}${o.outingTime}",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // --- Student Name ---
                              Text(
                                o.studentName.toUpperCase(),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // --- Purpose ---
                              if (o.purpose.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Purpose: ${o.purpose}",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // --- Approved By ---
                              if (o.permission.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Approved By: ${o.permission}",
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- FORM CARD ----------------
  Widget _buildFormCard(bool isDark, TextStyle headingStyle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.10)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white30 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3366E8), Color(0xFF3366E8)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              "Issue New Outing",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text("Date *", style: headingStyle),
          const SizedBox(height: 6),
          _neonDatePicker(
            context,
            label: "Select Date",
            icon: Icons.event,
            iconColor: Colors.lightBlueAccent,
            value: _selectedDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          Text("Pass Type *", style: headingStyle),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            children: [
              _radio("Home Pass", isDark),
              _radio("Outing Pass", isDark),
              _radio("Self Outing", isDark),
              _radio("Self Home", isDark),
            ],
          ),

          const SizedBox(height: 14),

          Text("Select Student *", style: headingStyle),
          const SizedBox(height: 6),
          _inputField(
            _admNoController,
            "Enter Admission Number",
            isDark,
            onChanged: _onAdmNoChanged,
          ),
          _buildSuggestions(isDark),
          _buildRedFlagInfo(),

          const SizedBox(height: 14),

          Text("Letter Photo *", style: headingStyle),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isUploadingPhoto
                  ? null
                  : () => _showPhotoDialog(context),
              child: _isUploadingPhoto
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text("Take Photo"),
            ),
          ),

          if (_capturedImage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _capturedImage!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isUploadingPhoto ? "Uploading..." : "Photo Captured",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        if (_letterPhotoUrl != null)
                          const Text(
                            "Upload Successful",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _capturedImage = null;
                        _letterPhotoUrl = null;
                        _isUploadingPhoto = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          Text("Out Time *", style: headingStyle),
          const SizedBox(height: 6),
          _neonTimePicker(
            context,
            label: "Out Time",
            icon: Icons.access_time,
            iconColor: Colors.lightBlueAccent,
            value: _selectedTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: false),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _selectedTime = picked);
            },
            isDark: isDark,
          ),

          const SizedBox(height: 14),

          Text("Purpose *", style: headingStyle),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
            ),
            child: DropdownButton<String>(
              value: selectedPurpose,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDark ? Colors.white : Colors.black,
              ),
              items: ["Personal", "Health Problem", "Functions", "Temple Visit"]
                  .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    );
                  })
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPurpose = newValue!;
                });
              },
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: GestureDetector(
              onTap: () async {
                final admNo = _admNoController.text.trim();

                if (_selectedStudent == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a student")),
                  );
                  return;
                }

                if (passType.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select pass type")),
                  );
                  return;
                }

                if (_letterPhotoUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please upload the letter photo first"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                try {
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final outDate =
                      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

                  // Format time as HH:MM AM/PM (12-hour) - matches Postman
                  final hour = _selectedTime.hourOfPeriod == 0
                      ? 12
                      : _selectedTime.hourOfPeriod;
                  final period = _selectedTime.period == DayPeriod.am
                      ? "AM"
                      : "PM";
                  final outTime =
                      "${hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} $period";

                  await ApiService.storeOuting(
                    sid: _selectedStudent!.sid,
                    admNo: _selectedStudent!.admNo,
                    studentName:
                        "${_selectedStudent!.sFirstName} ${_selectedStudent!.sLastName}",
                    outDate: outDate,
                    outTime: outTime,
                    outingType: passType,
                    purpose: selectedPurpose,
                    letterPhoto: _letterPhotoUrl!,
                  );

                  // Pop loading dialog
                  if (mounted) Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Outing granted for $admNo"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  // Refresh pending list
                  if (Get.isRegistered<OutingPendingController>()) {
                    Get.find<OutingPendingController>().fetchOutings();
                  }

                  // Clear inputs
                  _admNoController.clear();
                  setState(() {
                    _selectedStudent = null;
                    _letterPhotoUrl = null;
                    _capturedImage = null;
                  });
                  outingCtrl.selectedStudentOutings.clear();

                  // Navigate to pending list
                  Get.to(() => const OutingPendingListPage());
                } catch (e) {
                  // Pop loading dialog
                  if (mounted) Navigator.pop(context);

                  if (mounted) {
                    String msg = e.toString();
                    if (msg.contains("Already one outing")) {
                      msg =
                          "Already one outing is Pending or Approved for this student";
                    } else if (msg.contains("SQLSTATE") ||
                        msg.contains("500")) {
                      msg =
                          "Server Side Error: Some fields are missing or invalid.";
                    } else if (msg.startsWith("Exception: ")) {
                      msg = msg.replaceFirst("Exception: ", "");
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Container(
                height: 44,
                width: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5966FF), Color(0xFF6D9BFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Grant Outing',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PHOTO DIALOG ----------------
  void _showPhotoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 40,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1e1e2e) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Header ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                  child: Row(
                    children: [
                      Text(
                        'Capture Student Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF2d2d2d),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  thickness: 1,
                  height: 1,
                ),

                // ---- Camera Preview Area ----
                Container(
                  width: double.infinity,
                  height: 280,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: _capturedImage != null
                      ? GestureDetector(
                          onTap: () async {
                            Navigator.of(ctx).pop();
                            await _captureFromCamera();
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _capturedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 56,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Camera Preview',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // ---- Action Buttons ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3CB371),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _captureFromCamera();
                        },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text(
                          'Capture Photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B7FD4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _pickFromGallery();
                        },
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text(
                          'Upload Photo',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- CAPTURE FROM CAMERA ----------------
  Future<void> _captureFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image != null) {
      final file = File(image.path);
      setState(() {
        _capturedImage = file;
        _isUploadingPhoto = true;
      });

      try {
        final url = await ApiService.uploadOutingLetter(
          file,
          admNo: _admNoController.text.trim(),
        );
        setState(() {
          _letterPhotoUrl = url;
          _isUploadingPhoto = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photo uploaded successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isUploadingPhoto = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload failed: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ---------------- PICK FROM GALLERY ----------------
  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      final file = File(image.path);
      setState(() {
        _capturedImage = file;
        _isUploadingPhoto = true;
      });

      try {
        final url = await ApiService.uploadOutingLetter(
          file,
          admNo: _admNoController.text.trim(),
        );
        setState(() {
          _letterPhotoUrl = url;
          _isUploadingPhoto = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photo uploaded successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isUploadingPhoto = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload failed: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ---------------- SELECTION LOGIC ----------------

  void _onAdmNoChanged(String value) {
    if (_ignoreNextAdmNoChange) {
      _ignoreNextAdmNoChange = false;
      return;
    }

    if (value.isNotEmpty) {
      studentCtrl.searchStudent(value);
      setState(() {
        _showSuggestions = true;
      });
    } else {
      setState(() {
        _showSuggestions = false;
        _selectedStudent = null;
      });
      outingCtrl.selectedStudentOutings.clear();
    }
  }

  void _selectStudent(StudentModel student) {
    setState(() {
      _selectedStudent = student;
      _ignoreNextAdmNoChange = true;
      _admNoController.text = student.admNo;
      _showSuggestions = false;
    });

    // Fetch outings (don't await, let Obx handle loading state in dialog)
    outingCtrl.fetchStudentOutings(student.admNo, sid: student.sid.toString());

    if (student.isFlagged) {
      _showRedFlagWarning(context, () {
        if (mounted) {
          _showHistoryDialog(context);
        }
      });
    } else {
      // Show the history dialog INSTANTLY
      if (mounted) {
        _showHistoryDialog(context);
      }
    }
  }

  void _showRedFlagWarning(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD1A7), width: 3),
              ),
              child: const Icon(
                Icons.priority_high,
                color: Color(0xFFFFCC33),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Warning",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A4A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedStudent?.flagRemarks != null &&
                      _selectedStudent!.flagRemarks.isNotEmpty
                  ? _selectedStudent!.flagRemarks
                  : "Caution: This student has a red flag. Kindly verify before issuing an outing.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF5E6A81),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6666),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onConfirm();
                },
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    if (!_showSuggestions) return const SizedBox.shrink();

    return Obx(() {
      if (studentCtrl.isLoading.value) {
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const SkeletonList(itemCount: 3),
        );
      }

      if (studentCtrl.students.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(top: 4),
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: studentCtrl.students.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
          itemBuilder: (context, index) {
            final s = studentCtrl.students[index];
            return InkWell(
              onTap: () => _selectStudent(s),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${s.admNo}/${s.sFirstName} ${s.sLastName}",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${s.fatherName} | ${s.courseName} | ${s.groupName}",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildRedFlagInfo() {
    if (_selectedStudent == null) return const SizedBox.shrink();

    return Obx(() {
      final history = outingCtrl.selectedStudentOutings;
      final homePassCount = history
          .where((o) => o.outingType == 'Home Pass')
          .length;
      final outingPassCount = history
          .where((o) => o.outingType == 'Outing Pass')
          .length;
      final selfOutingCount = history
          .where((o) => o.outingType == 'Self Outing')
          .length;
      final selfHomeCount = history
          .where((o) => o.outingType == 'Self Home')
          .length;

      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          "Outings: ${history.length} | HP: $homePassCount, OP: $outingPassCount, SO: $selfOutingCount, SH: $selfHomeCount",
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    });
  }

  // ---------------- RADIO ----------------

  Widget _radio(String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: text,
          groupValue: passType,
          activeColor: isDark ? Colors.white : Colors.blue,
          onChanged: (v) => setState(() => passType = v!),
        ),
        Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------- INPUT FIELD ----------------
  Widget _inputField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    void Function(String)? onChanged,
  }) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.grey.shade500,
            fontSize: 15,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ---------------- NEON DATE PICKER ----------------
  Widget _neonDatePicker(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required DateTime value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final formatted =
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatted,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- NEON TIME PICKER ----------------
  Color _getTagColor(String type) {
    if (type.contains("Home")) return Colors.blue;
    if (type.contains("Outing")) return const Color(0xFF3498DB);
    return Colors.teal;
  }

  Widget _neonTimePicker(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color iconColor,
    required TimeOfDay value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final formatted = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(value, alwaysUse24HourFormat: false);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                formatted,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white : Colors.black,
            ),
          ],
        ),
      ),
    );
  }
}
