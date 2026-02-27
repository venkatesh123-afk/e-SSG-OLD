import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_app/staff_app/controllers/branch_controller.dart';
import 'package:student_app/staff_app/controllers/fee_controller.dart';
import 'package:student_app/staff_app/widgets/skeleton.dart';

final TextEditingController searchCtrl = TextEditingController();

class FeeHeadPage extends StatefulWidget {
  const FeeHeadPage({super.key});

  @override
  State<FeeHeadPage> createState() => _FeeHeadPageState();
}

class _FeeHeadPageState extends State<FeeHeadPage> {
  final BranchController branchCtrl = Get.put(BranchController());
  final FeeController feeCtrl = Get.put(FeeController());

  String? selectedBranch;
  int? selectedBranchId;

  @override
  void initState() {
    super.initState();
    branchCtrl.loadBranches();
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF7E49FF);
    const lavenderBg = Color(0xFFF1EEFF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ================= CUSTOM HEADER =================
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 25,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: primaryPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Fee Heads",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ================= BRANCH SELECTOR =================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Branch",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedBranch,
                                dropdownColor: Colors.white,
                                hint: const Text(
                                  "Select Branch",
                                  style: TextStyle(color: Colors.black54),
                                ),
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black,
                                ),
                                items: branchCtrl.branches
                                    .map<DropdownMenuItem<String>>(
                                      (b) => DropdownMenuItem(
                                        value: b.branchName,
                                        child: Text(
                                          b.branchName,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final branch = branchCtrl.branches.firstWhere(
                                    (b) => b.branchName == v,
                                  );

                                  setState(() {
                                    selectedBranch = v;
                                    selectedBranchId = branch.id;
                                  });

                                  searchCtrl.clear();
                                  feeCtrl.loadFeeHeads(branch.id);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ================= MAIN CONTENT AREA =================
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lavenderBg,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        // --- SEARCH BAR ---
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: primaryPurple.withOpacity(0.8),
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: searchCtrl,
                            onChanged: (v) => feeCtrl.searchFeeHead(v),
                            decoration: const InputDecoration(
                              hintText: "Search Student or ID",
                              hintStyle: TextStyle(color: Colors.black38),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.black54,
                                size: 22,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- FEE HEAD LIST ---
                        Obx(() {
                          if (feeCtrl.isLoading.value) {
                            return const SkeletonList(itemCount: 3);
                          }

                          if (feeCtrl.feeHeads.isEmpty) {
                            return const Center(
                              child: Text("No Fee Heads Found"),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: feeCtrl.feeHeads.length,
                            itemBuilder: (context, index) {
                              final fee = feeCtrl.feeHeads[index];
                              return _buildFeeItem(fee, context);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFeeItem(fee, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                Text(
                  fee.feeHead,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  "Fee",
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E7CFF), Color(0xFFD3ADFF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                Get.snackbar("Collect Fee", "Collecting ${fee.feeHead}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 0,
                ),
                minimumSize: const Size(90, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Collect",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const primaryPurple = Color(0xFF7E49FF);
    return Container(
      decoration: const BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, "Home", false),
          _navItem(Icons.assessment_rounded, "Attendance", false),
          _navItem(Icons.description_rounded, "Fees", true),
          _navItem(Icons.person, "Profile", false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isActive
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              )
            : Icon(icon, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
