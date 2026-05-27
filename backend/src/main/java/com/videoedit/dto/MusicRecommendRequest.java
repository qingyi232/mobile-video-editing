package com.videoedit.dto;

import lombok.Data;

@Data
public class MusicRecommendRequest {
    /** 视频场景类型: nature, portrait, dynamic */
    private String sceneType;
    /** 视频时长(秒) */
    private Double videoDuration;
    /** 期望情绪: happy, sad, exciting, relaxing */
    private String mood;
}
