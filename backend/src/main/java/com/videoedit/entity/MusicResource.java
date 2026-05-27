package com.videoedit.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "music_resources")
public class MusicResource {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(length = 100)
    private String artist;

    @Column(name = "file_url", nullable = false, length = 500)
    private String fileUrl;

    @Column(name = "cover_url", length = 500)
    private String coverUrl;

    @Column(name = "duration")
    private Double duration;

    /** 场景分类: nature, portrait, dynamic, festive, calm, energetic */
    @Column(name = "category", length = 50)
    private String category;

    /** 情绪标签: happy, sad, exciting, relaxing */
    @Column(name = "mood", length = 50)
    private String mood;

    @Column(name = "bpm")
    private Integer bpm;

    @Column(name = "file_size")
    private Long fileSize;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
