import 'package:flutter/material.dart';
import '../models/patient_allergy.dart';
import '../services/profile_service.dart';
import 'patient_edit_allergy.dart';

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/patient_allergy.dart';
import '../services/profile_service.dart';
import 'patient_edit_allergy.dart';

class ViewAllergiesScreen extends StatefulWidget {
  const ViewAllergiesScreen({super.key});

  @override
  State<ViewAllergiesScreen> createState() => _ViewAllergiesScreenState();
}

class _ViewAllergiesScreenState extends State<ViewAllergiesScreen> {
  List<AllergyEntry> _allergies = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ProfileService.loadAllergies();
    setState(() => _allergies = list);
  }

  Future<void> _save() async {
    await ProfileService.saveAllergies(_allergies);
  }

  void _add() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _allergies.add(AllergyEntry.create(name: name));
      _controller.clear();
    });
    _save();
  }

  void _delete(String id) async {
    setState(() => _allergies.removeWhere((a) => a.id == id));
    await _save();
  }

  Future<void> _edit(AllergyEntry entry) async {
    final updated = await showModalBottomSheet<AllergyEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAllergySheet(entry: entry),
    );
    if (updated != null) {
      final idx = _allergies.indexWhere((a) => a.id == updated.id);
      if (idx != -1) {
        setState(() => _allergies[idx] = updated);
        await _save();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Allergic Conditions', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Add allergy or condition'),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _add, child: const Text('Add')),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _allergies.isEmpty
                    ? const Center(child: Text('No allergic conditions recorded.'))
                    : ListView.separated(
                        itemCount: _allergies.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final a = _allergies[i];
                          return ListTile(
                            title: Text(a.name),
                            subtitle: a.description.isNotEmpty ? Text(a.description) : null,
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(a)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(a.id)),
                            ]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class PatientViewAllergies extends StatefulWidget {
  const PatientViewAllergies({super.key});

  @override
  State<PatientViewAllergies> createState() => _PatientViewAllergiesState();
}

class _PatientViewAllergiesState extends State<PatientViewAllergies> {
  late List<AllergyEntry> _allergies;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllergies();
  }

  Future<void> _loadAllergies() async {
    final allergies = await ProfileService.loadAllergies();
    setState(() {
      _allergies = allergies;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addAllergy() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _allergies.add(AllergyEntry.create(name: name));
      _nameController.clear();
    });
  }

  void _deleteAllergy(String id) {
    setState(() {
      _allergies.removeWhere((e) => e.id == id);
    });
  }

  Future<void> _openEditSheet(AllergyEntry entry) async {
    final updated = await showModalBottomSheet<AllergyEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditAllergySheet(entry: entry),
    );

    if (updated != null) {
      setState(() {
        final index = _allergies.indexWhere((e) => e.id == updated.id);
        if (index != -1) _allergies[index] = updated;
      });
    }
  }

  Future<void> _saveAllergies() async {
    await ProfileService.saveAllergies(_allergies);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allergies updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Allergies & Conditions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Allergies & Medical\nConditions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your allergies or medical conditions',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // Input row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addAllergy(),
                      decoration: InputDecoration(
                        labelText: 'Allergy or Condition',
                        hintText: 'Type here',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryTeal, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _addAllergy,
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // List or empty state
              Expanded(
                child: _allergies.isEmpty
                    ? Center(
                        child: Text(
                          'No allergies or conditions recorded',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _allergies.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final allergy = _allergies[index];
                          return GestureDetector(
                            onTap: () => _openEditSheet(allergy),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          allergy.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (allergy.description.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            allergy.description,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteAllergy(allergy.id),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    iconSize: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAllergies,
                  style: AppTheme.primaryButton(),
                  child: const Text('Save changes'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
