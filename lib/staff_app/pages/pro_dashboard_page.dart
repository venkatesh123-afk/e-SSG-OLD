import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:student_app/staff_app/controllers/theme_controller.dart';
import '../controllers/pro_dashboard_controller.dart';
import '../model/pro_mom_model.dart';
import '../model/pro_yoy_model.dart';
import '../model/pro_admissions_chart_model.dart';

class ProAdmissionPage extends StatelessWidget {
  const ProAdmissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    final proDashboardCtrl = Get.put(ProDashboardController());
    final isDark = themeCtrl.isDark.value;

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
        appBar: _buildAppBar(context),
        body: Obx(() {
          if (proDashboardCtrl.isLoading.value &&
              proDashboardCtrl.dashboardData.value == null) {
            return _buildSkeletonLoading(context);
          }

          if (proDashboardCtrl.errorMessage.isNotEmpty &&
              proDashboardCtrl.dashboardData.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    proDashboardCtrl.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => proDashboardCtrl.fetchDashboardData(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final data = proDashboardCtrl.dashboardData.value;
          if (data == null) {
            return const Center(child: Text("No data available"));
          }

          return RefreshIndicator(
            onRefresh: () => proDashboardCtrl.fetchDashboardData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildAnalysisCard(
                        "Total",
                        [data.totalAdmissions.toString()],
                        Icons.groups_outlined,
                        [const Color(0xFF7b84db), const Color(0xFF5a63ba)],
                      ),
                      _buildAnalysisCard(
                        "Today",
                        [data.today.toString()],
                        Icons.calendar_today,
                        [const Color(0xFFffb84d), const Color(0xFFff9900)],
                      ),
                      _buildAnalysisCard(
                        "Yesterday",
                        [data.yesterday.toString()],
                        Icons.event_note,
                        [const Color(0xFF2ebf8a), const Color(0xFF19a674)],
                      ),
                      _buildAnalysisCard(
                        "This Week",
                        [data.thisWeek.toString()],
                        Icons.view_week,
                        [const Color(0xFFff6b6b), const Color(0xFFee5253)],
                      ),
                      _buildAnalysisCard(
                        "This Month",
                        [data.thisMonth.toString()],
                        Icons.calendar_month,
                        [const Color(0xFF54a0ff), const Color(0xFF2e86de)],
                      ),
                      _buildAnalysisCard(
                        "Last Month",
                        [data.lastMonth.toString()],
                        Icons.history,
                        [const Color(0xFF8b94e1), const Color(0xFF6c7cd1)],
                      ),
                      _buildAnalysisCard(
                        "Boys",
                        [data.boys.toString()],
                        Icons.person_outline,
                        [const Color(0xFF54a0ff), const Color(0xFF2e86de)],
                      ),
                      _buildAnalysisCard(
                        "Girls",
                        [data.girls.toString()],
                        Icons.face_6_outlined,
                        [const Color(0xFFa2a8d3), const Color(0xFF858dbd)],
                      ),
                      _buildAnalysisCard(
                        "Hostel",
                        [data.hostel.toString()],
                        Icons.apartment,
                        [const Color(0xFFffca28), const Color(0xFFffb300)],
                      ),
                      _buildAnalysisCard(
                        "Day",
                        [data.day.toString()],
                        Icons.directions_bus_outlined,
                        [const Color(0xFF43a047), const Color(0xFF2e7d32)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionHeader(context, "Admission Analysis"),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildAnalysisCard(
                        "Target",
                        [data.target.toString()],
                        Icons.track_changes_sharp,
                        [const Color(0xFF7079D1), const Color(0xFF5560B9)],
                      ),
                      _buildAnalysisCard(
                        "Paid",
                        [data.paid.toString()],
                        Icons.monetization_on_outlined,
                        [const Color(0xFFFDB75E), const Color(0xFFF7941D)],
                      ),
                      _buildAnalysisCard(
                        "Not Paid",
                        [data.notPaid.toString()],
                        Icons.wallet_outlined,
                        [const Color(0xFF4DBB91), const Color(0xFF13A871)],
                      ),
                      _buildAnalysisCard(
                        "Local",
                        [data.local.toString()],
                        Icons.location_on_outlined,
                        [const Color(0xFF4DC4F4), const Color(0xFF1A9FD9)],
                      ),
                      _buildAnalysisCard(
                        "Non-Local",
                        [data.nonLocal.toString()],
                        Icons.directions_bus_outlined,
                        [const Color(0xFFE54D7E), const Color(0xFFD81B60)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionHeader(context, "Pro Admissions Analysis"),
                  const SizedBox(height: 10),
                  _buildLegend(context, [
                    {
                      "label": "Total Admissions",
                      "color": const Color(0xFF1DB082),
                    },
                    {
                      "label": "Remaining Targets",
                      "color": const Color(0xFF6371D1),
                    },
                  ]),
                  const SizedBox(height: 20),
                  _buildAnalysisChart(
                    context,
                    proDashboardCtrl.proAdmissionsChartData.value,
                  ),
                  const SizedBox(height: 30),
                  if (proDashboardCtrl.yoyData.value != null)
                    _buildYearOnYearChart(
                      context,
                      proDashboardCtrl.yoyData.value!,
                    ),
                  const SizedBox(height: 30),
                  _buildMonthOnMonthChart(
                    context,
                    proDashboardCtrl.momData.value,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 64,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: () => Get.back(),
      ),
      title: const Text(
        "Pro Admission",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildYearOnYearChart(BuildContext context, ProYoyModel yoyData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black54;

    final sessionColors = [
      const Color(0xFF1DB9C3),
      const Color(0xFF7077A1),
      const Color(0xFFF6B17A),
      const Color(0xFF424769),
      const Color(0xFF2D3250),
    ];

    // Build legend row (just session names as shown in user's image)
    final legendItems = <Map<String, dynamic>>[];
    for (int i = 0; i < yoyData.sessions.length; i++) {
      legendItems.add({
        "label": "${yoyData.sessions[i]} Admissions",
        "color": sessionColors[i % sessionColors.length],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Pro Year on Year Analytics"),
        const SizedBox(height: 10),
        _buildLegend(context, legendItems),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          controller: ScrollController(),
          child: SizedBox(
            width: math.max(
              MediaQuery.of(context).size.width - 32,
              yoyData.data.length * 90.0,
            ),
            height: 440,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 20),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      (yoyData.data.fold<double>(0, (max, pro) {
                                final proMax = pro.history.fold<double>(
                                  0,
                                  (m, h) => h.admissions > m
                                      ? h.admissions.toDouble()
                                      : m,
                                );
                                return proMax > max ? proMax : max;
                              }) *
                              1.5)
                          .ceilToDouble(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.9),
                      tooltipBorderRadius: BorderRadius.circular(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          "${yoyData.sessions[rodIndex]}\n",
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: rod.toY.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 80,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < yoyData.data.length) {
                            return SideTitleWidget(
                              meta: meta,
                              space: 12,
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  yoyData.data[value.toInt()].proName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: labelColor,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) return const SizedBox();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(color: labelColor, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: value == 0
                          ? (isDark ? Colors.white38 : Colors.grey[400]!)
                          : (isDark
                                ? Colors.white10
                                : Colors.grey.withOpacity(0.2)),
                      strokeWidth: value == 0 ? 2 : 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white38 : Colors.grey[400]!,
                        width: 1,
                      ),
                    ),
                  ),
                  barGroups: List.generate(yoyData.data.length, (index) {
                    final proData = yoyData.data[index];

                    return BarChartGroupData(
                      x: index,
                      barRods: List.generate(proData.history.length, (hIndex) {
                        final history = proData.history[hIndex];
                        return BarChartRodData(
                          toY: history.admissions.toDouble(),
                          color: sessionColors[hIndex % sessionColors.length],
                          width: 10,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFFC62828),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, List<Map<String, dynamic>> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item['label'] as String,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAnalysisChart(
    BuildContext context,
    ProAdmissionsChartModel? data,
  ) {
    if (data == null || data.data.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black54;
    final scrollController = ScrollController();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      controller: scrollController,
      child: Container(
        width: data.data.length * 85.0 + 40,
        height: 350,
        padding: const EdgeInsets.only(right: 16, top: 20),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY:
                data.data.fold<double>(
                  0,
                  (max, element) =>
                      element.target > max ? element.target.toDouble() : max,
                ) *
                1.35,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < data.data.length) {
                      return SideTitleWidget(
                        meta: meta,
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            data.data[value.toInt()].proName,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w500,
                              color: labelColor,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 100,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(color: labelColor, fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: value == 0
                    ? (isDark ? Colors.white38 : Colors.grey[400]!)
                    : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
                strokeWidth: value == 0 ? 2 : 1,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white38 : Colors.grey[400]!,
                  width: 1,
                ),
              ),
            ),
            barGroups: List.generate(data.data.length, (index) {
              final item = data.data[index];
              final achieved = item.totalAdmissions.toDouble();
              final target = item.target.toDouble();
              final remaining = (target - achieved).clamp(0, 10000).toDouble();

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: achieved + remaining,
                    width: 12,
                    borderRadius: BorderRadius.zero,
                    rodStackItems: [
                      BarChartRodStackItem(
                        0,
                        achieved,
                        const Color(0xFF1DB082),
                      ),
                      BarChartRodStackItem(
                        achieved,
                        achieved + remaining,
                        const Color(0xFF6371D1),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthOnMonthChart(BuildContext context, ProMomModel? momData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black54;

    if (momData == null || momData.data.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text("No trend data available")),
      );
    }

    final sessionColors = [
      const Color(0xFF4DC4F4),
      const Color(0xFF1DB082),
      const Color(0xFFFDB75E),
      const Color(0xFFE54D7E),
      const Color(0xFF7b84db),
    ];

    final legendItems = <Map<String, dynamic>>[];
    for (int i = 0; i < momData.data.length; i++) {
      legendItems.add({
        "label": momData.data[i].sessionName,
        "color": sessionColors[i % sessionColors.length],
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          "Admissions Month on Month (Session Wise)",
        ),
        const SizedBox(height: 10),
        _buildLegend(context, legendItems),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          controller: ScrollController(),
          child: Container(
            padding: const EdgeInsets.only(right: 20, top: 20),
            width: math.max(
              MediaQuery.of(context).size.width - 32,
              momData.months.length * 80.0,
            ),
            height: 380,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    momData.data.fold<double>(0, (max, session) {
                      final sessionMax = session.months.fold<double>(
                        0,
                        (m, month) =>
                            month.count > m ? month.count.toDouble() : m,
                      );
                      return sessionMax > max ? sessionMax : max;
                    }) *
                    1.4,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value >= 0 && value < momData.months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              momData.months[value.toInt()],
                              style: TextStyle(fontSize: 10, color: labelColor),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      "Admissions Count",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: labelColor,
                      ),
                    ),
                    axisNameSize: 40,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: labelColor, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: value == 0
                        ? (isDark ? Colors.white38 : Colors.grey[400]!)
                        : (isDark
                              ? Colors.white10
                              : Colors.grey.withOpacity(0.2)),
                    strokeWidth: value == 0 ? 2 : 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white38 : Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                ),
                barGroups: List.generate(momData.months.length, (monthIndex) {
                  final monthName = momData.months[monthIndex];

                  return BarChartGroupData(
                    x: monthIndex,
                    barRods: List.generate(momData.data.length, (sessionIndex) {
                      final session = momData.data[sessionIndex];
                      final monthData = session.months.firstWhere(
                        (m) => m.month == monthName,
                        orElse: () => MonthCount(month: monthName, count: 0),
                      );

                      return BarChartRodData(
                        toY: monthData.count.toDouble(),
                        width: 8,
                        color:
                            sessionColors[sessionIndex % sessionColors.length],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
    String title,
    List<String> values,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
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
                      for (var value in values)
                        Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.white24 : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(10, (index) => _buildSkeletonCard()),
            ),
            const SizedBox(height: 30),
            _buildSkeletonText(150),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(5, (index) => _buildSkeletonCard()),
            ),
            const SizedBox(height: 30),
            _buildSkeletonText(180),
            const SizedBox(height: 20),
            _buildSkeletonChart(),
            const SizedBox(height: 30),
            _buildSkeletonText(180),
            const SizedBox(height: 20),
            _buildSkeletonChart(),
            const SizedBox(height: 30),
            _buildSkeletonText(180),
            const SizedBox(height: 20),
            _buildSkeletonChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildSkeletonText(double width) {
    return Container(
      width: width,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSkeletonChart() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
