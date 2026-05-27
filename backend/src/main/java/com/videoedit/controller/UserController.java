package com.videoedit.controller;

import com.videoedit.dto.ApiResponse;
import com.videoedit.entity.User;
import com.videoedit.repository.VideoProjectRepository;
import com.videoedit.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;
    private final VideoProjectRepository videoProjectRepository;

    /** 近7日新建项目趋势（真实数据库统计） */
    @GetMapping("/stats")
    public ApiResponse<Map<String, Object>> getStats(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        User user = userService.getUserById(userId);
        long projectCount = videoProjectRepository.countByUserId(userId);
        long exportCount = videoProjectRepository.countByUserIdAndStatus(userId, 1);
        long draftCount = videoProjectRepository.countByUserIdAndStatus(userId, 0);

        long dayCount = 1L;
        if (user.getCreatedAt() != null) {
            dayCount = ChronoUnit.DAYS.between(user.getCreatedAt().toLocalDate(), LocalDate.now()) + 1;
        }

        List<Map<String, Object>> chart = new ArrayList<>();
        for (int i = 6; i >= 0; i--) {
            LocalDate day = LocalDate.now().minusDays(i);
            LocalDateTime start = day.atStartOfDay();
            LocalDateTime end = day.plusDays(1).atStartOfDay();
            long cnt = videoProjectRepository.countByUserIdAndCreatedAtBetween(userId, start, end);
            Map<String, Object> point = new LinkedHashMap<>();
            point.put("label", day.getMonthValue() + "/" + day.getDayOfMonth());
            point.put("count", cnt);
            chart.add(point);
        }

        Map<String, Object> stats = new LinkedHashMap<>();
        stats.put("projectCount", projectCount);
        stats.put("exportCount", exportCount);
        stats.put("draftCount", draftCount);
        stats.put("dayCount", dayCount);
        stats.put("chart", chart);
        return ApiResponse.success(stats);
    }

    @GetMapping("/profile")
    public ApiResponse<Map<String, Object>> getProfile(Authentication authentication) {
        Long userId = (Long) authentication.getPrincipal();
        User user = userService.getUserById(userId);
        Map<String, Object> profile = new HashMap<>();
        profile.put("id", user.getId());
        profile.put("username", user.getUsername());
        profile.put("nickname", user.getNickname());
        profile.put("avatar", user.getAvatar());
        profile.put("email", user.getEmail());
        profile.put("phone", user.getPhone());
        profile.put("createdAt", user.getCreatedAt());
        long projectCount = videoProjectRepository.countByUserId(userId);
        long exportCount = videoProjectRepository.countByUserIdAndStatus(userId, 1);
        profile.put("projectCount", projectCount);
        profile.put("exportCount", exportCount);
        int dayCount = 1;
        if (user.getCreatedAt() != null) {
            dayCount = (int) Math.max(1,
                    java.time.Duration.between(user.getCreatedAt(), java.time.LocalDateTime.now()).toDays() + 1);
        }
        profile.put("dayCount", dayCount);
        return ApiResponse.success(profile);
    }

    @PutMapping("/profile")
    public ApiResponse<Map<String, Object>> updateProfile(
            Authentication authentication,
            @RequestBody Map<String, String> updates) {
        Long userId = (Long) authentication.getPrincipal();
        User user = userService.updateProfile(userId,
                updates.get("nickname"),
                updates.get("email"),
                updates.get("phone"),
                updates.get("avatar"));
        Map<String, Object> result = new HashMap<>();
        result.put("nickname", user.getNickname());
        result.put("email", user.getEmail());
        result.put("phone", user.getPhone());
        result.put("avatar", user.getAvatar());
        return ApiResponse.success("更新成功", result);
    }

    @PostMapping("/avatar")
    public ApiResponse<Map<String, String>> uploadAvatar(
            Authentication authentication,
            @RequestParam("file") MultipartFile file) {
        try {
            Long userId = (Long) authentication.getPrincipal();
            String dir = "./uploads/avatars/" + userId;
            new File(dir).mkdirs();
            String fileName = UUID.randomUUID() + "_" + file.getOriginalFilename();
            String filePath = dir + "/" + fileName;
            file.transferTo(new File(filePath));
            String avatarUrl = "/uploads/avatars/" + userId + "/" + fileName;
            userService.updateProfile(userId, null, null, null, avatarUrl);
            return ApiResponse.success(Map.of("avatar", avatarUrl));
        } catch (Exception e) {
            return ApiResponse.error("上传失败: " + e.getMessage());
        }
    }

    @PostMapping("/change-password")
    public ApiResponse<String> changePassword(
            Authentication authentication,
            @RequestBody Map<String, String> body) {
        try {
            Long userId = (Long) authentication.getPrincipal();
            userService.changePassword(userId, body.get("oldPassword"), body.get("newPassword"));
            return ApiResponse.success("密码修改成功", null);
        } catch (RuntimeException e) {
            return ApiResponse.error(400, e.getMessage());
        }
    }
}
