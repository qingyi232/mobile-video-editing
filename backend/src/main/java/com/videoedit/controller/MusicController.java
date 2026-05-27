package com.videoedit.controller;

import com.videoedit.dto.ApiResponse;
import com.videoedit.dto.MusicRecommendRequest;
import com.videoedit.entity.MusicResource;
import com.videoedit.service.MusicService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/music")
@RequiredArgsConstructor
public class MusicController {

    private final MusicService musicService;

    @GetMapping
    public ApiResponse<List<MusicResource>> getAllMusic() {
        return ApiResponse.success(musicService.getAllMusic());
    }

    @GetMapping("/category/{category}")
    public ApiResponse<List<MusicResource>> getMusicByCategory(@PathVariable String category) {
        return ApiResponse.success(musicService.getMusicByCategory(category));
    }

    @GetMapping("/{id}")
    public ApiResponse<MusicResource> getMusicById(@PathVariable Long id) {
        return ApiResponse.success(musicService.getMusicById(id));
    }

    @PostMapping("/upload")
    public ApiResponse<MusicResource> uploadMusic(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "title", required = false) String title,
            @RequestParam(value = "artist", required = false) String artist,
            @RequestParam(value = "category", required = false) String category,
            @RequestParam(value = "mood", required = false) String mood) throws Exception {
        return ApiResponse.success(musicService.uploadMusic(file, title, artist, category, mood));
    }

    @PostMapping("/recommend")
    public ApiResponse<List<MusicResource>> recommendMusic(@RequestBody MusicRecommendRequest request) {
        return ApiResponse.success(musicService.recommendMusic(request));
    }
}
