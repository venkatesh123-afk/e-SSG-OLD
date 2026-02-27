import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/hostel_controller.dart';
import '../controllers/branch_controller.dart';
import '../controllers/staff_controller.dart';
import '../controllers/floor_controller.dart';
import '../model/floor_model.dart';
import '../widgets/search_field.dart';
import '../widgets/skeleton.dart';
import 'floor_students_page.dart';

class FloorsManagementPage extends StatefulWidget {
  const FloorsManagementPage({super.key});

  @override
  State<FloorsManagementPage> createState() => _FloorsManagementPageState();
}

class _FloorsManagementPageState extends State<FloorsManagementPage> {
  final FloorController _floorController = Get.put(FloorController());
  final HostelController _hostelController = Get.put(HostelController());
  final BranchController _branchController = Get.put(BranchController());
  final StaffController _staffController = Get.put(StaffController());

  String _query = '';

  // Dialog Selection State
  final RxnInt _selectedBranchId = RxnInt();
  final RxnInt _selectedHostelId = RxnInt();
  final RxnInt _selectedStaffId = RxnInt();
  final RxnString _selectedStatus = RxnString("Active");

  @override
  void initState() {
    super.initState();
    _branchController.loadBranches();
    _staffController.fetchStaff();

    // Optionally load some initial data if needed
    // _floorController.fetchFloorsByIncharge(...)
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
          "Floors Management",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
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

            // ================= SEARCH & ACTION =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Branch & Hostel Selection
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _buildMiniDropdown(
                            hint: "Select Branch",
                            value: _branchController.branches
                                .firstWhereOrNull(
                                  (b) => b.id == _selectedBranchId.value,
                                )
                                ?.branchName,
                            items: _branchController.branches
                                .map((b) => b.branchName)
                                .toList(),
                            isDark: isDark,
                            onChanged: (val) {
                              final b = _branchController.branches
                                  .firstWhereOrNull((b) => b.branchName == val);
                              _selectedBranchId.value = b?.id;
                              _selectedHostelId.value = null;
                              if (b != null) {
                                _hostelController.loadHostelsByBranch(b.id);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(
                          () => _buildMiniDropdown(
                            hint: "Select Hostel",
                            value: _hostelController.hostels
                                .firstWhereOrNull(
                                  (h) => h.id == _selectedHostelId.value,
                                )
                                ?.buildingName,
                            items: _hostelController.hostels
                                .map((h) => h.buildingName)
                                .toList(),
                            isDark: isDark,
                            onChanged: (val) {
                              final h = _hostelController.hostels
                                  .firstWhereOrNull(
                                    (h) => h.buildingName == val,
                                  );
                              _selectedHostelId.value = h?.id;
                              if (h != null) {
                                _floorController.fetchFloorsByHostel(h.id);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
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
                      hint: 'Search floor / hostel / branch',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    label: "Add New Floor",
                    icon: Icons.add,
                    color: const Color(0xFF27ae60), // Emerald Green
                    onTap: () => _showAddDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= FLOOR LIST =================
            Expanded(
              child: Obx(() {
                if (_floorController.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SkeletonList(itemCount: 5),
                  );
                }

                final floorList = _floorController.floors.where((f) {
                  if (_query.isEmpty) return true;
                  return f.floorName.toLowerCase().contains(
                    _query.toLowerCase(),
                  );
                }).toList();

                if (floorList.isEmpty) {
                  return Center(
                    child: Text(
                      "No floors found",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: floorList.length,
                  itemBuilder: (context, i) {
                    final floor = floorList[i];
                    return _buildFloorCard(floor, isDark);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ================= COMPONENTS =================

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorCard(FloorModel floor, bool isDark) {
    final floorName = floor.floorName;
    // In a real scenario, building/branch details might need to be resolved correctly from IDs
    // For now, using placeholders or parsing if available in the model
    final hostelName = "Building ID: ${floor.building}";
    final branchName = "Branch ID: ${floor.branchId}";
    final category = floor.status == 1 ? "Active" : "Inactive";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      floorName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? neon.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? neon : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Hostel: $hostelName",
                  style: TextStyle(
                    color: isDark ? const Color(0xFFB5C7E8) : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Branch: $branchName",
                  style: TextStyle(
                    color: isDark ? const Color(0xFFB5C7E8) : Colors.black54,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit, color: Colors.orange, size: 22),
                onPressed: () => _showEditDialog(context, floor),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 22,
                ),
                onPressed: () => _showDeleteDialog(context, floor),
              ),
              const SizedBox(height: 12),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.people_outline,
                  color: Color(0xFF00FFCC),
                  size: 24,
                ),
                onPressed: () {
                  Get.to(
                    () => FloorStudentsPage(
                      floorId: floor.id,
                      floorName: floor.floorName,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= DIALOGS =================

  void _showAddDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final floorNameController = TextEditingController();

    _selectedBranchId.value = null;
    _selectedHostelId.value = null;
    _selectedStaffId.value = null;
    _selectedStatus.value = "Active";

    showDialog(
      context: context,
      builder: (context) => _buildDialogBase(
        context: context,
        title: "Add Floor",
        buttonLabel: "Add Floor",
        onConfirm: () => Navigator.pop(context),
        content: [
          _buildLabel("Floor Name *", isDark),
          _buildTextField(
            "Floor Name/Number",
            isDark,
            controller: floorNameController,
          ),
          const SizedBox(height: 16),
          _buildLabel("Branch *", isDark),
          Obx(
            () => _buildDropdown(
              [
                "Select Branch",
                ..._branchController.branches.map((b) => b.branchName),
              ],
              isDark,
              value:
                  _branchController.branches
                      .firstWhereOrNull((b) => b.id == _selectedBranchId.value)
                      ?.branchName ??
                  "Select Branch",
              onChanged: (val) {
                final b = _branchController.branches.firstWhereOrNull(
                  (b) => b.branchName == val,
                );
                _selectedBranchId.value = b?.id;
                if (b != null) _hostelController.loadHostelsByBranch(b.id);
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel("Building *", isDark),
          Obx(
            () => _buildDropdown(
              [
                "Select",
                ..._hostelController.hostels.map((h) => h.buildingName),
              ],
              isDark,
              value:
                  _hostelController.hostels
                      .firstWhereOrNull((h) => h.id == _selectedHostelId.value)
                      ?.buildingName ??
                  "Select",
              onChanged: (val) {
                final h = _hostelController.hostels.firstWhereOrNull(
                  (h) => h.buildingName == val,
                );
                _selectedHostelId.value = h?.id;
                if (h != null) {
                  _floorController.fetchFloorIncharges(h.id);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildLabel("Incharge *", isDark),
          Obx(() {
            if (_floorController.isLoading.value) {
              return const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            // If we have incharges, maybe show a dropdown or just use the text field
            // To match the screenshot exactly, it's a text field.
            // But if we have an API, we should probably use it.
            // Let's use a searchable dropdown or just list them.
            return _buildTextField(
              _floorController.floorIncharges.isEmpty
                  ? "Enter incharge name"
                  : "Search/Select Incharge",
              isDark,
            );
          }),
          const SizedBox(height: 16),
          _buildLabel("Status", isDark),
          Obx(
            () => _buildDropdown(
              ["Select", "Active", "Inactive"],
              isDark,
              value: _selectedStatus.value ?? "Select",
              onChanged: (val) => _selectedStatus.value = val,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, FloorModel floor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final floorNameController = TextEditingController(text: floor.floorName);

    _selectedStatus.value = floor.status == 1 ? "Active" : "Inactive";

    showDialog(
      context: context,
      builder: (context) => _buildDialogBase(
        context: context,
        title: "Update Floor",
        buttonLabel: "Update Floor",
        onConfirm: () => Navigator.pop(context),
        content: [
          _buildLabel("Floor Name *", isDark),
          _buildTextField(
            "Floor Name/Number",
            isDark,
            controller: floorNameController,
          ),
          const SizedBox(height: 16),
          _buildLabel("Incharge *", isDark),
          _buildTextField("Search incharge...", isDark),
          const SizedBox(height: 16),
          _buildLabel("Status", isDark),
          Obx(
            () => _buildDropdown(
              ["Select", "Active", "Inactive"],
              isDark,
              value: _selectedStatus.value ?? "Select",
              onChanged: (val) => _selectedStatus.value = val,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FloorModel floor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ),
              const Icon(
                Icons.error_outline,
                color: Color(0xFFfcc4a6),
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                "Are you sure? You want to delete this Floor",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "This is soft delete. This will hide data.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C79E0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Yes, Delete it!"),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _buildDialogBase({
    required BuildContext context,
    required String title,
    required String buttonLabel,
    required VoidCallback onConfirm,
    required List<Widget> content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2D2D3A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...content,
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C79E0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: isDark ? Colors.white70 : const Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    bool isDark, {
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.white38 : const Color(0xFFD1D5DB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? neon : const Color(0xFF7C79E0),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    bool isDark, {
    String? value,
    ValueChanged<String?>? onChanged,
  }) {
    final selectedValue = (value != null && items.contains(value))
        ? value
        : items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.white38 : const Color(0xFFD1D5DB),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedValue,
          dropdownColor: isDark ? const Color(0xFF2D2D3A) : Colors.white,
          icon: Icon(
            Icons.arrow_drop_down,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMiniDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey,
              fontSize: 13,
            ),
          ),
          dropdownColor: isDark ? dark2 : Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? neon : purpleDark,
            size: 18,
          ),
          items: items.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(
                e,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
