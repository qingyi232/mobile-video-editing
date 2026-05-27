import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class TemplateScreen extends StatefulWidget {
  const TemplateScreen({super.key});

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  String _selectedCategory = '全部';
  List<dynamic> _templates = [];
  bool _loading = true;

  final List<Map<String, dynamic>> _categories = [
    {'label': '全部', 'icon': Icons.apps_rounded},
    {'label': 'festival', 'icon': Icons.celebration_rounded},
    {'label': 'vlog', 'icon': Icons.videocam_rounded},
    {'label': 'tutorial', 'icon': Icons.school_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getAllTemplates();
      if (res['code'] == 200) {
        setState(() {
          _templates = res['data'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _templates = [];
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredTemplates {
    if (_selectedCategory == '全部') return _templates;
    return _templates.where((t) => (t['category']?.toString() ?? '') == _selectedCategory).toList();
  }

  String _labelCategory(String raw) {
    const names = {
      'festival': '节日',
      'vlog': 'Vlog',
      'tutorial': '教程',
    };
    return names[raw] ?? raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模板中心')),
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(
            child: _loading
                ? _buildSkeleton()
                : _filteredTemplates.isEmpty
                    ? const Center(
                        child: Text('暂无模板',
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _filteredTemplates.length,
                        itemBuilder: (_, i) =>
                            _buildTemplateCard(_filteredTemplates[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _categories[i];
          final selected = _selectedCategory == c['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = c['label'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(22),
                border: selected
                    ? Border.all(color: AppTheme.accent.withValues(alpha: 0.5))
                    : null,
              ),
              child: Row(
                children: [
                  Icon(c['icon'] as IconData,
                      size: 16,
                      color: selected ? AppTheme.accent : AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _labelCategory(c['label'] as String),
                    style: TextStyle(
                      color: selected ? AppTheme.accent : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.78,
      ),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showTemplateDetail(dynamic template, List<Color> colorPair) {
    final cat = (template['category'] ?? '').toString();
    final desc = (template['description'] ?? '暂无描述').toString();
    final ratio = (template['aspectRatio'] ?? '16:9').toString();
    final dur = template['duration'];
    final usage = template['usageCount'] ?? 0;

    const effectMap = {
      'festival': {'transition': '缩放过渡', 'filter': '暖色调', 'style': '喜庆热闹，适合节日庆祝视频'},
      'vlog': {'transition': '滑动切换', 'filter': '胶片质感', 'style': '自然清新，适合日常记录'},
      'tutorial': {'transition': '淡入淡出', 'filter': '明亮通透', 'style': '简洁明了，适合教学演示'},
    };
    final effect = effectMap[cat] ?? {'transition': '淡入淡出', 'filter': '无', 'style': '通用风格'};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [colorPair[0].withValues(alpha: 0.3), colorPair[1].withValues(alpha: 0.1)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.movie_filter_rounded, color: colorPair[0], size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template['name'] ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(_labelCategory(cat),
                          style: TextStyle(color: colorPair[0], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(desc,
                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 14, height: 1.5)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _detailRow(Icons.animation_rounded, '转场效果', effect['transition']!),
                  const SizedBox(height: 10),
                  _detailRow(Icons.filter_vintage_rounded, '滤镜风格', effect['filter']!),
                  const SizedBox(height: 10),
                  _detailRow(Icons.aspect_ratio_rounded, '画面比例', ratio),
                  if (dur != null) ...[
                    const SizedBox(height: 10),
                    _detailRow(Icons.timer_rounded, '建议时长', '${(dur as num).toStringAsFixed(0)}s'),
                  ],
                  const SizedBox(height: 10),
                  _detailRow(Icons.style_rounded, '风格特点', effect['style']!),
                  const SizedBox(height: 10),
                  _detailRow(Icons.download_rounded, '使用次数', '$usage 次'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final id = template['id'];
                  if (id == null) return;
                  try {
                    final res = await ApiService().useTemplate((id as num).toInt());
                    if (!mounted) return;
                    if (res['code'] == 200) {
                      await _loadTemplates();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已应用模板: ${template['name']}')),
                      );
                    }
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('应用模板失败')),
                    );
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('应用此模板'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.accent),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTemplateCard(dynamic template) {
    final colors = [
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
      [AppTheme.accent, const Color(0xFF00B894)],
      [const Color(0xFFFFD93D), const Color(0xFFFFE066)],
      [const Color(0xFF6C63FF), const Color(0xFF8B83FF)],
      [const Color(0xFF48CAE4), const Color(0xFF90E0EF)],
      [const Color(0xFFFF6B9D), const Color(0xFFFF8EBA)],
    ];
    final colorIdx = (template['id'] ?? 0) % colors.length;
    final colorPair = colors[colorIdx];

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTemplateDetail(template, colorPair),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorPair[0].withValues(alpha: 0.3),
                      colorPair[1].withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(Icons.play_circle_outline_rounded,
                      size: 40, color: colorPair[0]),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template['name'] ?? '',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(template['description'] ?? '',
                          style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.6),
                              fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Row(
                      children: [
                        Icon(Icons.download_rounded,
                            size: 12,
                            color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(width: 3),
                        Text('${template['usageCount'] ?? 0}',
                            style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                                fontSize: 11)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorPair[0].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_labelCategory((template['category'] ?? '').toString()),
                               style: TextStyle(
                                   color: colorPair[0], fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
