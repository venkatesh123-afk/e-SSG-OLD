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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Fee Heads",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ================= BODY =================
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                    Color(0xFF533483),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),

              /// -------- BRANCH DROPDOWN --------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    initialValue: selectedBranch,
                    dropdownColor: isDark
                        ? const Color(0xFF1a1a2e)
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withOpacity(0.12)
                          : Theme.of(context).cardColor,
                      hintText: "Select Branch",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: branchCtrl.branches
                        .map<DropdownMenuItem<String>>(
                          (b) => DropdownMenuItem(
                            value: b.branchName,
                            child: Text(b.branchName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      final branch = branchCtrl.branches.firstWhere(
                        (b) => b.branchName == v,
                      );

                      setState(() {
                        selectedBranch = v;
                        selectedBranchId = branch.id;
                      });

                      searchCtrl.clear(); // ✅ clear old search
                      feeCtrl.loadFeeHeads(branch.id);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ================= SEARCH BAR =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFF9E9E9E),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: isDark ? Colors.cyanAccent : Colors.black54,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) {
                            feeCtrl.searchFeeHead(v); // 🔥 SEARCH CONNECTED
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search fee",
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// -------- FEE HEAD LIST --------
              Expanded(
                child: Obx(() {
                  if (feeCtrl.isLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: SkeletonList(itemCount: 5),
                    );
                  }

                  if (feeCtrl.feeHeads.isEmpty) {
                    return Center(
                      child: Text(
                        "No Fee Heads Found",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black54,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: feeCtrl.feeHeads.length,
                    itemBuilder: (context, index) {
                      final fee = feeCtrl.feeHeads[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF0f3460),
                                    Color(0xFF533483),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.08),
                                    Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.08),
                                  ],
                                ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fee.feeHead,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fee.feeGroup,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Get.snackbar(
                                  "Collect Fee",
                                  "Collecting ${fee.feeHead}",
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.cyanAccent
                                    : Theme.of(context).primaryColor,
                                foregroundColor: isDark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                              child: const Text("Collect"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
