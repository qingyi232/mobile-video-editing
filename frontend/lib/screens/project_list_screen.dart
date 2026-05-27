import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'video_editor_screen.dart';

class ProjectListScreen extends StatefulWidget {
  final int? initialStatusFilter;
  const ProjectListScreen({super.key, this.initialStatusFilter});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  List<dynamic> _projects = [];
  bool _loading = true;
  String _sortBy = 'latest';
  final _api = ApiService();
  int? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getProjects(status: _statusFilter);
      if (res['code'] == 200) {
        setState(() {
          _projects = res['data'] ?? [];
          _sortProjects();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _deleteProject(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除此项目吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: AppTheme.accentOrange))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteProject(id);
        _showMessage('已删除');
        _loadProjects();
      } catch (_) {
        _showMessage('删除失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_statusFilter == null
            ? '我的项目'
            : _statusFilter == 2
                ? '已导出作品'
                : '草稿箱'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, size: 22),
            onSelected: (v) {
              setState(() => _sortBy = v);
              _sortProjects();
            },
            itemBuilder: (_) => [
              _buildSortItem('latest', '最近修改'),
              _buildSortItem('name', '按名称'),
              _buildSortItem('oldest', '最早创建'),
            ],
          ),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : _projects.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: _loadProjects,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _projects.length,
                    itemBuilder: (_, i) => _buildProjectCard(_projects[i]),
                  ),
                ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            const Icon(Icons.check_rounded, size: 18, color: AppTheme.accent)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 90,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.video_library_outlined,
                size: 36, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          const Text('还没有项目', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('点击下方 + 开始创作',
              style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
        ],
      ),
    );
  }

  void _sortProjects() {
    _projects.sort((a, b) {
      DateTime parse(dynamic value) {
        if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
        return DateTime.tryParse(value.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }

      final aTitle = (a['title'] ?? a['name'] ?? '').toString();
      final bTitle = (b['title'] ?? b['name'] ?? '').toString();
      final aTime = parse(a['updatedAt'] ?? a['createdAt']);
      final bTime = parse(b['updatedAt'] ?? b['createdAt']);

      switch (_sortBy) {
        case 'name':
          return aTitle.compareTo(bTitle);
        case 'oldest':
          return aTime.compareTo(bTime);
        case 'latest':
        default:
          return bTime.compareTo(aTime);
      }
    });
  }

  Widget _buildProjectCard(dynamic project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final id = (project['id'] as num?)?.toInt();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoEditorScreen(
                projectName: (project['title'] ?? project['name'] ?? '未命名').toString(),
                projectId: id,
              ),
            ),
          );
          if (mounted) _loadProjects();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.2),
                      AppTheme.accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.movie_creation_outlined,
                    color: AppTheme.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (project['title'] ?? project['name'] ?? '未命名').toString(),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13,
                            color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(project['updatedAt'] ?? project['createdAt']),
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            project['status'] == 1 || project['status'] == 'exported'
                                ? '已导出'
                                : '编辑中',
                            style: const TextStyle(fontSize: 11, color: AppTheme.accent),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppTheme.textSecondary, size: 20),
                onSelected: (v) {
                  if (v == 'delete') {
                    final id = (project['id'] as num?)?.toInt();
                    if (id != null) _deleteProject(id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'export', child: Text('导出')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('删除', style: TextStyle(color: AppTheme.accentOrange))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
