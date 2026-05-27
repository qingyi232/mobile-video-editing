package com.videoedit.service;

import com.videoedit.entity.VideoTemplate;
import com.videoedit.repository.VideoTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TemplateService {

    private final VideoTemplateRepository templateRepository;

    public List<VideoTemplate> getAllTemplates() {
        return templateRepository.findAllByOrderByUsageCountDesc();
    }

    public List<VideoTemplate> getTemplatesByCategory(String category) {
        return templateRepository.findByCategory(category);
    }

    public VideoTemplate getTemplateById(Long id) {
        return templateRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("模板不存在"));
    }

    public VideoTemplate useTemplate(Long id) {
        VideoTemplate template = getTemplateById(id);
        template.setUsageCount(template.getUsageCount() + 1);
        return templateRepository.save(template);
    }

    public VideoTemplate addTemplate(VideoTemplate template) {
        return templateRepository.save(template);
    }
}
