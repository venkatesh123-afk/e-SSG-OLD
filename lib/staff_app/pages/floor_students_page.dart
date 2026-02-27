import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/floor_student_controller.dart';
import '../model/floor_student_model.dart';
import '../widgets/skeleton.dart';
import '../widgets/search_field.dart';

class FloorStudentsPage extends StatefulWidget {
  final int floorId;
  final String floorName;

  const FloorStudentsPage({
    super.key,
    required this.floorId,
    required this.floorName,
  });

  @override
  State<FloorStudentsPage> createState() => _FloorStudentsPageState();
}

class _FloorStudentsPageState extends State<FloorStudentsPage> {
  final FloorStudentController _controller = Get.put(FloorStudentController());
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.fetchStudentsByFloor(widget.floorId);
  }

  // ================= COLORS & TOKENS =================
  static const Color dark1 = Color(0xFF1a1a2e);
  static const Color dark2 = Color(0xFF16213e);
  static const Color dark3 = Color(0xFF0f3460);
  static const Color purpleDark = Color(0xFF533483);
  static const Color neon = Color(0xFF00FFF5);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${widget.floorName} Students",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [dark1, dark2, dark3, purpleDark]
                : const [Color(0xFFF5F6FA), Color(0xFFE8ECF4)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 95),

            // ================= SEARCH BAR =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white24
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: SearchField(
                  hint: 'Search by name / adm no / room',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),

            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SkeletonList(itemCount: 8),
                  );
                }

                final filteredStudents = _controller.students.where((s) {
                  if (_query.isEmpty) return true;
                  final q = _query.toLowerCase();
                  return s.fullName.toLowerCase().contains(q) ||
                      s.admno.toLowerCase().contains(q) ||
                      s.roomname.toLowerCase().contains(q);
                }).toList();

                if (filteredStudents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 80,
                          color: isDark
                              ? Colors.white24
                              : Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty
                              ? "No students found on this floor"
                              : "No results for '$_query'",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    return _buildStudentCard(student, isDark);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(FloorStudentModel student, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [dark3.withOpacity(0.45), purpleDark.withOpacity(0.45)],
              )
            : const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF0F2F5)],
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? neon.withOpacity(0.35) : Colors.transparent,
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? neon.withOpacity(0.15) : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? neon.withOpacity(0.1)
                  : const Color(0xFF7C79E0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                student.sfname.isNotEmpty ? student.sfname[0] : "?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? neon : const Color(0xFF7C79E0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Adm No: ${student.admno}",
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.meeting_room_outlined,
                      size: 14,
                      color: isDark ? neon : const Color(0xFF7C79E0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Room: ${student.roomname}",
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? neon.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "ID: ${student.studentId}",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? neon : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
