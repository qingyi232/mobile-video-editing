package com.videoedit.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "video_projects")
public class VideoProject {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 500)
    private String description;

    @Column(name = "cover_url", length = 500)
    private String coverUrl;

    @Column(name = "video_url", length = 500)
    private String videoUrl;

    @Column(name = "duration")
    private Double duration;

    @Column(name = "width")
    private Integer width;

    @Column(name = "height")
    private Integer height;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "format", length = 20)
    private String format;

    @Column(name = "aspect_ratio", length = 20)
    private String aspectRatio;

    @Column(name = "template_id")
    private Long templateId;

    /** 0=草稿 1=已导出 */
    @Column(name = "status")
    private Integer status = 0;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "project_data", columnDefinition = "TEXT")
    private String projectData;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
