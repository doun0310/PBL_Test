import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise_entry.dart';
import '../services/exercise_tracking_service.dart';

class ExerciseTrackingScreen extends StatefulWidget {
  const ExerciseTrackingScreen({super.key});

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  DateTime _selectedDate = DateTime.now();
  List<ExerciseEntry> _exercises = [];
  double _totalCaloriesBurned = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    final exercises = await ExerciseTrackingService.getExercisesByDate(_selectedDate);
    final totalCalories = await ExerciseTrackingService.getDailyCaloriesBurned(_selectedDate);
    
    setState(() {
      _exercises = exercises;
      _totalCaloriesBurned = totalCalories;
      _isLoading = false;
    });
  }

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddExerciseDialog(
        onAdd: (exercise) {
          ExerciseTrackingService.addExercise(exercise);
          _loadExercises();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddExerciseDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateSelector(),
                _buildSummaryCard(),
                Expanded(child: _buildExerciseList()),
              ],
            ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadExercises();
            },
          ),
          Text(
            DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _selectedDate.day == DateTime.now().day
                ? null
                : () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _loadExercises();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '오늘의 운동',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('운동 횟수', '${_exercises.length}회', Icons.fitness_center),
                _buildStatItem(
                  '소모 칼로리',
                  '${_totalCaloriesBurned.toStringAsFixed(0)} kcal',
                  Icons.local_fire_department,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildExerciseList() {
    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_gymnastics, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '운동 기록이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showAddExerciseDialog,
              icon: const Icon(Icons.add),
              label: const Text('운동 추가'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              child: const Icon(Icons.directions_run),
            ),
            title: Text(
              exercise.exerciseType,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${exercise.durationMinutes}분 • ${exercise.caloriesBurned.toStringAsFixed(0)} kcal',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await ExerciseTrackingService.deleteExercise(exercise.id);
                _loadExercises();
              },
            ),
          ),
        );
      },
    );
  }
}

class _AddExerciseDialog extends StatefulWidget {
  final Function(ExerciseEntry) onAdd;

  const _AddExerciseDialog({required this.onAdd});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  ExerciseType? _selectedType;
  int _durationMinutes = 30;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final caloriesBurned = _selectedType != null
        ? _selectedType!.caloriesPerMinute * _durationMinutes
        : 0.0;

    return AlertDialog(
      title: const Text('운동 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('운동 종류', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExerciseType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ExerciseType.predefinedTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text('${type.icon} ${type.name}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            const Text('운동 시간 (분)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              label: '$_durationMinutes분',
              onChanged: (value) {
                setState(() => _durationMinutes = value.toInt());
              },
            ),
            Text(
              '$_durationMinutes분',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '예상 소모 칼로리: ${caloriesBurned.toStringAsFixed(0)} kcal',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '메모 (선택사항)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _selectedType == null
              ? null
              : () {
                  final exercise = ExerciseEntry(
                    timestamp: DateTime.now(),
                    exerciseType: _selectedType!.name,
                    durationMinutes: _durationMinutes,
                    caloriesBurned: caloriesBurned,
                    notes: _notesController.text.isEmpty ? null : _notesController.text,
                  );
                  widget.onAdd(exercise);
                  Navigator.pop(context);
                },
          child: const Text('추가'),
        ),
      ],
    );
  }
}
