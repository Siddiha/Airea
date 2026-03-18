import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/patient_allergy.dart';

/// A modal bottom sheet that lets the user edit an existing [AllergyEntry].
///
/// The sheet is opened via [showModalBottomSheet] and **pops** with the updated
/// [AllergyEntry] on save, or with `null` if the user dismisses without saving.
///
/// Usage:
/// ```dart
/// final updated = await showModalBottomSheet<AllergyEntry>(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => EditAllergySheet(entry: entry),
/// );
/// if (updated != null) { /* apply changes */ }
/// ```
class EditAllergySheet extends StatefulWidget {
  const EditAllergySheet({super.key, required this.entry});

  /// The existing allergy entry whose data pre-fills the editor.
  final AllergyEntry entry;

  @override
  State<EditAllergySheet> createState() => _EditAllergySheetState();
}

class _EditAllergySheetState extends State<EditAllergySheet> {
  late final TextEditingController _editController;
  bool _hasChanges = false;

  // ─────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Pre-fill the text field with whatever the user originally saved.
    // The editable text combines the name and description (if any) as a
    // single free-text block, matching the Figma design's single textarea.
    final initialText = widget.entry.description.isNotEmpty
        ? '${widget.entry.name}\n\n${widget.entry.description}'
        : widget.entry.name;

    _editController = TextEditingController(text: initialText)
      ..addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────
  // Actions
  // ─────────────────────────────────────

  void _onTextChanged() {
    final changed = _editController.text != _initialText;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  String get _initialText {
    return widget.entry.description.isNotEmpty
        ? '${widget.entry.name}\n\n${widget.entry.description}'
        : widget.entry.name;
  }

  void _saveChanges() {
    final raw = _editController.text.trim();
    if (raw.isEmpty) return;

    // First line → name; rest → description
    final lines = raw.split('\n');
    final newName = lines.first.trim();
    final newDesc = lines.length > 1
        ? lines.sublist(1).join('\n').trim()
        : '';

    final updated = widget.entry.copyWith(
      name: newName.isNotEmpty ? newName : widget.entry.name,
      description: newDesc,
    );

    Navigator.of(context).pop(updated);
  }

  void _dismiss() => Navigator.of(context).pop(null);

  // ─────────────────────────────────────
  // Build
  // ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // viewInsets accounts for the software keyboard so the sheet scrolls up.
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      // Tapping outside the sheet dismisses it.
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollController) => GestureDetector(
          // Prevent taps inside the sheet from propagating to the outside GestureDetector.
          onTap: () {},
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5), // light grey background matching Figma
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ──
                _DragHandle(),

                // ── Header row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit allergic\nconditions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ),
                      // ── Close ( × ) button ──
                      GestureDetector(
                        onTap: _dismiss,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Multi-line text area ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F4), // mint/teal tint matching Figma
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFB2DFDB),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: _editController,
                        maxLines: null,          // unlimited lines
                        expands: true,           // fills the container
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.55,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(18),
                          hintText: 'Enter allergy name on first line,\nadd notes below (optional)…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF90A4A0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Save button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _saveChanges : null,
                      style: AppTheme.primaryButton().copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.disabled)
                              ? Colors.grey.shade300
                              : AppTheme.darkBlue,
                        ),
                      ),
                      child: Text(
                        _hasChanges ? 'Save Changes' : 'No Changes',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Cancel link ──
                Center(
                  child: TextButton(
                    onPressed: _dismiss,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Small drag handle indicator at the top of the sheet
// ─────────────────────────────────────────────────────────────────
class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
