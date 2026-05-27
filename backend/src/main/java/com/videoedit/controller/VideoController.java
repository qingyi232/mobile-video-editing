package com.videoedit.controller;

import com.videoedit.dto.ApiResponse;
import com.videoedit.entity.VideoProject;
import com.videoedit.service.VideoProjectService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/video")
@RequiredArgsConstructor
public class VideoController {

    private final VideoProjectService videoService;

    @GetMapping("/projects")
    public ApiResponse<List<VideoProject>> getProjects(
            Authentication authentication,
            @RequestParam(required = false) Integer status) {
        Long userId = (Long) authentication.getPrincipal();
        List<VideoProject> projects = status != null
                ? videoService.getUserProjectsByStatus(userId, status)
                : videoService.getUserProjects(userId);
        return ApiResponse.success(projects);
    }

    @GetMapping("/projects/{id}")
    public ApiResponse<VideoProject> getProject(@PathVariable Long id) {
        return ApiResponse.success(videoService.getProject(id));
    }

    @PostMapping("/projects")
    public ApiResponse<VideoProject> createProject(
            Authentication authentication,
            @RequestBody Map<String, String> body) {
        Long userId = (Long) authentication.getPrincipal();
        VideoProject project = videoService.createProject(userId,
                body.get("title"), body.get("description"));
        return ApiResponse.success("项目创建成功", project);
    }

    @PutMapping("/projects/{id}")
    public ApiResponse<VideoProject> updateProject(
            @PathVariable Long id,
            @RequestBody VideoProject updates) {
        return ApiResponse.success(videoService.updateProject(id, updates));
    }

    @DeleteMapping("/projects/{id}")
    public ApiResponse<String> deleteProject(@PathVariable Long id) {
        videoService.deleteProject(id);
        return ApiResponse.success("删除成功", null);
    }

