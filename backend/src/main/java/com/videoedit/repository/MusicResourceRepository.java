package com.videoedit.repository;

import com.videoedit.entity.MusicResource;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface MusicResourceRepository extends JpaRepository<MusicResource, Long> {
    List<MusicResource> findByCategory(String category);
    List<MusicResource> findByMood(String mood);
    List<MusicResource> findByCategoryAndMood(String category, String mood);
    List<MusicResource> findByDurationBetween(Double minDuration, Double maxDuration);
}
