package com.videoedit.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "video_templates")
public class VideoTemplate {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(length = 500)
    private String description;

    /** 模板类型: festival, vlog, tutorial */
    @Column(name = "category", nullable = false, length = 50)
    private String category;

    @Column(name = "cover_url", length = 500)
    private String coverUrl;

    @Column(name = "preview_url", length = 500)
    private String previewUrl;

    /** 模板配置JSON: 包含转场、滤镜、音乐等预设 */
    @Column(name = "config_data", columnDefinition = "TEXT")
    private String configData;

    @Column(name = "aspect_ratio", length = 20)
    private String aspectRatio;

    @Column(name = "duration")
    private Double duration;

    @Column(name = "usage_count")
    private Integer usageCount = 0;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
