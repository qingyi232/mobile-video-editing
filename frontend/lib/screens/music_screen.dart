import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  String _selectedCategory = '全部';
  String _selectedMood = '全部';
  List<dynamic> _musicList = [];
  bool _loading = true;
  int? _playingId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;

  final List<String> _categories = ['全部', 'nature', 'portrait', 'dynamic', 'festive', 'calm', 'energetic'];
  final List<Map<String, dynamic>> _moods = [
    {'label': '全部', 'icon': Icons.apps_rounded},
    {'label': 'happy', 'icon': Icons.sentiment_very_satisfied_rounded},
    {'label': 'relaxing', 'icon': Icons.spa_rounded},
    {'label': 'exciting', 'icon': Icons.local_fire_department_rounded},
    {'label': 'sad', 'icon': Icons.water_drop_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadMusic();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(dynamic music) async {
    final id = music['id'] as int?;
    final rawUrl = (music['fileUrl'] ?? music['file_url'] ?? '').toString();
    final url = rawUrl.isEmpty ? '' : ApiService.mediaUrlFromServerPath(rawUrl);

    if (_playingId == id && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      setState(() => _playingId = null);
      return;
    }

    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该音乐暂无可播放的音频文件')),
        );
      }
      return;
    }

    await _audioPlayer.stop();
    setState(() => _playingId = id);
    await _audioPlayer.play(UrlSource(url));
  }

  Future<void> _importLocalMusic() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    if (!mounted) return;
    final titleController = TextEditingController(text: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('导入本地音乐', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            labelText: '音乐名称',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('导入')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService().uploadMusic(
        filePath: file.path!,
        title: titleController.text.trim().isEmpty ? file.name : titleController.text.trim(),
      );
      await _loadMusic();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('音乐导入成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _loadMusic() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getAllMusic();
      if (res['code'] == 200) {
        setState(() {
          _musicList = res['data'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _musicList = [];
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredMusic {
    return _musicList.where((m) {
      final catMatch = _selectedCategory == '全部' || (m['category']?.toString() ?? '') == _selectedCategory;
      final moodMatch = _selectedMood == '全部' || (m['mood']?.toString() ?? '') == _selectedMood;
      return catMatch && moodMatch;
    }).toList();
  }

  String _formatDuration(num seconds) {
    final total = seconds.toInt();
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _labelCategory(String raw) {
    const map = {
      'nature': '风景',
      'portrait': '人物',
      'dynamic': '动态',
      'festive': '节日',
      'calm': '安静',
      'energetic': '动感',
    };
    return map[raw] ?? raw;
  }

  String _labelMood(String raw) {
    const map = {
      'happy': '欢快',
      'relaxing': '舒缓',
      'exciting': '激昂',
      'sad': '抒情',
    };
    return map[raw] ?? raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音乐库'),
        actions: [
          IconButton(
            tooltip: '导入本地音乐',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: _importLocalMusic,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          const SizedBox(height: 8),
          _buildMoodBar(),
          const SizedBox(height: 4),
          Expanded(
            child: _loading
                ? _buildSkeleton()
                : _filteredMusic.isEmpty
                    ? const Center(
                        child: Text('暂无音乐',
                            style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _filteredMusic.length,
                        itemBuilder: (_, i) =>
                            _buildMusicCard(_filteredMusic[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = _selectedCategory == _categories[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = _categories[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: selected
                    ? Border.all(color: AppTheme.accent.withValues(alpha: 0.5))
                    : null,
              ),
              child: Center(
                child: Text(
                  _labelCategory(_categories[i]),
                  style: TextStyle(
                    color: selected ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final m = _moods[i];
          final selected = _selectedMood == m['label'];
          return GestureDetector(
            onTap: () => setState(() => _selectedMood = m['label'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accentYellow.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(m['icon'] as IconData,
                      size: 14,
                      color: selected ? AppTheme.accentYellow : AppTheme.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    _labelMood((m['label'] as String)),
                    style: TextStyle(
                      color: selected ? AppTheme.accentYellow : AppTheme.textSecondary.withValues(alpha: 0.5),
                      fontSize: 12,
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildMusicCard(dynamic music) {
    final isPlaying = _playingId == music['id'];
    final moodColors = {
      'happy': AppTheme.accentYellow,
      'relaxing': AppTheme.accent,
      'exciting': AppTheme.accentOrange,
      'sad': const Color(0xFF48CAE4),
    };
    final moodRaw = (music['mood'] ?? '').toString();
    final moodColor = moodColors[moodRaw] ?? AppTheme.accent;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _togglePlay(music),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      moodColor.withValues(alpha: 0.25),
                      moodColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPlaying && _playerState == PlayerState.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: moodColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((music['title'] ?? music['name'] ?? '').toString(),
                        style: TextStyle(
                          color: isPlaying ? moodColor : AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(music['artist'] ?? '',
                            style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                fontSize: 12)),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatDuration((music['duration'] as num?) ?? 0),
                            style: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_labelMood(moodRaw),
                    style: TextStyle(color: moodColor, fontSize: 10)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: AppTheme.accent, size: 22),
                onPressed: () {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已选择音乐: ${(music['title'] ?? music['name'] ?? '').toString()}')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
