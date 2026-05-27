package com.videoedit.repository;

import com.videoedit.entity.VideoProject;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface VideoProjectRepository extends JpaRepository<VideoProject, Long> {
    List<VideoProject> findByUserIdOrderByUpdatedAtDesc(Long userId);
    List<VideoProject> findByUserIdAndStatusOrderByUpdatedAtDesc(Long userId, Integer status);
    long countByUserId(Long userId);
    long countByUserIdAndStatus(Long userId, Integer status);

    long countByUserIdAndCreatedAtBetween(Long userId, LocalDateTime start, LocalDateTime end);
}