    @PostMapping("/upload")
    public ApiResponse<Map<String, String>> uploadVideo(
            Authentication authentication,
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "projectId", required = false) Long projectId) {
        try {
            Long userId = (Long) authentication.getPrincipal();
            String path = videoService.uploadVideo(file, userId, projectId);
            return ApiResponse.success(Map.of("path", path, "filename", file.getOriginalFilename()));
        } catch (Exception e) {
            return ApiResponse.error("上传失败: " + e.getMessage());
        }
    }

    @PostMapping("/trim")
    public ApiResponse<Map<String, String>> trimVideo(
            Authentication authentication,
            @RequestBody Map<String, Object> body) {
        Long userId = (Long) authentication.getPrincipal();
        String inputPath = (String) body.get("inputPath");
        double startTime = ((Number) body.get("startTime")).doubleValue();
        double endTime = ((Number) body.get("endTime")).doubleValue();
        String outputPath = videoService.trimVideo(inputPath, startTime, endTime, userId);
        return ApiResponse.success(Map.of("outputPath", outputPath));
    }

    @PostMapping("/concat")
    public ApiResponse<Map<String, String>> concatVideos(
            Authentication authentication,
            @RequestBody Map<String, Object> body) {
        Long userId = (Long) authentication.getPrincipal();
        @SuppressWarnings("unchecked")
        List<String> inputPaths = (List<String>) body.get("inputPaths");
        String outputPath = videoService.concatVideos(inputPaths, userId);
        return ApiResponse.success(Map.of("outputPath", outputPath));
    }

    @PostMapping("/transition")
    public ApiResponse<Map<String, String>> addTransition(
            Authentication authentication,
            @RequestBody Map<String, Object> body) {
        Long userId = (Long) authentication.getPrincipal();
        @SuppressWarnings("unchecked")
        List<String> inputPaths = (List<String>) body.get("inputPaths");
        String transitionType = (String) body.getOrDefault("transitionType", "fade");
        String outputPath = videoService.addTransition(inputPaths, transitionType, userId);
        return ApiResponse.success(Map.of("outputPath", outputPath));
    }

    @PostMapping("/add-music")
    public ApiResponse<Map<String, String>> addMusic(
            Authentication authentication,
            @RequestBody Map<String, Object> body) {
        Long userId = (Long) authentication.getPrincipal();
        String videoPath = (String) body.get("videoPath");
        String audioPath = (String) body.get("audioPath");
        float volume = ((Number) body.get("volume")).floatValue();
        String outputPath = videoService.addMusic(videoPath, audioPath, volume, userId);
        return ApiResponse.success(Map.of("outputPath", outputPath));
    }

    @PostMapping("/separate-voice")
    public ApiResponse<Map<String, String>> separateVoice(
            Authentication authentication,
            @RequestBody Map<String, String> body) {
        Long userId = (Long) authentication.getPrincipal();
        Map<String, String> result = videoService.separateVoice(body.get("videoPath"), userId);
        return ApiResponse.success(result);
    }

    @PostMapping("/change-ratio")
    public ApiResponse<Map<String, String>> changeRatio(
            Authentication authentication,
            @RequestBody Map<String, String> body) {
        Long userId = (Long) authentication.getPrincipal();
        String outputPath = videoService.changeAspectRatio(
                body.get("videoPath"), body.get("ratio"), userId);
        return ApiResponse.success(Map.of("outputPath", outputPath));
    }

    @PostMapping("/export")
    public ApiResponse<Map<String, String>> exportVideo(@RequestBody Map<String, Object> body) {
        Long projectId = ((Number) body.get("projectId")).longValue();
        String format = (String) body.getOrDefault("format", "mp4");
        String outputPath = videoService.exportVideo(projectId, format);
        return ApiResponse.success(Map.of("outputPath", outputPath, "format", format));
    }

    @PostMapping("/analyze-clarity")
    public ApiResponse<List<Map<String, Object>>> analyzeClarity(@RequestBody Map<String, Object> body) {
        String videoPath = (String) body.get("videoPath");
        int sampleCount = body.containsKey("sampleCount")
                ? ((Number) body.get("sampleCount")).intValue() : 10;
        return ApiResponse.success(videoService.analyzeClarity(videoPath, sampleCount));
    }

    @PostMapping("/recognize-scene")
    public ApiResponse<Map<String, Object>> recognizeScene(@RequestBody Map<String, String> body) {
        String videoPath = body.get("videoPath");
        return ApiResponse.success(videoService.recognizeScene(videoPath));
    }

    @PostMapping("/subtitle")
    public ApiResponse<Map<String, Object>> generateSubtitle(@RequestBody Map<String, String> body) {
        try {
            String videoPath = body.get("videoPath");
            return ApiResponse.success(videoService.generateSubtitle(videoPath));
        } catch (RuntimeException e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PostMapping("/burn-subtitle")
    public ApiResponse<Map<String, String>> burnSubtitle(
            Authentication authentication,
            @RequestBody Map<String, String> body) {
        try {
            Long userId = (Long) authentication.getPrincipal();
            String videoPath = body.get("videoPath");
            String subtitleText = body.get("subtitleText");
            String outputPath = videoService.burnSubtitle(videoPath, subtitleText, userId);
            return ApiResponse.success(Map.of("outputPath", outputPath));
        } catch (RuntimeException e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PostMapping("/smart-clip")
    public ApiResponse<Map<String, Object>> smartClip(
            Authentication authentication,
            @RequestBody Map<String, Object> body) {
        try {
            Long userId = (Long) authentication.getPrincipal();
            String videoPath = (String) body.get("videoPath");
            int sampleCount = body.containsKey("sampleCount")
                    ? ((Number) body.get("sampleCount")).intValue() : 10;
            double threshold = body.containsKey("threshold")
                    ? ((Number) body.get("threshold")).doubleValue() : 60.0;
            String outputPath = videoService.smartClip(videoPath, userId, sampleCount, threshold);
            List<Map<String, Object>> clarity = videoService.analyzeClarity(videoPath, sampleCount);
            long kept = clarity.stream()
                    .filter(s -> ((Number) s.getOrDefault("clarity", 0)).doubleValue() >= threshold)
                    .count();
            Map<String, Object> result = new java.util.HashMap<>();
            result.put("outputPath", outputPath);
            result.put("totalSegments", sampleCount);
            result.put("keptSegments", kept);
            result.put("threshold", threshold);
            return ApiResponse.success(result);
        } catch (RuntimeException e) {
            return ApiResponse.error(e.getMessage());
        }
    }

    @PostMapping("/apply-filter")
    public ApiResponse<Map<String, String>> applyFilter(
            Authentication authentication,
            @RequestBody Map<String, String> body) {
        try {
            Long userId = (Long) authentication.getPrincipal();
            String videoPath = body.get("videoPath");
            String filterType = body.getOrDefault("filterType", "none");
            String outputPath = videoService.applyFilter(videoPath, filterType, userId);
            return ApiResponse.success(Map.of("outputPath", outputPath));
        } catch (RuntimeException e) {
            return ApiResponse.error(e.getMessage());
        }
    }
}
