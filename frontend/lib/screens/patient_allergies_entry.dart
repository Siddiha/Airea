import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/patient_allergy.dart';
import 'patient_edit_allergy.dart';
import 'patient_account_created.dart';

class PatientAllergies extends StatefulWidget {
  const PatientAllergies({super.key});

  @override
  State<PatientAllergies> createState() => _PatientAllergiesState();
}

class _PatientAllergiesState extends State<PatientAllergies> {
  final List<AllergyEntry> _allergies = [];
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ── Add a new allergy entry from the text field ──
  void _addAllergy() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _allergies.add(AllergyEntry.create(name: name));
      _nameController.clear();
    });
  }

  // ── Delete an entry by its unique id ──
  void _deleteAllergy(String id) {
    setState(() {
      _allergies.removeWhere((e) => e.id == id);
    });
  }

  // ── Open the edit bottom sheet; apply the returned updated entry ──
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

  // ── Navigate to account created screen ──
  void _completeRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAccountCreated(allergies: _allergies),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────

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

              // ── Page heading ──
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
                'List any allergies or medical conditions',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              // ── Input row (text field + add button) ──
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
                  // ── Add (+) button ──
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

              // ── List or empty state fills remaining space ──
              Expanded(
                child: _allergies.isEmpty
                    ? _buildEmptyState()
                    : _buildAllergyList(),
              ),

              const SizedBox(height: 16),

              // ── Complete Registration button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Complete Registration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Skip button ──
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _completeRegistration,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // Sub-widgets
  // ────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(Icons.health_and_safety_outlined,
          //     size: 72, color: Colors.grey.shade300),
          // const SizedBox(height: 16),
          // Text(
          //   'No allergies added yet',
          //   style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          // ),
          // const SizedBox(height: 6),
          Text(
            'Type in the text box and press + to add',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Allergies & Conditions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: _allergies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final entry = _allergies[index];
              return _AllergyCard(
                entry: entry,
                onEdit: () => _openEditSheet(entry),
                onDelete: () => _deleteAllergy(entry.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Allergy card widget
// ─────────────────────────────────────────────────────────────────

class _AllergyCard extends StatelessWidget {
  const _AllergyCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final AllergyEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFEF6C00),
            size: 22,
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: entry.description.isNotEmpty
            ? Text(
                entry.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppTheme.primaryTeal,
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade400,
              tooltip: 'Delete',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
