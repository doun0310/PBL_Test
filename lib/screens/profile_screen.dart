import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final List<String> _allergenOptions = [
    '우유', '계란', '대두', '밀', '돼지고기', 
    '쇠고기', '새우젓', '조개', '땅콩', '견과류'
  ];
  List<String> _selectedAllergens = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);

    _user = await AuthService.getCurrentUser();
    if (_user != null) {
      _nameController.text = _user!.name;
      _selectedAllergens = List.from(_user!.allergies);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // 취소 시 원래 값으로 복원
        if (_user != null) {
          _nameController.text = _user!.name;
          _selectedAllergens = List.from(_user!.allergies);
        }
      }
    });
  }

  Future<void> _saveProfile() async {
    // 실제 구현에서는 API 호출
    // 여기서는 로컬 저장소 업데이트만 시뮬레이션

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('프로필이 저장되었습니다'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('사용자 정보를 불러올 수 없습니다'))
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 프로필 이미지
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                _user!.name.isNotEmpty ? _user!.name[0] : '?',
                style: const TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 이름
          Card(
            child: ListTile(
              leading: const Icon(Icons.person),
              title: const Text('이름'),
              subtitle: _isEditing
                  ? TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '이름을 입력하세요',
                      ),
                    )
                  : Text(_user!.name),
            ),
          ),
          const SizedBox(height: 8),

          // 이메일
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text('이메일'),
              subtitle: Text(_user!.email),
            ),
          ),
          const SizedBox(height: 24),

          // 알레르기 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        '알레르기 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    Wrap(
                      spacing: 8,
                      children: _allergenOptions.map((allergen) {
                        final isSelected = _selectedAllergens.contains(allergen);
                        return FilterChip(
                          label: Text(allergen),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAllergens.add(allergen);
                              } else {
                                _selectedAllergens.remove(allergen);
                              }
                            });
                          },
                        );
                      }).toList(),
                    )
                  else if (_selectedAllergens.isEmpty)
                    const Text('등록된 알레르기 정보가 없습니다')
                  else
                    Wrap(
                      spacing: 8,
                      children: _selectedAllergens.map((allergen) {
                        return Chip(
                          label: Text(allergen),
                          backgroundColor: Colors.red[100],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 저장 버튼 (편집 모드일 때)
          if (_isEditing)
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('저장하기', style: TextStyle(fontSize: 16)),
            ),

          // 로그아웃 버튼
          if (!_isEditing) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _handleLogout,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              child: const Text('로그아웃', style: TextStyle(fontSize: 16)),
            ),
          ],
        ],
      ),
    );
  }
}
