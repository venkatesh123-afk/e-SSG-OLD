import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../api/api_service.dart';
import '../model/pro_dashboard_model.dart';
import '../model/pro_mom_model.dart';
import '../model/pro_yoy_model.dart';
import '../model/pro_admissions_chart_model.dart';

class ProDashboardController extends GetxController {
  final isLoading = false.obs;
  final dashboardData = Rxn<ProDashboardModel>();
  final momData = Rxn<ProMomModel>();
  final yoyData = Rxn<ProYoyModel>();
  final proAdmissionsChartData = Rxn<ProAdmissionsChartModel>();
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final dashboard = await ApiService.getProDashboardData();
      final mom = await ApiService.getProMomData();
      final yoy = await ApiService.getProYoyData();
      final proChart = await ApiService.getProAdmissionsChart();

      dashboardData.value = dashboard;
      momData.value = mom;
      yoyData.value = yoy;
      proAdmissionsChartData.value = proChart;
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint("Error fetching pro dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
