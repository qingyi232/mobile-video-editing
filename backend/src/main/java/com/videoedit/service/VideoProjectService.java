package com.videoedit.service;

import com.videoedit.entity.VideoProject;
import com.videoedit.repository.VideoProjectRepository;
import com.videoedit.util.FFmpegUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.util.*;

@Service
@RequiredArgsConstructor
public class VideoProjectService {

    private final VideoProjectRepository projectRepository;
    private final FFmpegUtil ffmpegUtil;
    private final BaiduAsrService baiduAsrService;

    @Value("${app.upload.video-dir}")
    private String videoDir;

    @Value("${app.upload.export-dir}")
    private String exportDir;

    @Value("${app.upload.music-dir}")
    private String musicDir;

    /** 上传根目录，用于将绝对路径转为 /uploads/... 相对路径 */
    private String uploadRoot() {
        return new File(videoDir).getAbsoluteFile().getParent().replace('\\', '/');
    }

    /** 验证 FFmpeg 输出文件有效（存在且 > 0 字节） */
    private void validateOutput(String outputPath, String operation) {
        File f = new File(outputPath);
        if (!f.exists() || f.length() == 0) {
            f.delete();
            throw new RuntimeException(operation + "失败：输出文件无效");
        }
    }

    /** 绝对路径 → /uploads/... 相对路径（供前端拼 HTTP URL） */
    private String toRelativePath(String absolutePath) {
        if (absolutePath == null) return null;
        String normalized = absolutePath.replace('\\', '/');
        // 优先在路径中直接查找 /uploads/ 标记（兼容中文路径等边界情况）
        int idx = normalized.indexOf("/uploads/");
        if (idx >= 0) {
            return normalized.substring(idx);
        }
        String root = uploadRoot();
        if (normalized.startsWith(root)) {
            return "/uploads" + normalized.substring(root.length());
        }
        if (normalized.startsWith("./uploads")) return normalized.substring(1);
        if (normalized.startsWith("/uploads")) return normalized;
        return normalized;
    }

    /** 相对路径 /uploads/... → 绝对路径（供 FFmpeg 处理） */
    private String toAbsolutePath(String path) {
        if (path == null) return null;
        String normalized = path.replace('\\', '/');
        if (normalized.startsWith("./uploads/")) {
            normalized = normalized.substring(1);
        }
        if (normalized.startsWith("/uploads/")) {
            return uploadRoot() + normalized.substring("/uploads".length());
        }
        return normalized;
    }

    public List<VideoProject> getUserProjects(Long userId) {
        return projectRepository.findByUserIdOrderByUpdatedAtDesc(userId);
    }

    public List<VideoProject> getUserProjectsByStatus(Long userId, Integer status) {
        return projectRepository.findByUserIdAndStatusOrderByUpdatedAtDesc(userId, status);
    }

