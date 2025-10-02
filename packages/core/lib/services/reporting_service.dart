// packages/core/lib/services/reporting_service.dart
class ReportingService {
  final ApiClient _apiClient;
  
  ReportingService(this._apiClient);
  
  Future<Report> generateReport({
    required ReportType type,
    required DateRange dateRange,
    String? tenantId,
    Map<String, dynamic>? filters,
  }) async {
    final response = await _apiClient.post('/reports/generate', {
      'type': type.value,
      'date_range': {
        'start': dateRange.start.toIso8601String(),
        'end': dateRange.end.toIso8601String(),
      },
      'tenant_id': tenantId,
      'filters': filters,
    });
    
    // Report generation is async, poll for completion
    final jobId = response.data['job_id'];
    return _pollForReport(jobId);
  }
  
  Future<Report> _pollForReport(String jobId) async {
    const maxAttempts = 60; // 5 minutes timeout
    var attempts = 0;
    
    while (attempts < maxAttempts) {
      final response = await _apiClient.get('/reports/status/$jobId');
      final status = response.data['status'];
      
      if (status == 'completed') {
        return Report.fromJson(response.data['report']);
      } else if (status == 'failed') {
        throw ReportGenerationException(response.data['error']);
      }
      
      // Wait before next poll
      await Future.delayed(const Duration(seconds: 5));
      attempts++;
    }
    
    throw ReportGenerationException('Report generation timed out');
  }
  
  Future<List<ScheduledReport>> getScheduledReports(String tenantId) async {
    final response = await _apiClient.get('/reports/scheduled?tenant_id=$tenantId');
    return (response.data as List)
        .map((json) => ScheduledReport.fromJson(json))
        .toList();
  }
  
  Future<void> scheduleReport({
    required ReportType type,
    required ReportSchedule schedule,
    required List<String> recipients,
    String? tenantId,
    Map<String, dynamic>? filters,
  }) async {
    await _apiClient.post('/reports/schedule', {
      'type': type.value,
      'schedule': schedule.toJson(),
      'recipients': recipients,
      'tenant_id': tenantId,
      'filters': filters,
    });
  }
}

// Report Templates
class ReportTemplates {
  static final salesReport = const ReportTemplate(
    name: 'Sales Report',
    sections: [
      const ReportSection(
        title: 'Executive Summary',
        widgets: [
          const KPIWidget(metrics: ['total_sales', 'order_count', 'avg_order_value']),
          const TrendChartWidget(metric: 'daily_sales', period: 30),
        ],
      ),
      const ReportSection(
        title: 'Product Performance',
        widgets: [
          const TableWidget(
            columns: ['product', 'quantity', 'revenue', 'growth'],
            sortBy: 'revenue',
          ),
          const PieChartWidget(metric: 'sales_by_category'),
        ],
      ),
      const ReportSection(
        title: 'Customer Analysis',
        widgets: [
          const MetricWidget(metric: 'new_vs_returning'),
          const HeatmapWidget(metric: 'order_time_distribution'),
        ],
      ),
    ],
  );
}