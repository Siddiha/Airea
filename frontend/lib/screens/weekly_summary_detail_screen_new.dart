import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weekly_summary_detail_model.dart';
import '../repositories/summary_repository.dart';

class WeeklySummaryDetailScreenNew extends StatefulWidget {
  final DateTime weekStart;
  final String deviceId;
  final SummaryRepository repository;

  const WeeklySummaryDetailScreenNew({
    super.key,
    required this.weekStart,
    required this.deviceId,
    required this.repository,
  });

  @override
  State<WeeklySummaryDetailScreenNew> createState() =>
      _WeeklySummaryDetailScreenNewState();
}

class _WeeklySummaryDetailScreenNewState
    extends State<WeeklySummaryDetailScreenNew> {
  late Future<WeeklySummaryDetailModel> _summaryFuture;

  @override
  void initState() {
    super.initState();
    print('🔍 Repository type: ${widget.repository.runtimeType}');
    print('📅 Loading weekly summary for week starting: ${widget.weekStart}');
    _summaryFuture = widget.repository.getWeeklySummaryDetail(
      widget.deviceId,
      widget.weekStart,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FutureBuilder<WeeklySummaryDetailModel>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFA8E6CF),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading weekly summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No data for this week',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.data?.message ?? 'No events recorded this week',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final summary = snapshot.data!;
            return _buildSummaryContent(summary);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryContent(WeeklySummaryDetailModel summary) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Summary',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${_formatDate(summary.weekStart)} - ${_formatDate(summary.weekEnd)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),

        // Scrollable Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Stats Card
                _buildMainStatsCard(summary),
                const SizedBox(height: 20),

                // Week Over Week Comparison
                _buildWeekComparisonCard(summary.weekOverWeekComparison),
                const SizedBox(height: 20),

                // Daily Breakdown Chart
                _buildDailyBreakdownChart(summary),
                const SizedBox(height: 20),

                // Vitals Summary Section
                if (summary.vitalsSummary != null) ...[
                  _buildVitalsSummarySection(summary.vitalsSummary!),
                  const SizedBox(height: 20),
                ],

                // Vitals Trend Chart
                if (summary.vitalsSummary != null &&
                    summary.vitalsSummary!.hasVitalsData) ...[
                  _buildVitalsTrendChart(summary.vitalsSummary!),
                  const SizedBox(height: 20),
                ],

                // Statistics Grid
                _buildStatisticsGrid(summary),
                const SizedBox(height: 20),

                // Patterns
                if (summary.weeklyPatterns.isNotEmpty) ...[
                  _buildPatternsSection(summary.weeklyPatterns),
                  const SizedBox(height: 20),
                ],

                // Insights
                if (summary.weeklyInsights.isNotEmpty) ...[
                  _buildInsightsSection(summary.weeklyInsights),
                  const SizedBox(height: 20),
                ],

                // Recommendations
                if (summary.recommendations.isNotEmpty) ...[
                  _buildRecommendationsSection(summary.recommendations),
                  const SizedBox(height: 20),
                ],

                // Daily Breakdown List
                _buildDailyBreakdownList(summary.dailyBreakdown),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatsCard(WeeklySummaryDetailModel summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getSeverityGradient(summary.severityLevel),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${summary.coughSummary.totalCoughs}',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'TOTAL WEEKLY COUGHS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.coughSummary.avgCoughsPerDay.toStringAsFixed(1)} per day average',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              summary.severityLevel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekComparisonCard(WeekOverWeekComparisonModel comparison) {
    final isImproving = comparison.trend == 'IMPROVING';
    final isWorsening = comparison.trend == 'WORSENING';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Week Over Week',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildComparisonColumn('Last Week', comparison.previousWeekTotal),
              Icon(
                isImproving
                    ? Icons.trending_down
                    : isWorsening
                        ? Icons.trending_up
                        : Icons.trending_flat,
                size: 40,
                color: isImproving
                    ? Colors.green
                    : isWorsening
                        ? Colors.red
                        : Colors.grey,
              ),
              _buildComparisonColumn('This Week', comparison.currentWeekTotal),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isImproving
                  ? Colors.green.withOpacity(0.1)
                  : isWorsening
                      ? Colors.red.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isImproving
                      ? Icons.arrow_downward
                      : isWorsening
                          ? Icons.arrow_upward
                          : Icons.remove,
                  color: isImproving
                      ? Colors.green
                      : isWorsening
                          ? Colors.red
                          : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comparison.trendMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isImproving
                          ? Colors.green
                          : isWorsening
                              ? Colors.red
                              : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonColumn(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBreakdownChart(WeeklySummaryDetailModel summary) {
    final maxCoughs = summary.dailyBreakdown
        .map((d) => d.totalCoughs.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day Cough Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCoughs > 0 ? maxCoughs * 1.2 : 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = summary.dailyBreakdown[group.x];
                      return BarTooltipItem(
                        '${day.dayName}\n${day.totalCoughs} coughs',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < 7) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: summary.dailyBreakdown.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final isPeakDay =
                      day.dayIndex == summary.coughSummary.peakDay;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: day.totalCoughs.toDouble(),
                        color: isPeakDay
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFA8E6CF),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(const Color(0xFF4CAF50), 'Peak Day'),
              const SizedBox(width: 24),
              _buildLegendItem(const Color(0xFFA8E6CF), 'Other Days'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildVitalsSummarySection(WeeklyVitalsSummaryModel vitals) {
    if (!vitals.hasVitalsData) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.monitor_heart_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No Vitals Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            Text(
              vitals.vitalsMessage,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              const Text(
                'Weekly Vitals Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getVitalsStatusColor(vitals.vitalsStatus)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${vitals.daysWithVitalsData}/7 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getVitalsStatusColor(vitals.vitalsStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Vitals Cards
          if (vitals.heartRate != null)
            _buildVitalCard(
              'Heart Rate',
              vitals.heartRate!,
              Icons.favorite,
              'bpm',
              Colors.red,
            ),
          if (vitals.temperature != null)
            _buildVitalCard(
              'Temperature',
              vitals.temperature!,
              Icons.thermostat,
              '°C',
              Colors.orange,
            ),
          if (vitals.respiratoryRate != null)
            _buildVitalCard(
              'Respiratory Rate',
              vitals.respiratoryRate!,
              Icons.air,
              'br/min',
              Colors.blue,
            ),
        ],
      ),
    );
  }

  Widget _buildVitalCard(
    String label,
    WeeklyVitalStatsModel stats,
    IconData icon,
    String unit,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusBackgroundColor(stats.status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusBorderColor(stats.status),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      stats.statusMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.weeklyAverage.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      _getTrendIcon(stats.trend),
                      const SizedBox(width: 4),
                      Text(
                        stats.trend,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getTrendColor(stats.trend),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Min', '${stats.weeklyMin.toStringAsFixed(1)} $unit'),
              _buildMiniStat('Max', '${stats.weeklyMax.toStringAsFixed(1)} $unit'),
              _buildMiniStat('Readings', '${stats.totalReadings}'),
              if (stats.anomalyCount > 0)
                _buildMiniStat(
                  'Anomalies',
                  '${stats.anomalyCount}',
                  isHighlighted: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isHighlighted ? Colors.red : Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isHighlighted ? Colors.red : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsTrendChart(WeeklyVitalsSummaryModel vitals) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Vitals Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Heart Rate Chart
          if (vitals.dailyHeartRateAverages.any((v) => v != null)) ...[
            _buildMiniLineChart(
              'Heart Rate',
              vitals.dailyHeartRateAverages,
              days,
              Colors.red,
              'bpm',
            ),
            const SizedBox(height: 16),
          ],
          // Temperature Chart
          if (vitals.dailyTemperatureAverages.any((v) => v != null)) ...[
            _buildMiniLineChart(
              'Temperature',
              vitals.dailyTemperatureAverages,
              days,
              Colors.orange,
              '°C',
            ),
            const SizedBox(height: 16),
          ],
          // Respiratory Rate Chart
          if (vitals.dailyRespiratoryRateAverages.any((v) => v != null)) ...[
            _buildMiniLineChart(
              'Respiratory Rate',
              vitals.dailyRespiratoryRateAverages,
              days,
              Colors.blue,
              'br/min',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniLineChart(
    String label,
    List<double?> data,
    List<String> labels,
    Color color,
    String unit,
  ) {
    final validData = data.where((v) => v != null).map((v) => v!).toList();
    if (validData.isEmpty) return const SizedBox.shrink();

    final minY = validData.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = validData.reduce((a, b) => a > b ? a : b) * 1.05;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < labels.length) {
                        return Text(
                          labels[value.toInt()].substring(0, 1),
                          style: const TextStyle(fontSize: 8),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value ?? 0,
                    );
                  }).where((spot) => spot.y > 0).toList(),
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 0,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(WeeklySummaryDetailModel summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Coughs', '${summary.coughSummary.totalCoughs}'),
          _buildStatRow('Daily Average',
              '${summary.coughSummary.avgCoughsPerDay.toStringAsFixed(1)}'),
          _buildStatRow('Day Coughs', '${summary.coughSummary.totalDayCoughs}'),
          _buildStatRow('Night Coughs',
              '${summary.coughSummary.totalNightCoughs} (${summary.coughSummary.nightCoughPercentage.toStringAsFixed(1)}%)'),
          _buildStatRow('Peak Day',
              '${summary.coughSummary.peakDayName} (${summary.coughSummary.peakDayCoughs})'),
          _buildStatRow('Best Day',
              '${summary.coughSummary.lowestDayName} (${summary.coughSummary.lowestDayCoughs})'),
          _buildStatRow('Days with Data', '${summary.daysWithData}/7'),
          _buildStatRow('Severity Score', '${summary.severityScore}/100'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsSection(List<String> patterns) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pattern, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(
                'Weekly Patterns',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...patterns.map((pattern) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.analytics,
                        color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pattern,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(List<String> insights) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Weekly Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(List<String> recommendations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rec,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdownList(List<DailyBreakdownModel> dailyBreakdown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_view_week, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Text(
                'Daily Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...dailyBreakdown.map((day) => _buildDailyBreakdownItem(day)),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdownItem(DailyBreakdownModel day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: day.hasData
            ? _getSeverityBackgroundColor(day.severityLevel)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.dayName.substring(0, 3),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  day.date.substring(5),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: day.hasData
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDayStatColumn('Total', '${day.totalCoughs}'),
                      _buildDayStatColumn('Day', '${day.dayCoughs}'),
                      _buildDayStatColumn('Night', '${day.nightCoughs}'),
                      if (day.avgHeartRate != null)
                        _buildDayStatColumn(
                            'HR', '${day.avgHeartRate!.toStringAsFixed(0)}'),
                    ],
                  )
                : const Center(
                    child: Text(
                      'No data',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSeverityColor(day.severityLevel),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day.severityLevel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper Methods

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final month = months[int.parse(parts[1]) - 1];
        return '${parts[2]} $month';
      }
    } catch (e) {
      // fallback
    }
    return dateStr;
  }

  List<Color> _getSeverityGradient(String level) {
    switch (level.toUpperCase()) {
      case 'GOOD':
        return [const Color(0xFF4CAF50), const Color(0xFF81C784)];
      case 'MODERATE':
        return [const Color(0xFFFFA726), const Color(0xFFFFCC80)];
      case 'HIGH':
        return [const Color(0xFFFF7043), const Color(0xFFFFAB91)];
      case 'SEVERE':
        return [const Color(0xFFE53935), const Color(0xFFEF5350)];
      default:
        return [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)];
    }
  }

  Color _getSeverityColor(String level) {
    switch (level.toUpperCase()) {
      case 'GOOD':
        return const Color(0xFF4CAF50);
      case 'MODERATE':
        return const Color(0xFFFFA726);
      case 'HIGH':
        return const Color(0xFFFF7043);
      case 'SEVERE':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityBackgroundColor(String level) {
    switch (level.toUpperCase()) {
      case 'GOOD':
        return const Color(0xFFE8F5E9);
      case 'MODERATE':
        return const Color(0xFFFFF3E0);
      case 'HIGH':
        return const Color(0xFFFBE9E7);
      case 'SEVERE':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getVitalsStatusColor(String status) {
    if (status.toLowerCase().contains('critical')) {
      return Colors.red;
    } else if (status.toLowerCase().contains('elevated') ||
        status.toLowerCase().contains('multiple')) {
      return Colors.orange;
    } else {
      return const Color(0xFF4CAF50);
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return const Color(0xFFE8F5E9);
      case 'HIGH':
        return const Color(0xFFFFF3E0);
      case 'LOW':
        return const Color(0xFFE3F2FD);
      case 'CRITICAL':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return const Color(0xFF4CAF50);
      case 'HIGH':
        return const Color(0xFFFFA726);
      case 'LOW':
        return const Color(0xFF2196F3);
      case 'CRITICAL':
        return const Color(0xFFE53935);
      default:
        return Colors.grey;
    }
  }

  Icon _getTrendIcon(String trend) {
    switch (trend.toUpperCase()) {
      case 'INCREASING':
        return const Icon(Icons.trending_up, size: 14, color: Colors.red);
      case 'DECREASING':
        return const Icon(Icons.trending_down, size: 14, color: Colors.green);
      default:
        return const Icon(Icons.trending_flat, size: 14, color: Colors.grey);
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend.toUpperCase()) {
      case 'INCREASING':
        return Colors.red;
      case 'DECREASING':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
