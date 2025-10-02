import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nokta_pos/providers/session.dart';
import 'package:nokta_pos/models/tenant.dart';
import 'package:nokta_pos/services/api.dart';

class SaasDashboardScreen extends StatefulWidget {
  const SaasDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SaasDashboardScreen> createState() => _SaasDashboardScreenState();
}

class _SaasDashboardScreenState extends State<SaasDashboardScreen> {
  List<Tenant> tenants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    try {
      final response = await ApiService.get('/admin/tenants');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          tenants = data.map((e) => Tenant.fromJson(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل المستأجرين: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().current!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم SaaS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTenants,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tenants.isEmpty
          ? const Center(child: Text('لا يوجد مستأجرين'))
          : ListView.builder(
        itemCount: tenants.length,
        itemBuilder: (context, index) {
          final tenant = tenants[index];
          return ListTile(
            title: Text(tenant.name),
            subtitle: Text('الخطة: ${tenant.plan} - الحالة: ${tenant.status}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTenant(tenant),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTenant,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createTenant() {
    // سيتم تنفيذ واجهة إنشاء مستأجر جديد
  }

  void _editTenant(Tenant tenant) {
    // سيتم تنفيذ واجهة تعديل المستأجر
  }
}