package com.videoedit.config;

import com.videoedit.entity.MusicResource;
import com.videoedit.entity.VideoTemplate;
import com.videoedit.repository.MusicResourceRepository;
import com.videoedit.repository.VideoTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final MusicResourceRepository musicRepo;
    private final VideoTemplateRepository templateRepo;

    @Override
    public void run(String... args) {
        if (musicRepo.count() == 0) {
            initMusicResources();
        }
        if (templateRepo.count() == 0) {
            initTemplates();
        }
    }

    private void initMusicResources() {
        String[][] musicData = {
                {"轻快晨光", "Studio BGM", "nature", "happy", "120", "180.0", "music_01.mp3"},
                {"城市漫步", "Urban Beats", "dynamic", "relaxing", "100", "210.0", "music_02.mp3"},
                {"温馨时刻", "Piano Dreams", "portrait", "relaxing", "80", "240.0", "music_03.mp3"},
                {"活力四射", "Energy Pop", "dynamic", "exciting", "140", "150.0", "music_04.mp3"},
                {"自然之声", "Nature Sounds", "nature", "relaxing", "90", "300.0", "music_05.mp3"},
                {"节日欢歌", "Festival Band", "festive", "happy", "130", "200.0", "music_06.mp3"},
                {"深夜独白", "Midnight Jazz", "portrait", "sad", "70", "270.0", "music_07.mp3"},
                {"运动节拍", "Sport Mix", "dynamic", "exciting", "160", "120.0", "music_08.mp3"},
                {"田园风光", "Country Style", "nature", "happy", "110", "190.0", "music_09.mp3"},
                {"科技未来", "Tech Wave", "dynamic", "exciting", "135", "160.0", "music_10.mp3"},
                {"浪漫花海", "Romance", "portrait", "happy", "95", "220.0", "music_11.mp3"},
                {"旅行日记", "Travel Diary", "nature", "relaxing", "105", "250.0", "music_12.mp3"},
        };
        for (String[] d : musicData) {
            MusicResource m = new MusicResource();
            m.setTitle(d[0]);
            m.setArtist(d[1]);
            m.setFileUrl("/uploads/music/" + d[6]);
            m.setCategory(d[2]);
            m.setMood(d[3]);
            m.setBpm(Integer.parseInt(d[4]));
            m.setDuration(Double.parseDouble(d[5]));
            musicRepo.save(m);
        }
    }

    private void initTemplates() {
        String[][] templateData = {
                {"新年祝福", "festival", "红色喜庆风格, 烟花转场效果", "16:9", "30.0"},
                {"春节拜年", "festival", "中国红主题, 灯笼特效", "9:16", "15.0"},
                {"生日快乐", "festival", "彩色气球, 蛋糕动画", "9:16", "20.0"},
                {"日常Vlog", "vlog", "简约白色风格, 文字标题动画", "9:16", "60.0"},
                {"旅行Vlog", "vlog", "胶片质感滤镜, 地图转场", "16:9", "45.0"},
                {"美食Vlog", "vlog", "暖色调滤镜, 美食标签动画", "9:16", "30.0"},
                {"软件教程", "tutorial", "清晰录屏风格, 步骤标注", "16:9", "120.0"},
                {"摄影教学", "tutorial", "分屏对比, 参数标注", "16:9", "90.0"},
                {"健身教程", "tutorial", "动感风格, 计时器组件", "9:16", "60.0"},
        };
        for (String[] d : templateData) {
            VideoTemplate t = new VideoTemplate();
            t.setName(d[0]);
            t.setCategory(d[1]);
            t.setDescription(d[2]);
            t.setAspectRatio(d[3]);
            t.setDuration(Double.parseDouble(d[4]));
            t.setConfigData("{\"transitions\":\"fade\",\"filter\":\"default\"}");
            templateRepo.save(t);
        }
    }
}
