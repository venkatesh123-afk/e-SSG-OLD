import 'package:get/get.dart';
import '../api/api_service.dart';
import '../api/api_collection.dart';
import '../model/fee_head_model.dart';

class FeeController extends GetxController {
  /// Loading indicator
  final RxBool isLoading = false.obs;

  /// Filtered list (used by UI)
  final RxList<FeeHeadModel> feeHeads = <FeeHeadModel>[].obs;

  /// Full list (for search reset)
  final List<FeeHeadModel> allFeeHeads = [];

  /// Load fee heads by branch
  Future<void> loadFeeHeads(int branchId) async {
    try {
      isLoading.value = true;

      final data = await ApiService.getRequest(
        ApiCollection.feeHeadsByBranch(branchId),
      );

      /// Handle both bool & string success
      final bool success = data['success'] == true || data['success'] == "true";

      if (success && data['indexdata'] != null) {
        final List list = data['indexdata'];

        allFeeHeads
          ..clear()
          ..addAll(
            list
                .map((e) => FeeHeadModel.fromJson(e))
                .where((f) => f.status == 1), // active only
          );

        /// show full list initially
        feeHeads.value = List.from(allFeeHeads);
      } else {
        feeHeads.clear();
        allFeeHeads.clear();
        Get.snackbar("Info", "No fee heads found");
      }
    } catch (e) {
      feeHeads.clear();
      allFeeHeads.clear();
      Get.snackbar("Error", "Failed to load fee heads");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔍 SEARCH fee heads
  void searchFeeHead(String query) {
    if (query.isEmpty) {
      feeHeads.value = List.from(allFeeHeads);
    } else {
      feeHeads.value = allFeeHeads
          .where((f) => f.feeHead.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Clear everything
  void clear() {
    feeHeads.clear();
    allFeeHeads.clear();
  }
}
