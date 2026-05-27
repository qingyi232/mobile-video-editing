package com.videoedit.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Files;
import java.util.*;

/**
 * 百度语音识别服务（短语音识别 REST API）
 * 文档：https://ai.baidu.com/ai-doc/SPEECH/Jlbxdezuf
 *
 * 流程：FFmpeg 提取音频段 → 转 PCM 16k → Base64 → 调百度 ASR → 返回识别文本
 */
@Slf4j
@Service
public class BaiduAsrService {

    @Value("${app.baidu-asr.app-id}")
    private String appId;

    @Value("${app.baidu-asr.api-key}")
    private String apiKey;

    @Value("${app.baidu-asr.secret-key}")
    private String secretKey;

    @Value("${app.ffmpeg.path:ffmpeg}")
    private String ffmpegPath;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private String accessToken;
    private long tokenExpireTime;

    /** 获取百度 access_token（缓存） */
    private synchronized String getAccessToken() throws IOException {
        if (accessToken != null && System.currentTimeMillis() < tokenExpireTime) {
            return accessToken;
        }
        String tokenUrl = String.format(
                "https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=%s&client_secret=%s",
                apiKey, secretKey);
        HttpURLConnection conn = (HttpURLConnection) new URL(tokenUrl).openConnection();
        conn.setRequestMethod("POST");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);

        String body = readStream(conn.getInputStream());
        JsonNode json = objectMapper.readTree(body);
        accessToken = json.get("access_token").asText();
        int expiresIn = json.get("expires_in").asInt(2592000);
        tokenExpireTime = System.currentTimeMillis() + (expiresIn - 600) * 1000L;
        log.info("百度ASR token获取成功");
        return accessToken;
    }

    /**
     * 识别一段音频文件中指定时间范围的语音
     * @param videoPath 视频文件绝对路径
     * @param startSec  起始秒
     * @param endSec    结束秒
     * @return 识别出的文本，失败返回 null
     */
    public String recognizeSegment(String videoPath, double startSec, double endSec) {
        File tempPcm = null;
        try {
            // 百度短语音识别限制60秒，这里每段最多取59秒
            double duration = Math.min(endSec - startSec, 59.0);

            // 1. FFmpeg 提取音频段并转为 PCM 16kHz 16bit 单声道
            tempPcm = File.createTempFile("asr_", ".pcm");
            List<String> cmd = Arrays.asList(
                    ffmpegPath, "-y",
                    "-i", videoPath,
                    "-ss", String.valueOf(startSec),
                    "-t", String.valueOf(duration),
                    "-ar", "16000",    // 采样率 16kHz
                    "-ac", "1",        // 单声道
                    "-f", "s16le",     // PCM 16bit
                    tempPcm.getAbsolutePath()
            );
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.redirectErrorStream(true);
            Process p = pb.start();
            p.getInputStream().readAllBytes(); // 消费输出
            int exitCode = p.waitFor();
            if (exitCode != 0 || !tempPcm.exists() || tempPcm.length() == 0) {
                log.warn("FFmpeg提取音频失败: exitCode={}", exitCode);
                return null;
            }

            // 2. 读取 PCM 并 Base64 编码
            byte[] pcmData = Files.readAllBytes(tempPcm.toPath());
            String base64Audio = Base64.getEncoder().encodeToString(pcmData);

            // 3. 调用百度语音识别 REST API（极速版）
            String token = getAccessToken();
            String asrUrl = "https://vop.baidu.com/pro_api";

            Map<String, Object> requestBody = new LinkedHashMap<>();
            requestBody.put("format", "pcm");
            requestBody.put("rate", 16000);
            requestBody.put("channel", 1);
            requestBody.put("cuid", "video_edit_app_" + appId);
            requestBody.put("token", token);
            requestBody.put("dev_pid", 80001); // 极速版-普通话
            requestBody.put("speech", base64Audio);
            requestBody.put("len", pcmData.length);

            String jsonBody = objectMapper.writeValueAsString(requestBody);

            HttpURLConnection conn = (HttpURLConnection) new URL(asrUrl).openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(60000);
            conn.setDoOutput(true);
            byte[] bodyBytes = jsonBody.getBytes("UTF-8");
            conn.setFixedLengthStreamingMode(bodyBytes.length);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(bodyBytes);
                os.flush();
            }

            int httpCode = conn.getResponseCode();
            InputStream respStream = (httpCode >= 200 && httpCode < 300)
                    ? conn.getInputStream() : conn.getErrorStream();
            String response = readStream(respStream);
            JsonNode result = objectMapper.readTree(response);

            int errNo = result.has("err_no") ? result.get("err_no").asInt() : -1;
            if (errNo == 0 && result.has("result")) {
                StringBuilder sb = new StringBuilder();
                for (JsonNode r : result.get("result")) {
                    sb.append(r.asText());
                }
                String text = sb.toString().trim();
                log.info("ASR识别成功 [{}-{}s]: {}", startSec, endSec, text);
                return text.isEmpty() ? null : text;
            } else {
                String errMsg = result.has("err_msg") ? result.get("err_msg").asText() : "unknown";
                log.warn("ASR识别失败: err_no={}, err_msg={}", errNo, errMsg);
                return null;
            }
        } catch (Exception e) {
            log.error("ASR识别异常: {}", e.getMessage());
            return null;
        } finally {
            if (tempPcm != null) tempPcm.delete();
        }
    }

    /**
     * 识别整个视频的语音，按段落返回
     * @param videoPath 视频绝对路径
     * @param segments  FFmpeg 检测到的语音段落列表
     * @return 每段的识别文本
     */
    public List<Map<String, Object>> recognizeAll(String videoPath, List<Map<String, Object>> segments) {
        List<Map<String, Object>> results = new ArrayList<>();
        for (Map<String, Object> seg : segments) {
            double start = ((Number) seg.getOrDefault("start", 0)).doubleValue();
            double end = ((Number) seg.getOrDefault("end", 0)).doubleValue();

            String text = recognizeSegment(videoPath, start, end);
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("start", start);
            item.put("end", end);
            item.put("text", text != null ? text : "(未识别到语音)");
            results.add(item);
        }
        return results;
    }

    private String readStream(InputStream is) throws IOException {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        byte[] buf = new byte[4096];
        int n;
        while ((n = is.read(buf)) != -1) bos.write(buf, 0, n);
        return bos.toString("UTF-8");
    }
}
