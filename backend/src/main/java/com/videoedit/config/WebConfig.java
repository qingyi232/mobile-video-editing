package com.videoedit.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Value("${app.upload.video-dir}")
    private String videoDir;

    @Value("${app.upload.music-dir}")
    private String musicDir;

    @Value("${app.upload.avatar-dir}")
    private String avatarDir;

    @Value("${app.upload.export-dir}")
    private String exportDir;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/videos/**")
                .addResourceLocations("file:///" + absPath(videoDir) + "/");
        registry.addResourceHandler("/uploads/music/**")
                .addResourceLocations("file:///" + absPath(musicDir) + "/");
        registry.addResourceHandler("/uploads/avatars/**")
                .addResourceLocations("file:///" + absPath(avatarDir) + "/");
        registry.addResourceHandler("/uploads/exports/**")
                .addResourceLocations("file:///" + absPath(exportDir) + "/");
    }

    private String absPath(String dir) {
        return new java.io.File(dir).getAbsolutePath().replace('\\', '/');
    }
}
