import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/meal_entry.dart';
import '../services/food_database_service.dart';
import '../themes/color_theme.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<FoodItem> _searchResults = [];
  final List<FoodItemEntry> _selectedFoods = [];

  @override
  void initState() {
    super.initState();
    _searchResults = FoodDatabaseService.getAllFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchResults = FoodDatabaseService.searchFoods(query);
    });
  }

  void _addFood(FoodItem food) {
    setState(() {
      _selectedFoods.add(FoodItemEntry(foodItem: food));
    });
  }

  void _removeFood(int index) {
    setState(() {
      _selectedFoods.removeAt(index);
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _selectedFoods);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음식 검색'),
        actions: [
          if (_selectedFoods.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: Text(
                '완료 (${_selectedFoods.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_selectedFoods.isNotEmpty) _buildSelectedFoods(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _performSearch,
        decoration: InputDecoration(
          hintText: '음식 이름을 검색하세요',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildSelectedFoods() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: blueSeven.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선택한 음식',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: dalgeurakBlueOne,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFoods.asMap().entries.map((entry) {
              final index = entry.key;
              final foodEntry = entry.value;
              return Chip(
                label: Text(foodEntry.foodItem.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeFood(index),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 카테고리별로 그룹화
    final categories = <String, List<FoodItem>>{};
    for (var food in _searchResults) {
      final category = food.category ?? '기타';
      categories.putIfAbsent(category, () => []).add(food);
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final foods = categories[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
            ...foods.map((food) => _buildFoodItem(food)),
          ],
        );
      },
    );
  }

  Widget _buildFoodItem(FoodItem food) {
    final isSelected = _selectedFoods.any((e) => e.foodItem.id == food.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? dalgeurakBlueOne : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.restaurant, color: yellowFive),
        ),
        title: Text(
          food.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${food.calories.toInt()} kcal / ${food.servingSize.toInt()}${food.unit}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: dalgeurakBlueOne)
            : const Icon(Icons.add_circle_outline, color: Colors.grey),
        onTap: () {
          if (isSelected) {
            final index = _selectedFoods.indexWhere((e) => e.foodItem.id == food.id);
            _removeFood(index);
          } else {
            _addFood(food);
          }
        },
      ),
    );
  }
}
