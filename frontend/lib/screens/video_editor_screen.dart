import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

class VideoEditorScreen extends StatefulWidget {
  final String projectName;
  final int? projectId;

  const VideoEditorScreen({
    super.key,
    required this.projectName,
    this.projectId,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  /// 后端可识别的素材路径（上传/处理后的路径）
  final List<String> _serverVideoPaths = [];
  final _api = ApiService();
  final Set<String> _loadingOps = {};
  String? _serverVideoPath;
  String? _appliedMusicPath;
  VideoPlayerController? _playerController;
  double _trimStart = 0;
  double _trimEnd = 10;
  double _volume = 1.0;
  String _selectedTransition = 'fade';
  double _transitionDuration = 1.0;
  String _selectedAspectRatio = '16:9';
  String _exportFormat = 'mp4';
  String? _selectedScene;
  /// 与后端 MusicRecommendRequest.sceneType 一致: nature/portrait/dynamic
  String? _sceneTypeApi;
  List<Map<String, dynamic>> _clarityResults = [];
  List<dynamic> _recommendedMusic = [];
  String _subtitleText = '';
  bool _voiceSeparated = false;
  List<Map<String, dynamic>> _editorTemplates = [];
  String _selectedFilter = 'none';
  bool _isSeeking = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProject();
      _loadTemplatesForEditor();
    });
  }

  Future<void> _loadTemplatesForEditor() async {
    try {
      final res = await _api.getAllTemplates();
      if (res['code'] != 200) return;
      final list = res['data'];
      if (list is List && mounted) {
        setState(() {
          _editorTemplates =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProject() async {
    final id = widget.projectId;
    if (id == null) return;
    try {
      final res = await _api.getProject(id);
      if (res['code'] != 200) return;
      final p = res['data'];
      if (p is! Map) return;
      final url = p['videoUrl']?.toString();
      if (url != null && url.isNotEmpty) {
        setState(() {
          _serverVideoPath = url;
          _serverVideoPaths
            ..clear()
            ..add(url);
        });
        await _initPlayerForPath(url);
      }
    } catch (_) {
      /* 离线或网络错误时仍可本地选片 */
    }
  }

  Future<void> _initPlayerForPath(String serverPath) async {
    _playerController?.removeListener(_onPlayerTick);
    await _playerController?.dispose();
    _playerController = null;
    final uri = Uri.parse(ApiService.mediaUrlFromServerPath(serverPath));
    final c = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await c.initialize();
      if (!mounted) return;
      setState(() {
        _playerController = c;
        _totalDuration = c.value.duration;
        _currentPosition = Duration.zero;
      });
      c.addListener(_onPlayerTick);
      await c.setLooping(true);
      await c.setVolume(1.0);
      await c.play();
    } catch (_) {
      await c.dispose();
    }
  }

  void _onPlayerTick() {
    if (!mounted || _isSeeking) return;
    final ctrl = _playerController;
    if (ctrl == null) return;
    setState(() {
      _currentPosition = ctrl.value.position;
      _totalDuration = ctrl.value.duration;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// 处理完成后更新当前主素材、片段列表并写回数据库
  Future<void> _applyOutputPath({
    required String newPath,
    required bool replaceAllSegments,
    String? replaceOldPath,
  }) async {
    final old = replaceOldPath ?? _serverVideoPath;
    setState(() {
      if (replaceAllSegments) {
        _serverVideoPaths
          ..clear()
          ..add(newPath);
      } else if (_serverVideoPaths.isEmpty) {
        _serverVideoPaths.add(newPath);
      } else if (old != null) {
        final i = _serverVideoPaths.indexOf(old);
        if (i >= 0) {
          _serverVideoPaths[i] = newPath;
        } else {
          _serverVideoPaths.add(newPath);
        }
      } else {
        _serverVideoPaths.add(newPath);
      }
      _serverVideoPath = newPath;
    });
    final pid = widget.projectId;
    if (pid != null) {
      try {
        await _api.updateProject(pid, {'videoUrl': newPath});
      } catch (_) {}
    }
    await _initPlayerForPath(newPath);
  }

  String? _outputPathFromResponse(Map<String, dynamic> res) {
    final d = res['data'];
    if (d is Map && d['outputPath'] != null) {
      return d['outputPath'].toString();
    }
    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _playerController?.removeListener(_onPlayerTick);
    _playerController?.dispose();
    super.dispose();
  }

  bool _isLoading(String op) => _loadingOps.contains(op);
  bool get _anyLoading => _loadingOps.isNotEmpty;

  void _startLoading(String op) => setState(() => _loadingOps.add(op));
  void _stopLoading(String op) => setState(() => _loadingOps.remove(op));

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isError ? AppTheme.accentOrange : AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
    ));
  }

  Future<void> _importVideo({required ImageSource source}) async {
    final pid = widget.projectId;
    if (pid == null) {
      _showMsg('请从首页「新建项目」进入后再导入视频，以便同步到数据库', isError: true);
      return;
    }

    String? filePath;
    if (source == ImageSource.gallery) {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result == null || result.files.single.path == null) return;
      filePath = result.files.single.path;
    } else {
      final picker = ImagePicker();
      final xfile = await picker.pickVideo(source: source);
      if (xfile == null) return;
      filePath = xfile.path;
    }
    final file = XFile(filePath!);
    _startLoading('import');
    try {
      final res = await _api.uploadVideo(file.path, projectId: pid);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '上传失败', isError: true);
        return;
      }
      final data = res['data'];
      final path = data is Map ? data['path']?.toString() : null;
      if (path == null || path.isEmpty) {
        _showMsg('服务器未返回视频路径', isError: true);
        return;
      }
      setState(() {
        _serverVideoPaths.add(path);
        _serverVideoPath = path;
      });
      if (widget.projectId != null) {
        await _api.updateProject(widget.projectId!, {'videoUrl': path});
      }
      await _initPlayerForPath(path);
      if (!mounted) return;
      _showMsg('已上传并写入项目');
    } catch (e) {
      _showMsg('上传失败: $e', isError: true);
    } finally {
      if (mounted) _stopLoading('import');
    }
  }

  Future<void> _trimVideo() async {
    final path = _serverVideoPath;
    if (path == null) {
      _showMsg('请先导入视频', isError: true);
      return;
    }
    _startLoading('trim');
    try {
      final res = await _api.trimVideo(path, _trimStart, _trimEnd);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '裁剪失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(
            newPath: out, replaceAllSegments: false, replaceOldPath: path);
      }
      _showMsg('裁剪完成');
    } catch (_) {
      _showMsg('裁剪失败', isError: true);
    } finally {
      if (mounted) _stopLoading('trim');
    }
  }

  Future<void> _concatVideos() async {
    if (_serverVideoPaths.length < 2) {
      _showMsg('至少上传 2 段视频到服务器后再拼接', isError: true);
      return;
    }
    _startLoading('concat');
    try {
      final res = await _api.concatVideos(List<String>.from(_serverVideoPaths));
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '拼接失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(newPath: out, replaceAllSegments: true);
      }
      _showMsg('拼接完成');
    } catch (_) {
      _showMsg('拼接失败', isError: true);
    } finally {
      if (mounted) _stopLoading('concat');
    }
  }

  Future<void> _addTransition() async {
    if (_serverVideoPaths.length < 2) {
      _showMsg('至少需要 2 段已上传视频', isError: true);
      return;
    }
    _startLoading('transition');
    try {
      final two = _serverVideoPaths.take(2).toList();
      final res = await _api.addTransition(two, _selectedTransition);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '转场失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(newPath: out, replaceAllSegments: true);
      }
      _showMsg('转场添加完成');
    } catch (_) {
      _showMsg('转场添加失败', isError: true);
    } finally {
      if (mounted) _stopLoading('transition');
    }
  }

  Future<void> _addFirstMusicFromLibrary() async {
    _startLoading('addMusic');
    try {
      final res = await _api.getAllMusic();
      if (res['code'] != 200) {
        _showMsg('拉取音乐库失败', isError: true);
        return;
      }
      final list = res['data'];
      if (list is! List || list.isEmpty) {
        _showMsg('音乐库为空，请先在音乐库页面导入音乐', isError: true);
        return;
      }
      if (mounted) _stopLoading('addMusic');
      if (!mounted) return;
      final selected = await _showMusicPicker(list);
      if (selected == null) return;
      await _addMusic(selected);
      return;
    } catch (e) {
      _showMsg('加载音乐失败: $e', isError: true);
    } finally {
      if (mounted) _stopLoading('addMusic');
    }
  }

  Future<String?> _showMusicPicker(List<dynamic> musicList) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.library_music_rounded, color: AppTheme.accent, size: 22),
                  const SizedBox(width: 10),
                  const Text('选择背景音乐',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${musicList.length} 首',
                      style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: musicList.length,
                itemBuilder: (_, i) {
                  final m = musicList[i];
                  if (m is! Map) return const SizedBox.shrink();
                  final title = (m['title'] ?? m['name'] ?? '未知').toString();
                  final artist = (m['artist'] ?? '').toString();
                  final mood = (m['mood'] ?? '').toString();
                  final duration = (m['duration'] as num?)?.toDouble() ?? 0;
                  return ListTile(
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.accent.withValues(alpha: 0.2),
                          AppTheme.accent.withValues(alpha: 0.05),
                        ]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: AppTheme.accent, size: 20),
                    ),
                    title: Text(title,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: Text(
                      [if (artist.isNotEmpty) artist, if (mood.isNotEmpty) mood, if (duration > 0) '${duration.toInt()}s']
                          .join(' · '),
                      style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12),
                    ),
                    trailing: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.accent, size: 22),
                    onTap: () {
                      final url = (m['fileUrl'] ?? m['file_url'] ?? '').toString();
                      if (url.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('该音乐缺少文件路径')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, url);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMusic(String musicPath) async {
    final path = _serverVideoPath;
    if (path == null) return;
    _startLoading('addMusic');
    try {
      final res = await _api.addMusic(path, musicPath, _volume);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '添加音乐失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(
            newPath: out, replaceAllSegments: false, replaceOldPath: path);
        setState(() => _appliedMusicPath = musicPath);
      }
      _showMsg('背景音乐添加成功');
    } catch (_) {
      _showMsg('添加失败（请确认服务器 uploads/music 下存在对应文件）', isError: true);
    } finally {
      if (mounted) _stopLoading('addMusic');
    }
  }

  Future<void> _removeMusic() async {
    final path = _serverVideoPath;
    if (path == null || _appliedMusicPath == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.music_off_rounded, color: AppTheme.accentOrange, size: 22),
            SizedBox(width: 10),
            Text('取消背景音乐'),
          ],
        ),
        content: const Text('确定要移除当前已应用的背景音乐吗？视频将恢复为无背景音乐状态。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('保留', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认取消', style: TextStyle(color: AppTheme.accentOrange)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _startLoading('removeMusic');
    try {
      final res = await _api.addMusic(path, _appliedMusicPath!, 0.0);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '取消音乐失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(
            newPath: out, replaceAllSegments: false, replaceOldPath: path);
      }
      setState(() {
        _appliedMusicPath = null;
        _volume = 1.0;
      });
      _showMsg('已取消背景音乐');
    } catch (_) {
      _showMsg('取消音乐失败', isError: true);
    } finally {
      if (mounted) _stopLoading('removeMusic');
    }
  }

  Future<void> _separateVoice() async {
    final path = _serverVideoPath;
    if (path == null) return;
    _startLoading('voice');
    try {
      final res = await _api.separateVoice(path);
      if (res['code'] == 200) {
        setState(() => _voiceSeparated = true);
      }
      _showMsg('人声分离完成（人声/背景音文件已生成在服务器）');
    } catch (_) {
      _showMsg('人声分离失败', isError: true);
    } finally {
      if (mounted) _stopLoading('voice');
    }
  }

  Future<void> _recognizeScene() async {
    final path = _serverVideoPath;
    if (path == null) {
      _showMsg('请先导入视频', isError: true);
      return;
    }
    _startLoading('scene');
    try {
      final res = await _api.recognizeScene(path);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '识别失败', isError: true);
        return;
      }
      final data = res['data'];
      if (data is Map) {
        setState(() {
          _selectedScene = data['sceneLabel']?.toString();
          _sceneTypeApi = data['sceneType']?.toString();
        });
      }
      _showMsg('场景识别完成: ${_selectedScene ?? "未知"}，正在自动推荐配乐…');
      if (mounted) {
        _stopLoading('scene');
        await _recommendMusic();
        return;
      }
    } catch (_) {
      _showMsg('场景识别失败', isError: true);
    } finally {
      if (mounted) _stopLoading('scene');
    }
  }

  Future<void> _analyzeClarity() async {
    final path = _serverVideoPath;
    if (path == null) return;
    _startLoading('clarity');
    try {
      final res = await _api.analyzeClarity(path);
      if (res['code'] == 200) {
        final data = res['data'];
        if (data is List) {
          setState(() {
            _clarityResults = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          });
        }
      }
      _showMsg('清晰度分析完成');
    } catch (_) {
      _showMsg('分析失败', isError: true);
    } finally {
      if (mounted) _stopLoading('clarity');
    }
  }

  /// 智能片段筛选：自动裁剪保留高清晰度片段并拼接
  Future<void> _smartClip() async {
    final path = _serverVideoPath;
    if (path == null) {
      _showMsg('请先导入视频', isError: true);
      return;
    }
    _startLoading('smartClip');
    try {
      final res = await _api.smartClip(path, sampleCount: 10, threshold: 60);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '智能筛选失败', isError: true);
        return;
      }
      final data = res['data'];
      if (data is Map) {
        final out = data['outputPath']?.toString();
        final kept = data['keptSegments'] ?? 0;
        final total = data['totalSegments'] ?? 0;
        if (out != null) {
          await _applyOutputPath(newPath: out, replaceAllSegments: true);
        }
        _showMsg('智能筛选完成：保留 $kept/$total 个高质量片段');
      }
    } catch (e) {
      _showMsg('智能筛选失败: $e', isError: true);
    } finally {
      if (mounted) _stopLoading('smartClip');
    }
  }

  /// 字幕烧录到视频
  Future<void> _burnSubtitle() async {
    final path = _serverVideoPath;
    if (path == null) {
      _showMsg('请先导入视频', isError: true);
      return;
    }
    if (_subtitleText.isEmpty) {
      _showMsg('请先生成字幕', isError: true);
      return;
    }
    _startLoading('burnSub');
    try {
      final res = await _api.burnSubtitle(path, _subtitleText);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '字幕烧录失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(
            newPath: out, replaceAllSegments: false, replaceOldPath: path);
      }
      _showMsg('字幕已烧录到视频');
    } catch (e) {
      _showMsg('字幕烧录失败: $e', isError: true);
    } finally {
      if (mounted) _stopLoading('burnSub');
    }
  }

  /// 应用滤镜
  Future<void> _applyFilter() async {
    final path = _serverVideoPath;
    if (path == null) {
      _showMsg('请先导入视频', isError: true);
      return;
    }
    if (_selectedFilter == 'none') {
      _showMsg('请选择一个滤镜', isError: true);
      return;
    }
    _startLoading('filter');
    try {
      final res = await _api.applyFilter(path, _selectedFilter);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '滤镜应用失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(
            newPath: out, replaceAllSegments: false, replaceOldPath: path);
      }
      _showMsg('滤镜「$_selectedFilter」已应用');
    } catch (e) {
      _showMsg('滤镜应用失败: $e', isError: true);
    } finally {
      if (mounted) _stopLoading('filter');
    }
  }

  Future<void> _recommendMusic() async {
    _startLoading('recommend');
    try {
      final res = await _api.recommendMusic(
        sceneType: _sceneTypeApi ?? 'nature',
        videoDuration: _trimEnd - _trimStart,
      );
      if (res['code'] == 200) {
        setState(() {
          _recommendedMusic = res['data'] ?? [];
        });
      }
      if (!mounted) return;
      _showMsg('推荐${_recommendedMusic.length}首音乐（数据库）');
    } catch (_) {
      _showMsg('推荐失败', isError: true);
    } finally {
      if (mounted) _stopLoading('recommend');
    }
  }

  Future<void> _generateSubtitle() async {
    final path = _serverVideoPath;
    if (path == null) return;
    _startLoading('subtitle');
    try {
      final res = await _api.generateSubtitle(path);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '字幕生成失败', isError: true);
        return;
      }
      final data = res['data'];
      if (data is Map && data['subtitleText'] != null) {
        setState(() => _subtitleText = data['subtitleText'].toString());
      }
      _showMsg('字幕生成完成');
    } catch (_) {
      _showMsg('字幕生成失败', isError: true);
    } finally {
      if (mounted) _stopLoading('subtitle');
    }
  }

  Future<void> _changeAspectRatio() async {
    final path = _serverVideoPath;
    if (path == null) return;
    _startLoading('ratio');
    try {
      final res = await _api.changeRatio(path, _selectedAspectRatio);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '比例切换失败', isError: true);
        return;
      }
      final out = _outputPathFromResponse(res);
      if (out != null) {
        await _applyOutputPath(
            newPath: out, replaceAllSegments: false, replaceOldPath: path);
      }
      if (widget.projectId != null) {
        await _api.updateProject(widget.projectId!, {'aspectRatio': _selectedAspectRatio});
      }
      _showMsg('画面比例已切换为 $_selectedAspectRatio');
    } catch (_) {
      _showMsg('切换失败', isError: true);
    } finally {
      if (mounted) _stopLoading('ratio');
    }
  }

  Future<void> _exportVideo() async {
    final pid = widget.projectId;
    if (pid == null) {
      _showMsg('缺少项目 ID，请从首页新建项目进入', isError: true);
      return;
    }
    if (_serverVideoPath == null) {
      _showMsg('请先上传视频到服务器', isError: true);
      return;
    }
    _startLoading('export');
    try {
      final res = await _api.exportVideo(pid, _exportFormat);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '导出失败', isError: true);
        return;
      }
      _showMsg('导出成功！格式: $_exportFormat（项目状态已更新为已导出）');
    } catch (e) {
      _showMsg('导出失败: $e', isError: true);
    } finally {
      if (mounted) _stopLoading('export');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_anyLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.accent),
                ),
              ),
            ),
          TextButton(
            onPressed: _isLoading('export') ? null : _exportVideo,
            child: const Text('导出', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: const [
            Tab(text: '基础编辑'),
            Tab(text: '音频'),
            Tab(text: '智能辅助'),
            Tab(text: '模板导出'),
            Tab(text: '字幕'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPreviewArea(),
          if (_serverVideoPaths.isNotEmpty) _buildTimeline(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicEditTab(),
                _buildAudioTab(),
                _buildSmartTab(),
                _buildExportTab(),
                _buildSubtitleTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    final hasVideo = _serverVideoPath != null;
    final ctrl = _playerController;
    return Container(
      height: 220,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasVideo
          ? Stack(
              fit: StackFit.expand,
              children: [
                if (ctrl != null && ctrl.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: ctrl.value.size.width,
                      height: ctrl.value.size.height,
                      child: VideoPlayer(ctrl),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.accent),
                  ),
                if (ctrl != null && ctrl.value.isInitialized)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(
                                  ctrl.value.isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                onPressed: () {
                                  if (ctrl.value.isPlaying) {
                                    ctrl.pause();
                                  } else {
                                    ctrl.play();
                                  }
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  _formatDuration(_currentPosition),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: AppTheme.accent,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: AppTheme.accent,
                                    overlayColor: AppTheme.accent.withValues(alpha: 0.2),
                                  ),
                                  child: Slider(
                                    value: _totalDuration.inMilliseconds > 0
                                        ? _currentPosition.inMilliseconds
                                            .toDouble()
                                            .clamp(0, _totalDuration.inMilliseconds.toDouble())
                                        : 0,
                                    min: 0,
                                    max: _totalDuration.inMilliseconds > 0
                                        ? _totalDuration.inMilliseconds.toDouble()
                                        : 1,
                                    onChangeStart: (_) => _isSeeking = true,
                                    onChanged: (v) {
                                      setState(() {
                                        _currentPosition = Duration(milliseconds: v.toInt());
                                      });
                                    },
                                    onChangeEnd: (v) {
                                      ctrl.seekTo(Duration(milliseconds: v.toInt()));
                                      _isSeeking = false;
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  _formatDuration(_totalDuration),
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedAspectRatio,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
                if (_selectedScene != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedScene!,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_call_rounded,
                      size: 44, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                  const SizedBox(height: 10),
                  Text('点击导入视频开始编辑',
                      style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          fontSize: 13)),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _serverVideoPaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final selected = _serverVideoPaths[i] == _serverVideoPath;
          return GestureDetector(
            onTap: () async {
              final p = _serverVideoPaths[i];
              setState(() => _serverVideoPath = p);
              await _initPlayerForPath(p);
              if (widget.projectId != null) {
                try {
                  await _api.updateProject(widget.projectId!, {'videoUrl': p});
                } catch (_) {}
              }
            },
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: AppTheme.accent, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '片段 ${i + 1}',
                  style: TextStyle(
                    color: selected ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 12,
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

  Widget _buildBasicEditTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('导入视频', Icons.file_upload_outlined),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildToolButton(
                icon: Icons.photo_library_outlined,
                label: '相册选择',
                onTap: _isLoading('import') ? () {} : () => _importVideo(source: ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToolButton(
                icon: Icons.videocam_outlined,
                label: '拍摄',
                onTap: _isLoading('import') ? () {} : () => _importVideo(source: ImageSource.camera),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('片段裁剪', Icons.content_cut_rounded),
        const SizedBox(height: 10),
        _buildSliderRow('起始 ${_trimStart.toStringAsFixed(1)}s', _trimStart, 0, _trimEnd,
            (v) => setState(() => _trimStart = v)),
        _buildSliderRow('结束 ${_trimEnd.toStringAsFixed(1)}s', _trimEnd, _trimStart, 60,
            (v) => setState(() => _trimEnd = v)),
        const SizedBox(height: 10),
        _buildActionButton('裁剪视频', Icons.content_cut_rounded, _trimVideo, opKey: 'trim'),
        const SizedBox(height: 24),
        _buildSectionTitle('视频拼接', Icons.merge_rounded),
        const SizedBox(height: 10),
        _buildInfoRow('已上传片段（服务器）', '${_serverVideoPaths.length} 个'),
        const SizedBox(height: 10),
        _buildActionButton('拼接视频', Icons.merge_rounded, _concatVideos, opKey: 'concat'),
        const SizedBox(height: 24),
        _buildSectionTitle('转场效果', Icons.animation_rounded),
        const SizedBox(height: 10),
        _buildTransitionPicker(),
        const SizedBox(height: 10),
        _buildActionButton('添加转场', Icons.animation_rounded, _addTransition, opKey: 'transition'),
      ],
    );
  }

  Widget _buildAudioTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('背景音乐', Icons.music_note_rounded),
        const SizedBox(height: 10),
        if (_appliedMusicPath != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.accent.withValues(alpha: 0.2),
                          AppTheme.accent.withValues(alpha: 0.05),
                        ]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: AppTheme.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('已应用背景音乐',
                              style: TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('拖动下方滑块调节音量',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isLoading('removeMusic') ? null : _removeMusic,
                      icon: _isLoading('removeMusic')
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange))
                          : const Icon(Icons.close_rounded, size: 16),
                      label: const Text('取消'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.accentOrange),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: AppTheme.accent, size: 20,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          activeTrackColor: AppTheme.accent,
                          inactiveTrackColor: AppTheme.accent.withValues(alpha: 0.15),
                          thumbColor: AppTheme.accent,
                          overlayColor: AppTheme.accent.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: _volume.clamp(0, 1.5),
                          min: 0,
                          max: 1.5,
                          onChanged: (v) => setState(() => _volume = v),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${(_volume * 100).toInt()}%',
                        style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                Icon(Icons.music_off_rounded,
                    size: 32, color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text('暂未添加背景音乐',
                    style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 13)),
                const SizedBox(height: 4),
                Text('从音乐库或推荐中选择添加',
                    style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.35), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        _buildActionButton(
            '从音乐库添加', Icons.library_music_rounded, _addFirstMusicFromLibrary, opKey: 'addMusic'),
        if (_recommendedMusic.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('推荐的音乐',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._recommendedMusic.map((m) => _buildMusicItem(m)),
        ],
        const SizedBox(height: 28),
        _buildSectionTitle('人声分离', Icons.record_voice_over_rounded),
        const SizedBox(height: 10),
        _buildInfoRow('状态', _voiceSeparated ? '已分离' : '未分离'),
        const SizedBox(height: 10),
        _buildActionButton(
            _voiceSeparated ? '已完成' : '开始分离',
            Icons.graphic_eq_rounded,
            _voiceSeparated ? null : _separateVoice,
            completed: _voiceSeparated,
            opKey: 'voice'),
      ],
    );
  }

  Widget _buildSmartTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('CNN+LSTM 场景识别', Icons.auto_awesome_rounded),
        const SizedBox(height: 6),
        Text('基于卷积神经网络与长短期记忆网络的智能场景分类',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        if (_selectedScene != null)
          _buildResultCard('识别结果', _selectedScene!, Icons.landscape_rounded),
        _buildActionButton('开始识别', Icons.auto_awesome_rounded, _recognizeScene, opKey: 'scene'),
        const SizedBox(height: 28),
        _buildSectionTitle('智能片段筛选', Icons.auto_fix_high_rounded),
        const SizedBox(height: 6),
        Text('基于帧清晰度分析自动筛选高质量片段',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        if (_clarityResults.isNotEmpty) ...[
          ..._clarityResults.map((r) => _buildClarityItem(r)),
          const SizedBox(height: 8),
        ],
        _buildActionButton('分析清晰度', Icons.auto_fix_high_rounded, _analyzeClarity, opKey: 'clarity'),
        const SizedBox(height: 10),
        _buildActionButton('一键保留高质量片段', Icons.auto_awesome_motion_rounded, _smartClip, opKey: 'smartClip'),
        const SizedBox(height: 28),
        _buildSectionTitle('智能配乐推荐', Icons.queue_music_rounded),
        const SizedBox(height: 6),
        Text('根据场景类型与视频时长智能推荐背景音乐',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.6))),
        const SizedBox(height: 12),
        _buildActionButton('获取推荐', Icons.queue_music_rounded, _recommendMusic, opKey: 'recommend'),
        if (_recommendedMusic.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._recommendedMusic.map((m) => _buildMusicItem(m)),
        ],
      ],
    );
  }

  Widget _buildExportTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('预设模板', Icons.dashboard_customize_rounded),
        const SizedBox(height: 10),
        _buildTemplateGrid(),
        const SizedBox(height: 28),
        _buildSectionTitle('滤镜效果', Icons.filter_vintage_rounded),
        const SizedBox(height: 10),
        _buildFilterPicker(),
        const SizedBox(height: 10),
        _buildActionButton('应用滤镜', Icons.filter_vintage_rounded, _applyFilter, opKey: 'filter'),
        const SizedBox(height: 28),
        _buildSectionTitle('画面比例', Icons.aspect_ratio_rounded),
        const SizedBox(height: 10),
        _buildRatioPicker(),
        const SizedBox(height: 10),
        _buildActionButton('切换比例', Icons.aspect_ratio_rounded, _changeAspectRatio, opKey: 'ratio'),
        const SizedBox(height: 28),
        _buildSectionTitle('导出设置', Icons.download_rounded),
        const SizedBox(height: 10),
        _buildFormatPicker(),
        const SizedBox(height: 16),
        _buildExportButton(),
      ],
    );
  }

  Widget _buildSubtitleTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('语音识别自动字幕', Icons.subtitles_rounded),
        const SizedBox(height: 6),
        Text('基于语音识别技术自动生成视频字幕',
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.6))),
        const SizedBox(height: 16),
        _buildActionButton('生成字幕', Icons.subtitles_rounded, _generateSubtitle, opKey: 'subtitle'),
        if (_subtitleText.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildActionButton('烧录字幕到视频', Icons.closed_caption_rounded, _burnSubtitle, opKey: 'burnSub'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.text_fields_rounded, color: AppTheme.accent, size: 18),
                    SizedBox(width: 8),
                    Text('生成的字幕',
                        style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_subtitleText,
                    style: const TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14, height: 1.8)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.accent, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style:
                      const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(
      String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback? onTap,
      {bool completed = false, String? opKey}) {
    final busy = opKey != null && _isLoading(opKey);
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: completed
          ? OutlinedButton.icon(
              onPressed: null,
              icon: Icon(Icons.check_circle_rounded,
                  color: AppTheme.accent.withValues(alpha: 0.5), size: 18),
              label: Text(label,
                  style: TextStyle(color: AppTheme.accent.withValues(alpha: 0.5))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
              ),
            )
          : FilledButton.icon(
              onPressed: (busy || onTap == null) ? null : onTap,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(icon, size: 18),
              label: Text(label),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildResultCard(String label, String result, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.12),
            AppTheme.accent.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(result,
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionPicker() {
    final transitions = [
      {'id': 'fade', 'label': '淡入淡出', 'icon': Icons.blur_on_rounded, 'desc': '画面渐隐渐现，柔和过渡', 'scene': '适合抒情、安静场景'},
      {'id': 'slide', 'label': '滑动', 'icon': Icons.swap_horiz_rounded, 'desc': '画面左右滑入切换', 'scene': '适合 Vlog、旅行场景'},
      {'id': 'zoom', 'label': '缩放', 'icon': Icons.zoom_in_rounded, 'desc': '画面由小放大过渡', 'scene': '适合节日、聚焦场景'},
      {'id': 'rotate', 'label': '旋转', 'icon': Icons.rotate_right_rounded, 'desc': '画面旋转切换场景', 'scene': '适合动感、创意场景'},
      {'id': 'wipe', 'label': '擦除', 'icon': Icons.cleaning_services_rounded, 'desc': '画面逐渐擦除过渡', 'scene': '适合教程、演示场景'},
    ];
    final selectedInfo = transitions.firstWhere(
        (t) => t['id'] == _selectedTransition,
        orElse: () => transitions.first);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: transitions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final t = transitions[i];
              final selected = _selectedTransition == t['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedTransition = t['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 78,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        selected ? Border.all(color: AppTheme.accent, width: 1.5) : null,
                    boxShadow: selected
                        ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(t['icon'] as IconData,
                            size: 24,
                            color: selected ? AppTheme.accent : AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(t['label'] as String,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? AppTheme.accent : AppTheme.textSecondary,
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(selectedInfo['icon'] as IconData,
                      size: 16, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedInfo['label']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${selectedInfo['desc']}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedInfo['scene']}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSliderRow(
          '转场时长 ${_transitionDuration.toStringAsFixed(1)}s',
          _transitionDuration, 0.3, 3.0,
          (v) => setState(() => _transitionDuration = v),
        ),
      ],
    );
  }

  Widget _buildFilterPicker() {
    final filters = [
      {'id': 'none', 'label': '无', 'icon': Icons.block_rounded},
      {'id': 'warm', 'label': '暖色', 'icon': Icons.wb_sunny_rounded},
      {'id': 'cool', 'label': '冷色', 'icon': Icons.ac_unit_rounded},
      {'id': 'vintage', 'label': '复古', 'icon': Icons.filter_vintage_rounded},
      {'id': 'bw', 'label': '黑白', 'icon': Icons.monochrome_photos_rounded},
      {'id': 'bright', 'label': '明亮', 'icon': Icons.brightness_high_rounded},
      {'id': 'film', 'label': '胶片', 'icon': Icons.camera_roll_rounded},
    ];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = filters[i];
          final selected = _selectedFilter == f['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['id'] as String),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border:
                    selected ? Border.all(color: AppTheme.accent, width: 1.5) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f['icon'] as IconData,
                      size: 22,
                      color: selected ? AppTheme.accent : AppTheme.textSecondary),
                  const SizedBox(height: 4),
                  Text(f['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? AppTheme.accent : AppTheme.textSecondary,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatioPicker() {
    final ratios = ['16:9', '9:16', '1:1', '4:3', '3:4'];
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: ratios.map((r) {
        final selected = _selectedAspectRatio == r;
        return ChoiceChip(
          label: Text(r),
          selected: selected,
          onSelected: (_) => setState(() => _selectedAspectRatio = r),
          selectedColor: AppTheme.accent.withValues(alpha: 0.2),
          labelStyle:
              TextStyle(color: selected ? AppTheme.accent : AppTheme.textSecondary),
          side: BorderSide(
              color: selected ? AppTheme.accent : AppTheme.dividerColor),
          checkmarkColor: AppTheme.accent,
        );
      }).toList(),
    );
  }

  Widget _buildFormatPicker() {
    return Row(
      children: ['mp4', 'avi'].map((f) {
        final selected = _exportFormat == f;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _exportFormat = f),
            child: Container(
              margin: EdgeInsets.only(right: f == 'mp4' ? 8 : 0, left: f == 'avi' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color:
                    selected ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border:
                    selected ? Border.all(color: AppTheme.accent, width: 1.5) : null,
              ),
              child: Center(
                child: Text(
                  f.toUpperCase(),
                  style: TextStyle(
                    color: selected ? AppTheme.accent : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.accent, Color(0xFF00B894)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading('export') ? null : _exportVideo,
        icon: const Icon(Icons.download_rounded, size: 20),
        label: Text('导出 ${_exportFormat.toUpperCase()} 视频'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  (IconData, Color) _templateStyle(String? category) {
    switch (category) {
      case 'festival':
        return (Icons.celebration_rounded, AppTheme.accentOrange);
      case 'vlog':
        return (Icons.flight_rounded, AppTheme.accent);
      case 'tutorial':
        return (Icons.school_rounded, const Color(0xFF6C63FF));
      default:
        return (Icons.movie_filter_rounded, AppTheme.accentYellow);
    }
  }

  Future<void> _applyDbTemplate(Map<String, dynamic> t) async {
    final id = (t['id'] as num?)?.toInt();
    if (id == null) return;
    _startLoading('template');
    try {
      final res = await _api.useTemplate(id);
      if (res['code'] != 200) {
        _showMsg(res['message']?.toString() ?? '应用失败', isError: true);
        return;
      }
      final pid = widget.projectId;
      if (pid != null) {
        final ar = t['aspectRatio']?.toString();
        await _api.updateProject(pid, {
          'templateId': id,
          if (ar != null) 'aspectRatio': ar,
        });
        if (ar != null) {
          setState(() => _selectedAspectRatio = ar);
        }
      }
      // 根据模板类别自动设置转场和滤镜
      final cat = t['category']?.toString();
      setState(() {
        switch (cat) {
          case 'festival':
            _selectedTransition = 'zoom';
            _selectedFilter = 'warm';
            break;
          case 'vlog':
            _selectedTransition = 'slide';
            _selectedFilter = 'film';
            break;
          case 'tutorial':
            _selectedTransition = 'fade';
            _selectedFilter = 'bright';
            break;
          default:
            _selectedTransition = 'fade';
            _selectedFilter = 'none';
        }
      });
      _showMsg('已应用模板「${t['name']}」，转场=$_selectedTransition 滤镜=$_selectedFilter');
    } catch (_) {
      _showMsg('应用模板失败', isError: true);
    } finally {
      if (mounted) _stopLoading('template');
    }
  }

  static const _templateEffectMap = {
    'festival': {'transition': '缩放过渡', 'filter': '暖色调', 'style': '喜庆热闹'},
    'vlog': {'transition': '滑动切换', 'filter': '胶片质感', 'style': '自然清新'},
    'tutorial': {'transition': '淡入淡出', 'filter': '明亮通透', 'style': '简洁明了'},
  };

  void _showEditorTemplateDetail(Map<String, dynamic> t) {
    final cat = t['category']?.toString() ?? '';
    final style = _templateStyle(cat);
    final effect = _templateEffectMap[cat] ?? {'transition': '淡入淡出', 'filter': '无', 'style': '通用风格'};
    final desc = t['description']?.toString() ?? '暂无描述';
    final ratio = t['aspectRatio']?.toString() ?? '16:9';

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
                    color: style.$2.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.$1, color: style.$2, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['name']?.toString() ?? '',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(effect['style']!,
                          style: TextStyle(color: style.$2, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(desc, style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7), fontSize: 14, height: 1.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.animation_rounded, '转场效果', effect['transition']!),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.filter_vintage_rounded, '滤镜风格', effect['filter']!),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.aspect_ratio_rounded, '画面比例', ratio),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.download_rounded, '使用次数', '${t['usageCount'] ?? 0} 次'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading('template')
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _applyDbTemplate(t);
                      },
                icon: _isLoading('template')
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_rounded, size: 18),
                label: const Text('应用此模板'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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

  Widget _buildTemplateGrid() {
    if (_editorTemplates.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('正在加载模板…',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: _editorTemplates.length,
      itemBuilder: (_, i) {
        final t = _editorTemplates[i];
        final cat = t['category']?.toString() ?? '';
        final style = _templateStyle(cat);
        final effect = _templateEffectMap[cat] ?? {'transition': '淡入淡出', 'filter': '无', 'style': '通用风格'};
        return Material(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showEditorTemplateDetail(t),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: style.$2.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(style.$1, color: style.$2, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t['name']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${effect['transition']} · ${effect['filter']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    effect['style'] ?? '',
                    style: TextStyle(
                      color: style.$2.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClarityItem(Map<String, dynamic> item) {
    final clarity = (item['clarity'] as num?)?.toDouble() ?? 0;
    final isGood = clarity >= 70;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isGood
                  ? AppTheme.accent.withValues(alpha: 0.15)
                  : AppTheme.accentOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGood ? Icons.hd_rounded : Icons.sd_rounded,
              color: isGood ? AppTheme.accent : AppTheme.accentOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('片段 ${item['segment'] ?? ''}',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('${item['start'] ?? 0}s - ${item['end'] ?? 0}s',
                    style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGood
                  ? AppTheme.accent.withValues(alpha: 0.1)
                  : AppTheme.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${clarity.toStringAsFixed(0)}分',
              style: TextStyle(
                color: isGood ? AppTheme.accent : AppTheme.accentOrange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicItem(dynamic music) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.2),
                  AppTheme.accent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note_rounded, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(music['name'] ?? music['title'] ?? '',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                if (music['artist'] != null)
                  Text(music['artist'],
                      style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.accent, size: 22),
            onPressed: () {
              final url = music['fileUrl'] ?? music['path'] ?? music['filePath'];
              if (url == null || url.toString().isEmpty) {
                _showMsg('该音乐缺少 fileUrl', isError: true);
                return;
              }
              _addMusic(url.toString());
            },
          ),
        ],
      ),
    );
  }
}
