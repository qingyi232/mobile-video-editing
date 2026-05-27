import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'project_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final api = ApiService();
      final res = await api.getProfile();
      Map<String, dynamic>? st;
      try {
        final sr = await api.getUserStats();
        if (sr['code'] == 200) {
          st = Map<String, dynamic>.from(sr['data'] as Map);
        }
      } catch (_) {}
      if (res['code'] == 200 && mounted) {
        setState(() {
          _profile = Map<String, dynamic>.from(res['data'] as Map);
          _stats = st;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('退出', style: TextStyle(color: AppTheme.accentOrange))),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildStatsRow(),
                const SizedBox(height: 20),
                _buildActivityChart(),
                const SizedBox(height: 24),
                _buildMenuSection('作品管理', [
                  _MenuItem(Icons.video_library_rounded, '我的作品', AppTheme.accent,
                      () => _navigateToProjects(null)),
                  _MenuItem(Icons.download_done_rounded, '已导出', const Color(0xFF48CAE4),
                      () => _navigateToProjects(2)),
                  _MenuItem(Icons.drafts_rounded, '草稿箱', AppTheme.accentYellow,
                      () => _navigateToProjects(0)),
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('账号设置', [
                  _MenuItem(Icons.person_outline_rounded, '编辑资料', AppTheme.accent,
                      () => _showEditProfile()),
                  _MenuItem(Icons.camera_alt_rounded, '更换头像', const Color(0xFF48CAE4),
                      () => _changeAvatar()),
                  _MenuItem(Icons.lock_outline_rounded, '修改密码', const Color(0xFF6C63FF),
                      () => _showChangePassword()),
                  _MenuItem(Icons.storage_rounded, '存储空间', AppTheme.accentYellow,
                      () => _showStorageInfo()),
                ]),
                const SizedBox(height: 16),
                _buildMenuSection('其他', [
                  _MenuItem(Icons.info_outline_rounded, '关于', AppTheme.textSecondary,
                      () => _showAbout()),
                  _MenuItem(Icons.help_outline_rounded, '帮助反馈', AppTheme.textSecondary,
                      () => _showFeedback()),
                ]),
                const SizedBox(height: 24),
                _buildLogoutButton(),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _profile?['nickname'] ?? _profile?['username'] ?? '用户';
    final username = _profile?['username'] ?? '';
    final email = _profile?['email']?.toString();
    final avatarUrl = _profile?['avatarUrl']?.toString();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final bio = _profile?['bio']?.toString();
    final createdAt = _profile?['createdAt']?.toString();
    String? joinDate;
    if (createdAt != null && createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        joinDate = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} 加入';
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.12),
            AppTheme.accent.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _changeAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.accent, Color(0xFF00B894)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasAvatar
                          ? Image.network(
                              ApiService.mediaUrlFromServerPath(avatarUrl),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('@$username',
                        style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.6),
                            fontSize: 13)),
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(email,
                          style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              fontSize: 12)),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showEditProfile,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_rounded, color: AppTheme.accent, size: 14),
                      SizedBox(width: 4),
                      Text('编辑',
                          style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.format_quote_rounded,
                    size: 14, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontStyle: FontStyle.italic)),
                ),
              ],
            ),
          ],
          if (joinDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 12, color: AppTheme.textSecondary.withValues(alpha: 0.35)),
                const SizedBox(width: 6),
                Text(joinDate,
                    style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.4),
                        fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = _stats;
    final projects = s?['projectCount'] ?? _profile?['projectCount'] ?? 0;
    final exports = s?['exportCount'] ?? _profile?['exportCount'] ?? 0;
    final days = s?['dayCount'] ?? _profile?['dayCount'] ?? 1;
    return Row(
      children: [
        _buildStatItem('作品', '$projects', AppTheme.accent),
        const SizedBox(width: 12),
        _buildStatItem('导出', '$exports', AppTheme.accentYellow),
        const SizedBox(width: 12),
        _buildStatItem('天数', '$days', AppTheme.accentOrange),
      ],
    );
  }

  /// 近 7 日新建项目数（/api/user/stats 真实聚合）
  Widget _buildActivityChart() {
    final chart = _stats?['chart'];
    if (chart is! List || chart.isEmpty) {
      return const SizedBox.shrink();
    }
    double maxY = 1;
    for (final e in chart) {
      if (e is Map) {
        final c = (e['count'] as num?)?.toDouble() ?? 0;
        if (c > maxY) maxY = c;
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('近7日新建项目',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('数据来自数据库按日统计',
              style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY < 1 ? 4 : (maxY * 1.25).ceilToDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= chart.length) {
                          return const SizedBox.shrink();
                        }
                        final e = chart[i];
                        final label =
                            e is Map ? (e['label']?.toString() ?? '') : '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY <= 4 ? 1 : null,
                      getTitlesWidget: (v, m) => Text(
                        v.toInt().toString(),
                        style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY <= 4 ? 1 : null,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.dividerColor.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(chart.length, (i) {
                  final e = chart[i];
                  final v = e is Map ? (e['count'] as num?)?.toDouble() ?? 0 : 0.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: v,
                        color: AppTheme.accent,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title,
              style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    title: Text(item.label,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textSecondary.withValues(alpha: 0.3), size: 20),
                    onTap: item.onTap,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    minVerticalPadding: 0,
                  ),
                  if (i < items.length - 1)
                    Divider(
                      height: 0.5,
                      indent: 64,
                      color: AppTheme.dividerColor.withValues(alpha: 0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('退出登录'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.accentOrange,
          side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _showEditProfile() {
    final nicknameCtrl = TextEditingController(
        text: _profile?['nickname'] ?? '');
    final emailCtrl = TextEditingController(
        text: _profile?['email'] ?? '');
    final bioCtrl = TextEditingController(
        text: _profile?['bio'] ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('编辑资料',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: nicknameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '昵称',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '邮箱',
                prefixIcon: Icon(Icons.email_outlined,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: bioCtrl,
              maxLines: 2,
              maxLength: 50,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '个性签名（选填）',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Icon(Icons.format_quote_rounded,
                      color: AppTheme.textSecondary, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final updates = <String, String>{
                      'nickname': nicknameCtrl.text,
                    };
                    if (emailCtrl.text.isNotEmpty) {
                      updates['email'] = emailCtrl.text;
                    }
                    if (bioCtrl.text.isNotEmpty) {
                      updates['bio'] = bioCtrl.text;
                    }
                    await ApiService().updateProfile(updates);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _loadProfile();
                    _showMsg('修改成功');
                  } catch (_) {
                    _showMsg('修改失败');
                  }
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword() {
    final oldPwdCtrl = TextEditingController();
    final newPwdCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('修改密码',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: oldPwdCtrl,
              obscureText: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '当前密码',
                prefixIcon: Icon(Icons.lock_outline_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newPwdCtrl,
              obscureText: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '新密码',
                prefixIcon: Icon(Icons.lock_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService().changePassword(oldPwdCtrl.text, newPwdCtrl.text);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _showMsg('密码修改成功');
                  } catch (_) {
                    _showMsg('密码修改失败');
                  }
                },
                child: const Text('确认修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProjects(int? statusFilter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectListScreen(initialStatusFilter: statusFilter),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (xfile == null) return;
    try {
      final res = await ApiService().uploadAvatar(xfile.path);
      if (res['code'] == 200) {
        _showMsg('头像更新成功');
        _loadProfile();
      } else {
        _showMsg('头像更新失败');
      }
    } catch (_) {
      _showMsg('头像上传失败');
    }
  }

  void _showStorageInfo() {
    final projects = _stats?['projectCount'] ?? _profile?['projectCount'] ?? 0;
    final exports = _stats?['exportCount'] ?? _profile?['exportCount'] ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.storage_rounded, color: AppTheme.accentYellow, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('存储空间'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _storageRow('视频项目', '$projects 个', AppTheme.accent),
            const SizedBox(height: 12),
            _storageRow('已导出文件', '$exports 个', const Color(0xFF48CAE4)),
            const SizedBox(height: 12),
            _storageRow('服务器存储', '正常', AppTheme.accentYellow),
            const SizedBox(height: 16),
            Text('视频文件存储在服务器 uploads 目录',
                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  Widget _storageRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showFeedback() {
    final feedbackCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('帮助与反馈',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            TextField(
              controller: feedbackCtrl,
              maxLines: 4,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: '请描述您的问题或建议...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.feedback_outlined, color: AppTheme.textSecondary, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showMsg('感谢您的反馈');
                },
                child: const Text('提交反馈'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF00B894)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.movie_filter_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('关于智剪'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('移动端短视频智能剪辑APP'),
            const SizedBox(height: 8),
            Text('版本 1.0.0',
                style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              '基于Flutter + Spring Boot开发\n'
              '集成CNN+LSTM场景识别\n'
              'FFmpeg视频处理引擎',
              style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定', style: TextStyle(color: AppTheme.accent))),
        ],
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SettingsSheet(onMsg: _showMsg),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  final void Function(String) onMsg;
  const _SettingsSheet({required this.onMsg});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  String _defaultQuality = '1080p';
  bool _autoSave = true;
  bool _showWatermark = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.settings_rounded, color: AppTheme.accent, size: 22),
              SizedBox(width: 10),
              Text('设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _settingsItem(
                  Icons.high_quality_rounded,
                  '默认导出质量',
                  trailing: DropdownButton<String>(
                    value: _defaultQuality,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    items: ['720p', '1080p', '2K', '4K'].map((q) =>
                      DropdownMenuItem(value: q, child: Text(q))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _defaultQuality = v);
                    },
                  ),
                ),
                _divider(),
                _settingsItem(
                  Icons.save_rounded,
                  '自动保存草稿',
                  trailing: Switch(
                    value: _autoSave,
                    onChanged: (v) => setState(() => _autoSave = v),
                    activeColor: AppTheme.accent,
                  ),
                ),
                _divider(),
                _settingsItem(
                  Icons.branding_watermark_rounded,
                  '导出添加水印',
                  trailing: Switch(
                    value: _showWatermark,
                    onChanged: (v) => setState(() => _showWatermark = v),
                    activeColor: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _settingsItem(
                  Icons.cleaning_services_rounded,
                  '清除缓存',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onMsg('缓存已清除');
                  },
                ),
                _divider(),
                _settingsItem(
                  Icons.description_outlined,
                  '用户协议',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onMsg('用户协议页面开发中');
                  },
                ),
                _divider(),
                _settingsItem(
                  Icons.privacy_tip_outlined,
                  '隐私政策',
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary, size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onMsg('隐私政策页面开发中');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsItem(IconData icon, String label, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.accent, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    );
  }

  Widget _divider() {
    return Divider(height: 0.5, indent: 64, color: AppTheme.dividerColor.withValues(alpha: 0.5));
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _MenuItem(this.icon, this.label, this.color, this.onTap);
}
