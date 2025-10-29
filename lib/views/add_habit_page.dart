import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/habit_controller.dart';
import '../models/habit_model.dart';

/// Page for adding or editing a habit
class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetMinutesController = TextEditingController();

  String _selectedFrequency = 'Daily';
  bool _isEditing = false;
  HabitModel? _editingHabit;

  final controller = Get.find<HabitController>();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Check if we're editing an existing habit
    if (Get.arguments != null) {
      _editingHabit = Get.arguments as HabitModel;
      _isEditing = true;
      _nameController.text = _editingHabit!.name;
      _selectedFrequency = _editingHabit!.frequency;
      if (_editingHabit!.targetMinutes != null) {
        _targetMinutesController.text = _editingHabit!.targetMinutes.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetMinutesController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (_formKey.currentState!.validate()) {
      if (_isEditing) {
        // Update existing habit
        final updatedHabit = _editingHabit!.copyWith(
          name: _nameController.text.trim(),
          frequency: _selectedFrequency,
          targetMinutes:
              _targetMinutesController.text.trim().isEmpty
                  ? null
                  : int.tryParse(_targetMinutesController.text.trim()),
        );

        final success = await controller.updateHabit(updatedHabit);
        if (success) {
          Get.back();
          Get.snackbar(
            'Success',
            'Habit updated successfully!',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Add new habit
        final success = await controller.addHabit(
          name: _nameController.text.trim(),
          frequency: _selectedFrequency,
          targetMinutes:
              _targetMinutesController.text.trim().isEmpty
                  ? null
                  : int.tryParse(_targetMinutesController.text.trim()),
        );

        if (success) {
          Get.back();
          Get.snackbar(
            'Success',
            'Habit added successfully!',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'updateHabit'.tr : 'addNewHabit'.tr),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await Get.dialog<bool>(
                  AlertDialog(
                    title: Text('deleteAll'.tr),
                    content: Text('areYouSureDeleteAll'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: Text('deleteAll'.tr),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await controller.deleteHabit(_editingHabit!.id!);
                  Get.back();
                  Get.snackbar(
                    'deleted'.tr,
                    'completedHabit'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Habit Name Field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'habitName'.tr,
                hintText: 'habitName'.tr,
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'pleaseEnterHabitName'.tr;
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),

            // Frequency Dropdown
            Text(
              'frequency'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'Daily', label: Text('daily'.tr)),
                ButtonSegment(value: 'Weekly', label: Text('weekly'.tr)),
                ButtonSegment(value: 'Custom', label: Text('custom'.tr)),
              ],
              selected: {_selectedFrequency},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedFrequency = newSelection.first;
                });
              },
            ),

            const SizedBox(height: 24),

            // Target Time Field (Optional)
            TextFormField(
              controller: _targetMinutesController,
              decoration: InputDecoration(
                labelText: 'targetMinutes'.tr,
                hintText: 'targetMinutes'.tr,
                prefixIcon: const Icon(Icons.timer),
                border: const OutlineInputBorder(),
                helperText: 'optionalDailyTarget'.tr,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final minutes = int.tryParse(value.trim());
                  if (minutes == null || minutes <= 0) {
                    return 'pleaseEnterValidNumber'.tr;
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEditing ? 'updateHabit'.tr : 'saveHabit'.tr,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
