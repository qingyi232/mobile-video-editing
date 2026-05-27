package com.videoedit.service;

import com.videoedit.dto.MusicRecommendRequest;
import com.videoedit.entity.MusicResource;
import com.videoedit.repository.MusicResourceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MusicService {

    private final MusicResourceRepository musicRepository;

    @Value("${app.upload.music-dir}")
    private String musicDir;

    public List<MusicResource> getAllMusic() {
        return musicRepository.findAll();
    }

    public List<MusicResource> getMusicByCategory(String category) {
        return musicRepository.findByCategory(category);
    }

    public MusicResource getMusicById(Long id) {
        return musicRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("音乐资源不存在"));
    }

    public List<MusicResource> recommendMusic(MusicRecommendRequest request) {
        List<MusicResource> candidates = new ArrayList<>();

        // 场景类型映射：AI 识别的 sceneType → 数据库 category
        String sceneType = request.getSceneType();
        if (sceneType != null) {
            sceneType = switch (sceneType) {
                case "calm" -> "nature";      // 静态场景 → 自然类音乐
                case "festive" -> "festive";
                default -> sceneType;         // nature/portrait/dynamic 直接匹配
            };
        }

        if (sceneType != null && request.getMood() != null) {
            candidates = musicRepository.findByCategoryAndMood(sceneType, request.getMood());
        } else if (sceneType != null) {
            candidates = musicRepository.findByCategory(sceneType);
        } else if (request.getMood() != null) {
            candidates = musicRepository.findByMood(request.getMood());
        } else {
            candidates = musicRepository.findAll();
        }

        if (request.getVideoDuration() != null && request.getVideoDuration() > 0) {
            double targetDuration = request.getVideoDuration();
            candidates = candidates.stream()
                    .sorted(Comparator.comparingDouble(m ->
                            Math.abs(m.getDuration() - targetDuration)))
                    .collect(Collectors.toList());
        }

        return candidates.stream().limit(10).collect(Collectors.toList());
    }

    public MusicResource addMusic(MusicResource music) {
        return musicRepository.save(music);
    }

    public MusicResource uploadMusic(MultipartFile file, String title, String artist,
                                     String category, String mood) throws IOException {
        Path dir = Paths.get(musicDir);
        Files.createDirectories(dir);
        String filename = UUID.randomUUID() + "_" + file.getOriginalFilename();
        Path dest = dir.resolve(filename);
        Files.copy(file.getInputStream(), dest, StandardCopyOption.REPLACE_EXISTING);

        MusicResource music = new MusicResource();
        music.setTitle(title != null && !title.isBlank() ? title : file.getOriginalFilename());
        music.setArtist(artist != null ? artist : "");
        music.setCategory(category != null ? category : "dynamic");
        music.setMood(mood != null ? mood : "happy");
        music.setFileUrl("./uploads/music/" + filename);
        music.setFileSize(file.getSize());
        return musicRepository.save(music);
    }
}
