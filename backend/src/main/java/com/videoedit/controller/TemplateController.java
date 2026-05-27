package com.videoedit.controller;

import com.videoedit.dto.ApiResponse;
import com.videoedit.entity.VideoTemplate;
import com.videoedit.service.TemplateService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/templates")
@RequiredArgsConstructor
public class TemplateController {

    private final TemplateService templateService;

    @GetMapping
    public ApiResponse<List<VideoTemplate>> getAllTemplates() {
        return ApiResponse.success(templateService.getAllTemplates());
    }

    @GetMapping("/category/{category}")
    public ApiResponse<List<VideoTemplate>> getTemplatesByCategory(@PathVariable String category) {
        return ApiResponse.success(templateService.getTemplatesByCategory(category));
    }

    @GetMapping("/{id}")
    public ApiResponse<VideoTemplate> getTemplateById(@PathVariable Long id) {
        return ApiResponse.success(templateService.getTemplateById(id));
    }

    @PostMapping("/{id}/use")
    public ApiResponse<VideoTemplate> useTemplate(@PathVariable Long id) {
        return ApiResponse.success(templateService.useTemplate(id));
    }
}
