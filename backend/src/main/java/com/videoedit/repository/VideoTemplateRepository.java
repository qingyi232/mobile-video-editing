package com.videoedit.repository;

import com.videoedit.entity.VideoTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface VideoTemplateRepository extends JpaRepository<VideoTemplate, Long> {
    List<VideoTemplate> findByCategory(String category);
    List<VideoTemplate> findAllByOrderByUsageCountDesc();
}
