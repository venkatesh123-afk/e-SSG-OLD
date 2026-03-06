import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_app/staff_app/controllers/auth_controller.dart';
import 'package:student_app/staff_app/controllers/theme_controller.dart';
import 'package:student_app/staff_app/controllers/search_controller.dart'
    as search;
import 'package:student_app/staff_app/controllers/profile_controller.dart';
import 'package:student_app/staff_app/pages/profile_page.dart';
import 'package:student_app/staff_app/pages/student_details_page.dart';
import 'package:student_app/staff_app/widgets/skeleton.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  bool showSearch = false;
  bool isGridMenuOpen = false;
  bool showSearchDropdown = false;
  String selectedYear = "2025-2026";
  final searchCtrl = Get.put(search.SearchController());
  final profileCtrl = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());
  final TextEditingController searchTextCtrl = TextEditingController();

  final List<String> years = [
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
  ];

  final List<Map<String, dynamic>> colleges = const [
    {"name": "Pelluru", "present": 75, "absent": 25},
    {"name": "VRB", "present": 65, "absent": 35},
    {"name": "PVB", "present": 75, "absent": 25},
    {"name": "Vidya Bhavan", "present": 75, "absent": 25},
    {"name": "Padmavathi", "present": 65, "absent": 35},
    {"name": "MM Road", "present": 75, "absent": 25},
    {"name": "AVP", "present": 65, "absent": 35},
    {"name": "Tallur", "present": 75, "absent": 25},
  ];
  final themeCtrl = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                  Color(0xFF533483),
                ]
              : const [Color(0xFFF5F6FA), Color(0xFFE8ECF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: _buildDrawer(),
        appBar: _buildAppBar(context),
        body: Stack(
          children: [
            _buildDashboardBody(),
            if (showSearchDropdown) _buildSearchDropdown(context),
          ],
        ),
      ),
    );
  }

  // ================= APP BAR =================

  AppBar _buildAppBar(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 64, // ✅ better height
      automaticallyImplyLeading: false,
      titleSpacing: 12, // ✅ spacing from left

      title: Row(
        children: [
          // LOGO
          const CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage("assets/icon/SSG.jpeg"),
          ),

          const SizedBox(width: 10),

          // MENU
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: iconColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),

          const SizedBox(width: 6),

          // GRID
          IconButton(
            icon: Icon(Icons.grid_view_rounded, color: iconColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: toggleGridMenu,
          ),

          const SizedBox(width: 8),

          // YEAR POPUP MENU
          PopupMenuButton<String>(
            initialValue: selectedYear,
            onSelected: (v) => setState(() => selectedYear = v),
            itemBuilder: (context) => years
                .map(
                  (y) => PopupMenuItem(
                    value: y,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          y,
                          style: TextStyle(
                            fontWeight: y == selectedYear
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: y == selectedYear
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        if (y == selectedYear)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: iconColor, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),

      actions: [
        // 🔍 SEARCH ICON
        IconButton(
          tooltip: "Search Student",
          icon: Icon(Icons.search, color: iconColor),
          onPressed: () {
            setState(() {
              showSearchDropdown = !showSearchDropdown;
              if (!showSearchDropdown) {
                searchCtrl.clearSearch();
                searchTextCtrl.clear();
              }
            });
          },
        ),
        // 🌙 THEME TOGGLE
        Obx(
          () => IconButton(
            tooltip: themeCtrl.isDark.value ? "Light Mode" : "Dark Mode",
            icon: Icon(
              themeCtrl.isDark.value
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: iconColor,
            ),
            onPressed: themeCtrl.toggleTheme,
          ),
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          onSelected: (v) async {
            switch (v) {
              case 'profile':
                // 👉 Open Profile Page
                Get.to(() => const ProfilePage());
                break;
              case 'logout':
                Get.find<AuthController>().logout();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'profile', child: Text("Profile")),
            PopupMenuItem(value: 'logout', child: Text("Logout")),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Obx(() {
              final p = profileCtrl.profile.value;
              final avatar = p?.avatar ?? "";
              final bool hasValidAvatar =
                  avatar.isNotEmpty && avatar != "avatar.png";

              return CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).cardColor,
                backgroundImage: hasValidAvatar
                    ? NetworkImage(
                        "https://dev.srisaraswathigroups.in/uploads/$avatar",
                      )
                    : null,
                child: !hasValidAvatar ? const Icon(Icons.person) : null,
              );
            }),
          ),
        ),
      ],
    );
  }

  // Dashboard Body

  Widget _buildDashboardBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            smallCard("Total Students", "6902", [
              Color(0xFF4ade80),
              Color(0xFF22c55e),
            ], Icons.people_outline),

            const SizedBox(height: 12),

            smallCard("Day", "2047", [
              Color(0xFF818cf8),
              Color(0xFF6366f1),
            ], Icons.directions_bus_outlined),

            const SizedBox(height: 12),

            smallCard("Hostel", "4854", [
              Color(0xFFfbbf24),
              Color(0xFFf59e0b),
            ], Icons.apartment_outlined),

            const SizedBox(height: 12),

            smallCard("Today's Outing", "14", [
              Color(0xFF51dbe2),
              Color(0xFF1cdbE5),
            ], Icons.person_outline),

            const SizedBox(height: 12),

            smallCard("Today Present", "4130", [
              Color(0xFF4ade80),
              Color(0xFF22c55e),
            ], Icons.people_outline),

            const SizedBox(height: 12),

            smallCard("Today Absent", "772", [
              Color(0xFFf87171),
              Color(0xFFef4444),
            ], Icons.person_off_outlined),

            const SizedBox(height: 25),

            Text(
              "Student Attendance",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // Attendance container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                    Color(0xFF533483),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var c in colleges)
                    AttendanceItem(
                      title: c["name"],
                      present: c["present"],
                      absent: c["absent"],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget smallCard(
    String title,
    String value,
    List<Color> colors,
    IconData icon,
  ) {
    return Container(
      height: 85,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(icon, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  // ================= SEARCH DROPDOWN =================

  Widget _buildSearchDropdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          setState(() {
            showSearchDropdown = false;
            searchCtrl.clearSearch();
            searchTextCtrl.clear();
          });
        },
        child: Container(
          color: Colors.black54,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping inside
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1a1a2e), Color(0xFF16213e)]
                      : const [Color(0xFFFFFFFF), Color(0xFFF5F6FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Input Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchTextCtrl,
                          decoration: InputDecoration(
                            hintText: 'Enter Admission ID',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              searchCtrl.searchStudent(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (searchTextCtrl.text.isNotEmpty) {
                            searchCtrl.searchStudent(searchTextCtrl.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.search, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Loading Indicator
                  Obx(() {
                    if (searchCtrl.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: SkeletonList(itemCount: 3),
                      );
                    }

                    // Error Message
                    if (searchCtrl.errorMessage.value.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          searchCtrl.errorMessage.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // Search Results
                    if (searchCtrl.searchResults.isNotEmpty) {
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchCtrl.searchResults.length,
                          itemBuilder: (context, index) {
                            final student = searchCtrl.searchResults[index];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  showSearchDropdown = false;
                                });
                                Get.to(
                                  () => StudentDetailsPage(student: student),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366f1),
                                      Color(0xFF818cf8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${student.admNo}/${student.sFirstName} ${student.sLastName}/${student.fatherName}/${student.branchName}/${student.groupName}/${student.batch}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                student.status.toLowerCase() ==
                                                    'active'
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            student.status.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //  GRID MENU

  void toggleGridMenu() {
    if (isGridMenuOpen) {
      Navigator.of(context).pop();
      if (mounted) setState(() => isGridMenuOpen = false);
    } else {
      openGridMenu();
    }
  }

  void _closeGridMenu() {
    if (isGridMenuOpen) {
      Navigator.of(context).pop();
      if (mounted) setState(() => isGridMenuOpen = false);
    }
  }

  void openGridMenu() {
    setState(() => isGridMenuOpen = true);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black38,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(top: kToolbarHeight + 10),
              height: MediaQuery.of(context).size.height * 0.85,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 28,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: _closeGridMenu,
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _menuCard(
                          color: const Color(0xFF2196F3),
                          icon: Icons.groups_rounded,
                          title: "Class Attendance",
                          onTap: () {
                            _closeGridMenu();
                            Get.toNamed('/classAttendance');
                          },
                        ),
                        _menuCard(
                          color: const Color(0xFFFFC107),
                          icon: Icons.fact_check_rounded,
                          title: "Hostel Attendance",
                          onTap: () {
                            _closeGridMenu();
                            Get.toNamed('/hostelAttendanceFilter');
                          },
                        ),
                        _menuCard(
                          color: const Color(0xFF4CAF50),
                          icon: Icons.hiking,
                          title: "Issue Outing",
                          onTap: () {
                            _closeGridMenu();
                            Get.toNamed('/outingList');
                          },
                        ),
                        _menuCard(
                          color: const Color(0xFFE53935),
                          icon: Icons.verified_user_rounded,
                          title: "Verify Outing",
                          onTap: () {
                            _closeGridMenu();
                            Get.toNamed('/outingPending');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        );
      },
    ).then((_) {
      if (mounted) setState(() => isGridMenuOpen = false);
    });
  }

  //  MENU CARD

  static Widget _menuCard({
    required Color color,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 45),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  DRAWER

  Widget _buildDrawer() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: Theme.of(context).brightness == Brightness.dark
                    ? const LinearGradient(
                        colors: [Color(0xFF0f3460), Color(0xFF533483)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFFE8ECF4), Color(0xFFF5F6FA)],
                      ),
              ),
              child: Obx(() {
                final p = profileCtrl.profile.value;
                final isLoading = profileCtrl.isLoading.value;

                // Only show spinner if we have NO data AND it's currently loading
                if (p == null && isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white70),
                        SizedBox(height: 10),
                        Text(
                          "Loading profile...",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                // If no data and not loading (fetch failed with no cache)
                if (p == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white70),
                        const SizedBox(height: 8),
                        const Text(
                          "Profile load failed",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: profileCtrl.fetchProfile,
                          child: const Text(
                            "Retry",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final avatar = p.avatar;
                final bool hasValidAvatar =
                    avatar.isNotEmpty && avatar != "avatar.png";

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Theme.of(context).cardColor,
                          backgroundImage: hasValidAvatar
                              ? NetworkImage(
                                  "https://dev.srisaraswathigroups.in/uploads/$avatar",
                                )
                              : null,
                          child: !hasValidAvatar
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.name.isEmpty ? "User" : p.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      p.email.isEmpty ? "No email provided" : p.email,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),

            _drawerItem(
              icon: Icons.dashboard_customize_outlined,
              title: "Pro Dashboard",
              iconColor: Colors.deepPurpleAccent,
              onTap: () {
                Get.back(); // Close drawer
                Get.toNamed('/proDashboard');
              },
            ),

            _drawerItem(
              icon: Icons.chat_bubble_outline,
              title: "Chat",
              iconColor: Colors.cyanAccent,
              onTap: () {},
            ),

            _drawerExpandable(
              icon: Icons.calendar_today,
              iconColor: Colors.blueAccent,
              title: "Attendance",
              children: [
                _drawerSubItem(
                  "Student Attendance",
                  () => Get.toNamed('/studentAttendance'),
                ),
                _drawerSubItem(
                  "Verify Attendance",
                  () => Get.toNamed('/verifyAttendance'),
                ),
                _drawerSubItem(
                  "Hostel Attendance",
                  () => Get.toNamed('/hostelAttendanceFilter'),
                ),
                _drawerSubItem("Outings", () => Get.toNamed('/outingList')),
                _drawerSubItem(
                  "Outings Pending",
                  () => Get.toNamed('/outingPending'),
                ),
              ],
            ),

            _drawerExpandable(
              icon: Icons.assignment_outlined,
              iconColor: Colors.greenAccent,
              title: "Exams",
              children: [
                _drawerSubItem(
                  "Exam Category List",
                  () => Get.toNamed('/examCategoryList'),
                ),
                _drawerSubItem("Exams List", () => Get.toNamed('/examsList')),
                _drawerSubItem(
                  "Student Marks Upload",
                  () => Get.toNamed('/marksUpload'),
                ),
              ],
            ),
            // ================= FEES (NEW) =================
            _drawerExpandable(
              icon: Icons.currency_rupee,
              iconColor: Colors.amberAccent,
              title: "Fees",
              children: [
                _drawerSubItem("Fee Heads", () => Get.toNamed('/feeHeads')),
                // _drawerSubItem(
                //   "Student Fee Assignment",
                //   () => Get.toNamed('/studentFeeAssign'),
                // ),
                // _drawerSubItem(
                //   "Fee Collection",
                //   () => Get.toNamed('/feeCollection'),
                // ),
                // _drawerSubItem("Fee Receipt", () => Get.toNamed('/feeReceipt')),
                // _drawerSubItem(
                //   "Pending Fees",
                //   () => Get.toNamed('/pendingFees'),
                // ),
                // _drawerSubItem("Fee Reports", () => Get.toNamed('/feeReports')),
              ],
            ),

            _drawerExpandable(
              icon: Icons.apartment,
              iconColor: Colors.orangeAccent,
              title: "Hostel",
              children: [
                _drawerSubItem("Hostel List", () => Get.toNamed('/hostelList')),
                _drawerSubItem("Rooms", () => Get.toNamed('/rooms')),
                _drawerSubItem("Floors", () => Get.toNamed('/floors')),
                _drawerSubItem("Members", () => Get.toNamed('/hostelMembers')),

                _drawerSubItem("Add Hostel", () => Get.toNamed('/addHostel')),
                _drawerSubItem(
                  "Non-Hostel Students",
                  () => Get.toNamed('/nonHostel'),
                ),
              ],
            ),

            _drawerExpandable(
              icon: Icons.groups_2_outlined,
              iconColor: Colors.pinkAccent,
              title: "HR Management",
              children: [
                _drawerSubItem("Staff", () => Get.toNamed('/staff')),
                _drawerSubItem(
                  "Staff Attendance",
                  () => Get.toNamed('/staffAttendance'),
                ),
              ],
            ),

            _drawerItem(
              icon: Icons.message_outlined,
              title: "Communication",
              iconColor: Colors.tealAccent,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      onTap: onTap,
    );
  }

  Widget _drawerExpandable({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      collapsedIconColor: Theme.of(context).iconTheme.color,
      iconColor: Theme.of(context).iconTheme.color,
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      children: children,
    );
  }

  Widget _drawerSubItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      onTap: onTap,
    );
  }
}

// ATTENDANCE

class AttendanceItem extends StatelessWidget {
  final String title;
  final int present;
  final int absent;

  const AttendanceItem({
    super.key,
    required this.title,
    required this.present,
    required this.absent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.grey.shade300,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: present,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7A80FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        bottomLeft: Radius.circular(50),
                      ),
                    ),
                    child: Text(
                      "$present%",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  flex: absent,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7A7A),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                    child: Text(
                      "$absent%",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
