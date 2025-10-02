// branches_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../models/branch.dart';
import '../providers/session.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({Key? key}) : super(key: key);

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<Branch> branches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiService.get('/branches');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          branches = data.map((e) => Branch.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('فشل في تحميل الفروع');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الفروع: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<Session>().current!;

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار الفرع')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : branches.isEmpty
          ? const Center(child: Text('لا توجد فروع متاحة'))
          : ListView.builder(
        itemCount: branches.length,
        itemBuilder: (_, i) {
          final branch = branches[i];
          return ListTile(
            title: Text(branch.name),
            subtitle: branch.address != null ? Text(branch.address!) : null,
            onTap: () {
              // تحديث فرع المستخدم
              user.branchId = branch.id;
              Navigator.pushReplacementNamed(context, '/pos');
            },
          );
        },
      ),
    );
  }
}