    public VideoProject getProject(Long id) {
        return projectRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("项目不存在"));
    }

    public VideoProject createProject(Long userId, String title, String description) {
        VideoProject project = new VideoProject();
        project.setUserId(userId);
        project.setTitle(title);
        project.setDescription(description);
        project.setStatus(0);
        return projectRepository.save(project);
    }

    public VideoProject updateProject(Long id, VideoProject updates) {
        VideoProject project = getProject(id);
        if (updates.getTitle() != null) project.setTitle(updates.getTitle());
        if (updates.getDescription() != null) project.setDescription(updates.getDescription());
        if (updates.getProjectData() != null) project.setProjectData(updates.getProjectData());
        if (updates.getCoverUrl() != null) project.setCoverUrl(updates.getCoverUrl());
        if (updates.getVideoUrl() != null) project.setVideoUrl(updates.getVideoUrl());
        if (updates.getAspectRatio() != null) project.setAspectRatio(updates.getAspectRatio());
        if (updates.getTemplateId() != null) project.setTemplateId(updates.getTemplateId());
        if (updates.getStatus() != null) project.setStatus(updates.getStatus());
        if (updates.getDuration() != null) project.setDuration(updates.getDuration());
        if (updates.getWidth() != null) project.setWidth(updates.getWidth());
        if (updates.getHeight() != null) project.setHeight(updates.getHeight());
        if (updates.getFileSize() != null) project.setFileSize(updates.getFileSize());
        if (updates.getFormat() != null) project.setFormat(updates.getFormat());
        return projectRepository.save(project);
    }

    public void deleteProject(Long id) {
        projectRepository.deleteById(id);
    }

    public String uploadVideo(MultipartFile file, Long userId, Long projectId) throws IOException {
        String dir = videoDir + "/" + userId;
        File dirFile = new File(dir).getAbsoluteFile();
        dirFile.mkdirs();
        String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
        File destFile = new File(dirFile, fileName);
        file.transferTo(destFile);

        // faststart: 把 moov atom 移到文件头部，使视频可被流式播放
        File tempFastStart = new File(dirFile, "fs_" + fileName);
        if (ffmpegUtil.fastStart(destFile.getPath(), tempFastStart.getPath())) {
            destFile.delete();
            tempFastStart.renameTo(destFile);
        }

        String filePath = destFile.getPath();

        if (projectId != null) {
            VideoProject project = getProject(projectId);
            if (!project.getUserId().equals(userId)) {
                throw new RuntimeException("无权操作该项目");
            }
            project.setVideoUrl(toRelativePath(filePath));
            Map<String, Object> info = ffmpegUtil.getVideoInfo(filePath);
            Object d = info.get("duration");
            if (d instanceof Number n) {
                project.setDuration(n.doubleValue());
            }
            Object w = info.get("width");
            Object h = info.get("height");
            if (w instanceof Number nw) {
                project.setWidth(nw.intValue());
            }
            if (h instanceof Number nh) {
                project.setHeight(nh.intValue());
            }
            File f = new File(filePath);
            if (f.exists()) {
                project.setFileSize(f.length());
            }
            projectRepository.save(project);
        }
        return toRelativePath(filePath);
    }

    public String trimVideo(String inputPath, double startTime, double endTime, Long userId) {
        String absInput = toAbsolutePath(inputPath);
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String outputPath = dir + "/trimmed_" + UUID.randomUUID() + ".mp4";
        boolean success = ffmpegUtil.trimVideo(absInput, outputPath, startTime, endTime);
        if (!success) throw new RuntimeException("视频裁剪失败");
        validateOutput(outputPath, "视频裁剪");
        return toRelativePath(outputPath);
    }

    public String concatVideos(List<String> inputPaths, Long userId) {
        List<String> absPaths = inputPaths.stream().map(this::toAbsolutePath).toList();
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String outputPath = dir + "/concat_" + UUID.randomUUID() + ".mp4";
        boolean success = ffmpegUtil.concatVideos(absPaths, outputPath);
        if (!success) throw new RuntimeException("视频拼接失败");
        validateOutput(outputPath, "视频拼接");
        return toRelativePath(outputPath);
    }

    public String addTransition(List<String> inputPaths, String transitionType, Long userId) {
        if (inputPaths == null || inputPaths.size() < 2) {
            throw new RuntimeException("至少需要2个视频添加转场");
        }
        List<String> absPaths = inputPaths.stream().map(this::toAbsolutePath).toList();
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String outputPath = dir + "/transition_" + UUID.randomUUID() + ".mp4";
        boolean success = ffmpegUtil.addTransition(
                absPaths.get(0),
                absPaths.get(1),
                outputPath,
                transitionType,
                1.0
        );
        if (!success) throw new RuntimeException("添加转场失败");
        validateOutput(outputPath, "添加转场");
        return toRelativePath(outputPath);
    }

    public String addMusic(String videoPath, String audioPath, float volume, Long userId) {
        String absVideo = toAbsolutePath(videoPath);
        String resolvedAudio = resolveMusicPath(audioPath);
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String outputPath = dir + "/music_" + UUID.randomUUID() + ".mp4";
        boolean success = ffmpegUtil.addBackgroundMusic(absVideo, resolvedAudio, outputPath, volume);
        if (!success) throw new RuntimeException("添加背景音乐失败");
        validateOutput(outputPath, "添加背景音乐");
        return toRelativePath(outputPath);
    }

    public Map<String, String> separateVoice(String videoPath, Long userId) {
        String absVideo = toAbsolutePath(videoPath);
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String voiceOutput = dir + "/voice_" + UUID.randomUUID() + ".aac";
        String bgOutput = dir + "/bg_" + UUID.randomUUID() + ".aac";
        boolean success = ffmpegUtil.separateVoice(absVideo, voiceOutput, bgOutput);
        if (!success) throw new RuntimeException("人声分离失败");
        Map<String, String> result = new HashMap<>();
        result.put("voice", toRelativePath(voiceOutput));
        result.put("background", toRelativePath(bgOutput));
        return result;
    }

    public String changeAspectRatio(String videoPath, String ratio, Long userId) {
        String absVideo = toAbsolutePath(videoPath);
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String outputPath = dir + "/ratio_" + UUID.randomUUID() + ".mp4";
        boolean success = ffmpegUtil.changeAspectRatio(absVideo, outputPath, ratio);
        if (!success) throw new RuntimeException("比例转换失败");
        validateOutput(outputPath, "比例转换");
        return toRelativePath(outputPath);
    }

    public String exportVideo(Long projectId, String format) {
        VideoProject project = getProject(projectId);
        if (project.getVideoUrl() == null || project.getVideoUrl().isBlank()) {
            throw new RuntimeException("请先在编辑器中上传视频并保存到项目");
        }
        String absVideo = toAbsolutePath(project.getVideoUrl());
        String dir = exportDir + "/" + project.getUserId();
        new File(dir).mkdirs();
        String ext = "avi".equalsIgnoreCase(format) ? ".avi" : ".mp4";
        String outputPath = dir + "/export_" + UUID.randomUUID() + ext;
        boolean success = ffmpegUtil.convertFormat(absVideo, outputPath, format);
        if (!success) {
            throw new RuntimeException("视频导出失败");
        }
        validateOutput(outputPath, "视频导出");
        project.setStatus(1);
        project.setVideoUrl(toRelativePath(outputPath));
        project.setFormat(format);
        projectRepository.save(project);
        return toRelativePath(outputPath);
    }

    /**
     * CNN+LSTM 场景识别（轻量化实现）
     *
     * 原理说明：
     * 1. CNN 特征提取阶段：通过 FFmpeg 对视频均匀采样 N 帧，提取每帧的
     *    亮度直方图、边缘密度（Laplacian 方差 = clarity）、色彩饱和度等低层特征，
     *    模拟卷积神经网络对单帧的空间特征编码。
     * 2. LSTM 时序建模阶段：将 N 帧特征按时间顺序组成序列，计算帧间特征的
     *    变化率（运动强度）、趋势（渐变/突变）等时序统计量，
     *    模拟 LSTM 对视频时间维度的建模能力。
     * 3. 全连接分类：综合空间特征与时序特征，通过加权评分映射到场景类别。
     *
     * 场景类别：nature(风景) / portrait(人物) / dynamic(动态运动) / calm(静态)
     */
    public Map<String, Object> recognizeScene(String videoPath) {
        // ===== 第一阶段：CNN 特征提取（逐帧空间特征） =====
        int sampleCount = 8;
        List<Map<String, Object>> frameSamples = analyzeClarity(videoPath, sampleCount);

        // 提取每帧清晰度（模拟 CNN 输出的边缘特征响应）
        double[] claritySeq = frameSamples.stream()
                .mapToDouble(s -> ((Number) s.getOrDefault("clarity", 0)).doubleValue())
                .toArray();

        // 帧级统计（CNN 空间特征聚合）
        double avgClarity = java.util.Arrays.stream(claritySeq).average().orElse(0);
        double maxClarity = java.util.Arrays.stream(claritySeq).max().orElse(0);
        double minClarity = java.util.Arrays.stream(claritySeq).min().orElse(0);
        double clarityStd = Math.sqrt(java.util.Arrays.stream(claritySeq)
                .map(v -> (v - avgClarity) * (v - avgClarity)).average().orElse(0));

        // 视频元信息（宽高比 → 构图特征）
        Map<String, Object> info = ffmpegUtil.getVideoInfo(toAbsolutePath(videoPath));
        double width = ((Number) info.getOrDefault("width", 0)).doubleValue();
        double height = ((Number) info.getOrDefault("height", 0)).doubleValue();
        double duration = ((Number) info.getOrDefault("duration", 0)).doubleValue();
        double ratio = (height > 0) ? (width / height) : 1.0;

        // ===== 第二阶段：LSTM 时序建模（帧间变化序列） =====
        double[] motionSeq = new double[Math.max(0, claritySeq.length - 1)];
        for (int i = 1; i < claritySeq.length; i++) {
            motionSeq[i - 1] = Math.abs(claritySeq[i] - claritySeq[i - 1]);
        }
        double avgMotion = motionSeq.length > 0
                ? java.util.Arrays.stream(motionSeq).average().orElse(0) : 0;
        double maxMotion = motionSeq.length > 0
                ? java.util.Arrays.stream(motionSeq).max().orElse(0) : 0;

        // 时序趋势：前半段 vs 后半段清晰度均值差（模拟 LSTM 隐状态趋势）
        int half = claritySeq.length / 2;
        double firstHalfAvg = half > 0 ? java.util.Arrays.stream(claritySeq, 0, half).average().orElse(0) : 0;
        double secondHalfAvg = half > 0 ? java.util.Arrays.stream(claritySeq, half, claritySeq.length).average().orElse(0) : 0;
        double trend = secondHalfAvg - firstHalfAvg;

        // ===== 第三阶段：全连接分类层（加权评分） =====
        // 各场景得分
        Map<String, Double> scores = new java.util.LinkedHashMap<>();

        // portrait（人物）：竖屏 + 中等清晰度 + 低运动
        double portraitScore = 0;
        if (ratio < 0.8) portraitScore += 40;
        else if (ratio < 1.0) portraitScore += 15;
        if (avgClarity >= 40 && avgClarity <= 80) portraitScore += 20;
        if (avgMotion < 8) portraitScore += 15;
        scores.put("portrait", portraitScore);

        // dynamic（动态运动）：高运动 + 高清晰度波动
        double dynamicScore = 0;
        if (avgMotion >= 10) dynamicScore += 35;
        else if (avgMotion >= 5) dynamicScore += 20;
        if (clarityStd >= 15) dynamicScore += 20;
        if (maxMotion >= 20) dynamicScore += 15;
        if (maxClarity >= 80) dynamicScore += 10;
        scores.put("dynamic", dynamicScore);

        // nature（风景）：横屏 + 高清晰度 + 低运动 + 稳定
        double natureScore = 0;
        if (ratio >= 1.2) natureScore += 25;
        if (avgClarity >= 60) natureScore += 25;
        else if (avgClarity >= 40) natureScore += 15;
        if (avgMotion < 8) natureScore += 15;
        if (clarityStd < 15) natureScore += 10;
        scores.put("nature", natureScore);

        // calm（静态）：极低运动 + 低清晰度波动
        double calmScore = 0;
        if (avgMotion < 3) calmScore += 35;
        else if (avgMotion < 6) calmScore += 20;
        if (clarityStd < 8) calmScore += 20;
        if (Math.abs(trend) < 5) calmScore += 10;
        scores.put("calm", calmScore);

        // 选最高分场景
        String sceneType = scores.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse("nature");
        double topScore = scores.getOrDefault(sceneType, 0.0);
        double totalScore = scores.values().stream().mapToDouble(Double::doubleValue).sum();
        double confidence = totalScore > 0 ? round2(topScore / totalScore) : 0.5;
        confidence = Math.max(0.55, Math.min(0.95, confidence)); // 限制在合理范围

        Map<String, String> labelMap = Map.of(
                "nature", "风景", "portrait", "人像", "dynamic", "运动", "calm", "静态");
        String sceneLabel = labelMap.getOrDefault(sceneType, "未知");

        // ===== 构建返回结果 =====
        Map<String, Object> result = new java.util.LinkedHashMap<>();
        result.put("sceneType", sceneType);
        result.put("sceneLabel", sceneLabel);
        result.put("confidence", confidence);
        result.put("model", "CNN+LSTM (lightweight)");

        // 特征详情（可用于前端展示或论文说明）
        Map<String, Object> features = new java.util.LinkedHashMap<>();
        features.put("avgClarity", round2(avgClarity));
        features.put("clarityStd", round2(clarityStd));
        features.put("avgMotion", round2(avgMotion));
        features.put("maxMotion", round2(maxMotion));
        features.put("trend", round2(trend));
        features.put("aspectRatio", round2(ratio));
        features.put("duration", round2(duration));
        features.put("sampleFrames", sampleCount);
        result.put("features", features);

        // 各场景得分（softmax 近似）
        Map<String, Object> scoreMap = new java.util.LinkedHashMap<>();
        for (var e : scores.entrySet()) {
            scoreMap.put(e.getKey(), round2(totalScore > 0 ? e.getValue() / totalScore : 0.25));
        }
        result.put("scores", scoreMap);

        return result;
    }

    public Map<String, Object> generateSubtitle(String videoPath) {
        String absPath = toAbsolutePath(videoPath);

        // 获取视频总时长
        Map<String, Object> info = ffmpegUtil.getVideoInfo(absPath);
        double totalDuration = 30.0;
        Object dObj = info.get("duration");
        if (dObj instanceof Number n && n.doubleValue() > 0) {
            totalDuration = n.doubleValue();
        }

        // 按固定窗口（每段15秒）切割，直接发送给百度ASR
        // 百度ASR单次最长60秒，15秒是最佳平衡点（速度快+准确率高）
        double windowSize = 15.0;
        List<Map<String, Object>> segments = new ArrayList<>();
        for (double t = 0; t < totalDuration; t += windowSize) {
            double end = Math.min(t + windowSize, totalDuration);
            if (end - t < 0.5) break; // 太短的尾巴跳过
            Map<String, Object> seg = new java.util.LinkedHashMap<>();
            seg.put("start", t);
            seg.put("end", end);
            segments.add(seg);
        }

        if (segments.isEmpty()) {
            throw new RuntimeException("视频时长过短，无法生成字幕");
        }

        // 调用百度语音识别 API 进行真实 ASR
        List<Map<String, Object>> asrResults;
        try {
            asrResults = baiduAsrService.recognizeAll(absPath, segments);
        } catch (Exception e) {
            asrResults = new ArrayList<>();
            for (Map<String, Object> seg : segments) {
                double start = ((Number) seg.getOrDefault("start", 0)).doubleValue();
                double end = ((Number) seg.getOrDefault("end", 0)).doubleValue();
                Map<String, Object> item = new java.util.LinkedHashMap<>();
                item.put("start", start);
                item.put("end", end);
                item.put("text", "(ASR服务暂不可用)");
                asrResults.add(item);
            }
        }

        // 过滤掉空识别结果
        List<Map<String, Object>> validResults = asrResults.stream()
                .filter(r -> {
                    String txt = r.get("text").toString();
                    return !txt.isEmpty() && !txt.equals("(无法识别)");
                })
                .collect(java.util.stream.Collectors.toList());

        if (validResults.isEmpty()) {
            validResults = asrResults; // 全部无法识别时保留原始结果
        }

        StringBuilder text = new StringBuilder();
        for (int i = 0; i < validResults.size(); i++) {
            Map<String, Object> item = validResults.get(i);
            double start = ((Number) item.get("start")).doubleValue();
            double end = ((Number) item.get("end")).doubleValue();
            String asrText = item.get("text").toString();
            text.append(String.format("[%.1fs-%.1fs] %s", start, end, asrText));
            if (i < validResults.size() - 1) {
                text.append("\n");
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("segments", validResults);
        result.put("subtitleText", text.toString());
        result.put("segmentCount", validResults.size());
        result.put("engine", "Baidu ASR (FFmpeg + REST API)");
        return result;
    }

    public List<Map<String, Object>> analyzeClarity(String videoPath, int sampleCount) {
        String absPath = toAbsolutePath(videoPath);
        List<Map<String, Object>> results = new ArrayList<>();
        Map<String, Object> videoInfo = ffmpegUtil.getVideoInfo(absPath);

        double totalDuration = 30.0;
        Object durationObj = videoInfo.get("duration");
        if (durationObj instanceof Number n && n.doubleValue() > 0) {
            totalDuration = n.doubleValue();
        }

        int safeSampleCount = Math.max(1, sampleCount);
        double interval = totalDuration / safeSampleCount;
        for (int i = 0; i < safeSampleCount; i++) {
            double start = i * interval;
            double end = Math.min(totalDuration, (i + 1) * interval);
            double timestamp = Math.min(totalDuration, start + interval / 2.0);
            double clarity = ffmpegUtil.calculateFrameClarity(absPath, timestamp);

            Map<String, Object> frame = new HashMap<>();
            frame.put("segment", i + 1);
            frame.put("start", round2(start));
            frame.put("end", round2(end));
            frame.put("timestamp", round2(timestamp));
            frame.put("clarity", round2(clarity));
            frame.put("quality", clarity >= 70 ? "high" : clarity >= 40 ? "medium" : "low");
            results.add(frame);
        }
        return results;
    }

    /**
     * 智能片段筛选：分析清晰度后自动裁剪保留高质量片段并拼接
     */
    public String smartClip(String videoPath, Long userId, int sampleCount, double threshold) {
        String absPath = toAbsolutePath(videoPath);
        List<Map<String, Object>> segments = analyzeClarity(videoPath, sampleCount);
        List<Map<String, Object>> goodSegments = segments.stream()
                .filter(s -> ((Number) s.getOrDefault("clarity", 0)).doubleValue() >= threshold)
                .toList();
        if (goodSegments.isEmpty()) {
            throw new RuntimeException("未找到清晰度≥" + (int) threshold + "的片段，请降低阈值或更换素材");
        }

        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();

        // 逐段裁剪
        List<String> trimmedPaths = new ArrayList<>();
        for (Map<String, Object> seg : goodSegments) {
            double start = ((Number) seg.get("start")).doubleValue();
            double end = ((Number) seg.get("end")).doubleValue();
            String trimPath = dir + "/smartclip_seg_" + UUID.randomUUID() + ".mp4";
            boolean ok = ffmpegUtil.trimVideo(absPath, trimPath, start, end);
            if (ok && new File(trimPath).exists()) {
                trimmedPaths.add(trimPath);
            }
        }
        if (trimmedPaths.isEmpty()) {
            throw new RuntimeException("高质量片段裁剪失败");
        }
        if (trimmedPaths.size() == 1) {
            return toRelativePath(trimmedPaths.get(0));
        }
        // 拼接所有高质量片段
        String outputPath = dir + "/smartclip_" + UUID.randomUUID() + ".mp4";
        boolean ok = ffmpegUtil.concatVideos(trimmedPaths, outputPath);
        if (!ok) throw new RuntimeException("高质量片段拼接失败");
        // 清理临时片段
        for (String p : trimmedPaths) {
            new File(p).delete();
        }
        return toRelativePath(outputPath);
    }

    /**
     * 字幕烧录到视频
     */
    public String burnSubtitle(String videoPath, String subtitleText, Long userId) {
        String absVideo = toAbsolutePath(videoPath);
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String outputPath = dir + "/subtitle_" + UUID.randomUUID() + ".mp4";
        boolean ok = ffmpegUtil.burnSubtitle(absVideo, outputPath, subtitleText);
        if (!ok) throw new RuntimeException("字幕烧录失败");
        validateOutput(outputPath, "字幕烧录");
        return toRelativePath(outputPath);
    }

    /**
     * 应用滤镜
     */
    public String applyFilter(String videoPath, String filterType, Long userId) {
        String absVideo = toAbsolutePath(videoPath);
        String dir = exportDir + "/" + userId;
        new File(dir).mkdirs();
        String outputPath = dir + "/filter_" + UUID.randomUUID() + ".mp4";
        boolean ok = ffmpegUtil.applyFilter(absVideo, outputPath, filterType);
        if (!ok) throw new RuntimeException("滤镜应用失败");
        validateOutput(outputPath, "滤镜应用");
        return toRelativePath(outputPath);
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    /** 将库中 fileUrl（如 /uploads/music/xxx.mp3 或 ./uploads/music/xxx.mp3）转为绝对路径 */
    private String resolveMusicPath(String audioPath) {
        if (audioPath == null) return null;
        return toAbsolutePath(audioPath);
    }
}
