import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'project_list_screen.dart';
import 'template_screen.dart';
import 'music_screen.dart';
import 'profile_screen.dart';
import 'video_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _api = ApiService();

  final List<Widget> _pages = const [
    ProjectListScreen(),
    TemplateScreen(),
    SizedBox(),
    MusicScreen(),
    ProfileScreen(),
  ];

  void _createProject() {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('新建项目',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            const Text('创建一个新的视频剪辑项目',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '项目名称',
                prefixIcon:
                    Icon(Icons.edit_rounded, color: AppTheme.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final name =
                      nameController.text.trim().isEmpty ? '未命名项目' : nameController.text.trim();
                  try {
                    final res = await _api.createProject(name, '');
                    final data = res['data'] as Map<String, dynamic>?;
                    final projectId = (data?['id'] as num?)?.toInt();
                    final projectTitle = (data?['title'] ?? name).toString();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoEditorScreen(projectName: projectTitle, projectId: projectId),
                      ),
                    );
                    if (mounted) {
                      setState(() => _currentIndex = 0);
                      // 刷新项目列表
                    }
                  } catch (e) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('创建失败: $e')));
                  }
                },
                child: const Text('开始创作'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _pages,
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.accent, Color(0xFF00B894)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _createProject,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          if (i == 2) {
            _createProject();
          } else {
            setState(() => _currentIndex = i);
          }
        },
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined, size: 22),
            selectedIcon: Icon(Icons.folder_rounded, size: 22),
            label: '项目',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined, size: 22),
            selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded, size: 22),
            label: '模板',
          ),
          NavigationDestination(
            icon: SizedBox(width: 22, height: 22),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined, size: 22),
            selectedIcon: Icon(Icons.library_music_rounded, size: 22),
            label: '音乐',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, size: 22),
            selectedIcon: Icon(Icons.person_rounded, size: 22),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
