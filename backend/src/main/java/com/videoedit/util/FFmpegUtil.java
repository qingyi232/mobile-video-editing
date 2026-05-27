package com.videoedit.util;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.*;
import java.util.*;

@Component
public class FFmpegUtil {

    @Value("${app.ffmpeg.path}")
    private String ffmpegPath;

    public boolean trimVideo(String inputPath, String outputPath, double startTime, double endTime) {
        List<String> cmd = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", inputPath,
                "-ss", String.valueOf(startTime),
                "-to", String.valueOf(endTime),
                "-c:v", "libx264", "-c:a", "aac",
                "-preset", "fast",
                "-movflags", "+faststart",
                outputPath
        ));
        return executeCommand(cmd);
    }

    public boolean concatVideos(List<String> inputPaths, String outputPath) {
        if (inputPaths == null || inputPaths.isEmpty()) return false;

        // 先统一每个片段的分辨率/帧率/编码，再用 concat demuxer 合并
        List<String> normalizedPaths = new ArrayList<>();
        try {
            for (int i = 0; i < inputPaths.size(); i++) {
                File tempFile = File.createTempFile("concat_norm_" + i + "_", ".mp4");
                List<String> normCmd = new ArrayList<>(Arrays.asList(
                        ffmpegPath, "-y",
                        "-i", inputPaths.get(i),
                        "-vf", "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,format=yuv420p",
                        "-c:v", "libx264", "-preset", "fast",
                        "-c:a", "aac", "-ar", "44100", "-ac", "2",
                        "-movflags", "+faststart",
                        tempFile.getAbsolutePath()
                ));
                if (!executeCommand(normCmd) || !tempFile.exists() || tempFile.length() == 0) {
                    for (String p : normalizedPaths) new File(p).delete();
                    return false;
                }
                normalizedPaths.add(tempFile.getAbsolutePath());
            }

            File listFile = File.createTempFile("ffmpeg_concat_", ".txt");
            try (PrintWriter writer = new PrintWriter(listFile)) {
                for (String path : normalizedPaths) {
                    writer.println("file '" + path.replace('\\', '/').replace("'", "'\\''") + "'");
                }
            }
            List<String> cmd = new ArrayList<>(Arrays.asList(
                    ffmpegPath, "-y",
                    "-f", "concat", "-safe", "0",
                    "-i", listFile.getAbsolutePath(),
                    "-c", "copy",
                    "-movflags", "+faststart",
                    outputPath
            ));
            boolean result = executeCommand(cmd);
            listFile.delete();
            for (String p : normalizedPaths) new File(p).delete();
            return result;
        } catch (IOException e) {
            for (String p : normalizedPaths) new File(p).delete();
            return false;
        }
    }

    public boolean addBackgroundMusic(String videoPath, String audioPath, String outputPath, float volume) {
        List<String> cmdWithMix = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", videoPath,
                "-i", audioPath,
                "-filter_complex",
                "[0:a]volume=1.0[a0];[1:a]volume=" + volume + "[a1];[a0][a1]amix=inputs=2:duration=first:normalize=0[aout]",
                "-map", "0:v", "-map", "[aout]",
                "-c:v", "libx264", "-preset", "fast", "-c:a", "aac", "-b:a", "192k",
                "-movflags", "+faststart",
                "-shortest",
                outputPath
        ));
        if (executeCommand(cmdWithMix)) return true;

        List<String> cmdNoMix = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", videoPath,
                "-i", audioPath,
                "-filter_complex",
                "[1:a]volume=" + volume + "[aout]",
                "-map", "0:v", "-map", "[aout]",
                "-c:v", "libx264", "-preset", "fast", "-c:a", "aac", "-b:a", "192k",
                "-movflags", "+faststart",
                "-shortest",
                outputPath
        ));
        return executeCommand(cmdNoMix);
    }

    public boolean separateVoice(String inputPath, String voiceOutput, String bgOutput) {
        boolean v = executeCommand(new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y", "-i", inputPath,
                "-af", "highpass=f=300,lowpass=f=3000",
                "-c:a", "aac", voiceOutput
        )));
        boolean b = executeCommand(new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y", "-i", inputPath,
                "-af", "lowpass=f=300",
                "-c:a", "aac", bgOutput
        )));
        return v && b;
    }

    public boolean changeAspectRatio(String inputPath, String outputPath, String ratio) {
        String scale;
        switch (ratio == null ? "16:9" : ratio) {
            case "9:16" ->
                    scale = "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2";
            case "1:1" ->
                    scale = "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2";
            case "4:3" ->
                    scale = "scale=1440:1080:force_original_aspect_ratio=decrease,pad=1440:1080:(ow-iw)/2:(oh-ih)/2";
            case "3:4" ->
                    scale = "scale=1080:1440:force_original_aspect_ratio=decrease,pad=1080:1440:(ow-iw)/2:(oh-ih)/2";
            default ->
                    scale = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2";
        }
        List<String> cmd = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", inputPath,
                "-vf", scale,
                "-c:v", "libx264", "-c:a", "aac",
                "-preset", "fast",
                "-movflags", "+faststart",
                outputPath
        ));
        return executeCommand(cmd);
    }

    public boolean convertFormat(String inputPath, String outputPath, String format) {
        List<String> cmd = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", inputPath,
                "-c:v", "libx264", "-c:a", "aac",
                "-preset", "fast",
                "-movflags", "+faststart",
                outputPath
        ));
        return executeCommand(cmd);
    }

    public boolean addTransition(String input1, String input2, String outputPath, String transitionType, double duration) {
        Map<String, Object> info1 = getVideoInfo(input1);
        Object d = info1.get("duration");
        double video1Duration = (d instanceof Number n) ? n.doubleValue() : 5.0;
        double offset = Math.max(0, video1Duration - duration);

        String xfadeType = switch (transitionType == null ? "fade" : transitionType) {
            case "slide" -> "slideleft";
            case "zoom" -> "smoothup";
            case "rotate" -> "circleopen";
            case "wipe" -> "wipeleft";
            default -> "fade";
        };

        String filter = String.format(
                "[0:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,format=yuv420p[v0];" +
                "[1:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,format=yuv420p[v1];" +
                "[v0][v1]xfade=transition=%s:duration=%.1f:offset=%.1f[outv]",
                xfadeType, duration, offset);

        List<String> cmd = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", input1, "-i", input2,
                "-filter_complex", filter,
                "-map", "[outv]", "-map", "0:a?",
                "-c:v", "libx264", "-c:a", "aac",
                "-preset", "fast",
                "-movflags", "+faststart",
                outputPath
        ));
        return executeCommand(cmd);
    }

    /** 将字幕文本烧录到视频画面上（drawtext） */
    public boolean burnSubtitle(String inputPath, String outputPath, String subtitleText) {
        String escaped = subtitleText
                .replace("\\", "\\\\\\\\")
                .replace("'", "'\\\\\\''")
                .replace(":", "\\\\:")
                .replace("[", "\\\\[")
                .replace("]", "\\\\]")
                .replace("\n", " ");
        String fontFile = "C\\\\:/Windows/Fonts/msyh.ttc";
        String drawtext = String.format(
                "drawtext=fontfile='%s':text='%s':fontsize=28:fontcolor=white:borderw=2:bordercolor=black:" +
                "x=(w-text_w)/2:y=h-th-50", fontFile, escaped);
        List<String> cmd = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", inputPath,
                "-vf", drawtext,
                "-c:v", "libx264", "-c:a", "aac",
                "-preset", "fast",
                "-movflags", "+faststart",
                outputPath
        ));
        return executeCommand(cmd);
    }

    /** 添加滤镜效果 */
    public boolean applyFilter(String inputPath, String outputPath, String filterType) {
        String vf;
        switch (filterType == null ? "none" : filterType) {
            case "warm" -> vf = "colorbalance=rs=0.15:gs=0.05:bs=-0.1";
            case "cool" -> vf = "colorbalance=rs=-0.1:gs=0.0:bs=0.15";
            case "vintage" -> vf = "curves=vintage";
            case "bw" -> vf = "hue=s=0";
            case "bright" -> vf = "eq=brightness=0.1:contrast=1.1:saturation=1.2";
            case "film" -> vf = "colorbalance=rs=0.1:gs=0.05:bs=-0.05,noise=alls=20:allf=t+u";
            default -> { return true; }
        }
        List<String> cmd = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", inputPath,
                "-vf", vf,
                "-c:v", "libx264", "-c:a", "aac",
                "-preset", "fast",
                "-movflags", "+faststart",
                outputPath
        ));
        return executeCommand(cmd);
    }

    public boolean fastStart(String inputPath, String outputPath) {
        List<String> cmd = new ArrayList<>(Arrays.asList(
                ffmpegPath, "-y",
                "-i", inputPath,
                "-c", "copy",
                "-movflags", "+faststart",
                outputPath
        ));
        return executeCommand(cmd);
    }

    public Map<String, Object> getVideoInfo(String videoPath) {
        Map<String, Object> info = new HashMap<>();
        try {
            List<String> cmd = Arrays.asList(
                    ffmpegPath.replace("ffmpeg", "ffprobe"),
                    "-v", "quiet",
                    "-print_format", "json",
                    "-show_format", "-show_streams",
                    videoPath
            );
            ProcessBuilder pb = new ProcessBuilder(cmd);
            pb.redirectErrorStream(true);
            Process process = pb.start();
            StringBuilder output = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line);
                }
            }
            process.waitFor();
            String raw = output.toString();
            info.put("raw", raw);

            Double duration = extractDouble(raw, "\"duration\"\\s*:\\s*\"([0-9.]+)\"");
            Integer width = extractInt(raw, "\"width\"\\s*:\\s*(\\d+)");
            Integer height = extractInt(raw, "\"height\"\\s*:\\s*(\\d+)");
            if (duration != null) info.put("duration", duration);
            if (width != null) info.put("width", width);
            if (height != null) info.put("height", height);
        } catch (Exception e) {
            info.put("error", e.getMessage());
        }
        return info;
    }

    public double calculateFrameClarity(String videoPath, double timestamp) {
        try {
            File tempFrame = File.createTempFile("frame_", ".png");
            List<String> extractCmd = Arrays.asList(
                    ffmpegPath, "-y",
                    "-ss", String.valueOf(timestamp),
                    "-i", videoPath,
                    "-vframes", "1",
                    tempFrame.getAbsolutePath()
            );
            boolean extracted = executeCommand(new ArrayList<>(extractCmd));
            if (!extracted || !tempFrame.exists()) {
                tempFrame.delete();
                return 0;
            }

            long fileSize = tempFrame.length();
            tempFrame.delete();

            double score = Math.min(100.0, Math.max(0.0, (fileSize / 250000.0) * 100.0));
            return score;
        } catch (Exception e) {
            return 0;
        }
    }

    public List<Map<String, Object>> detectSpeechSegments(String videoPath) {
        List<Map<String, Object>> segments = new ArrayList<>();
        try {
            String output = executeCommandWithOutput(Arrays.asList(
                    ffmpegPath,
                    "-i", videoPath,
                    "-af", "silencedetect=noise=-30dB:d=0.4",
                    "-f", "null",
                    "-"
            ));

            List<Double> silenceStarts = new ArrayList<>();
            List<Double> silenceEnds = new ArrayList<>();

            java.util.regex.Matcher startMatcher = java.util.regex.Pattern
                    .compile("silence_start:\\s*([0-9.]+)")
                    .matcher(output);
            while (startMatcher.find()) {
                silenceStarts.add(Double.parseDouble(startMatcher.group(1)));
            }

            java.util.regex.Matcher endMatcher = java.util.regex.Pattern
                    .compile("silence_end:\\s*([0-9.]+)")
                    .matcher(output);
            while (endMatcher.find()) {
                silenceEnds.add(Double.parseDouble(endMatcher.group(1)));
            }

            double duration = 0;
            Map<String, Object> info = getVideoInfo(videoPath);
            Object d = info.get("duration");
            if (d instanceof Number n) {
                duration = n.doubleValue();
            }

            double cursor = 0;
            int pairCount = Math.min(silenceStarts.size(), silenceEnds.size());
            for (int i = 0; i < pairCount; i++) {
                double silenceStart = silenceStarts.get(i);
                double silenceEnd = silenceEnds.get(i);
                if (silenceStart > cursor + 0.3) {
                    Map<String, Object> segment = new HashMap<>();
                    segment.put("start", round2(cursor));
                    segment.put("end", round2(silenceStart));
                    segments.add(segment);
                }
                cursor = Math.max(cursor, silenceEnd);
            }

            if (duration > cursor + 0.3) {
                Map<String, Object> segment = new HashMap<>();
                segment.put("start", round2(cursor));
                segment.put("end", round2(duration));
                segments.add(segment);
            }
        } catch (Exception ignored) {
        }
        return segments;
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private Double extractDouble(String text, String regex) {
        try {
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile(regex).matcher(text);
            if (matcher.find()) {
                return Double.parseDouble(matcher.group(1));
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    private Integer extractInt(String text, String regex) {
        try {
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile(regex).matcher(text);
            if (matcher.find()) {
                return Integer.parseInt(matcher.group(1));
            }
        } catch (Exception ignored) {
        }
        return null;
    }

    private boolean executeCommand(List<String> command) {
        try {
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.redirectErrorStream(true);
            Process process = pb.start();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                while (reader.readLine() != null) { }
            }
            int exitCode = process.waitFor();
            return exitCode == 0;
        } catch (Exception e) {
            return false;
        }
    }

    private String executeCommandWithOutput(List<String> command) {
        StringBuilder output = new StringBuilder();
        try {
            ProcessBuilder pb = new ProcessBuilder(command);
            pb.redirectErrorStream(true);
            Process process = pb.start();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    output.append(line).append('\n');
                }
            }
            process.waitFor();
        } catch (Exception ignored) {
        }
        return output.toString();
    }
}
