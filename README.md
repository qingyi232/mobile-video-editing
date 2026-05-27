# 移动端短视频智能剪辑 APP

## 项目概述

本项目为**前后端分离**架构的移动端短视频智能剪辑应用，支持视频导入、片段裁剪/拼接、音频配适、模板应用、智能剪辑等功能。

### 技术栈

| 模块 | 技术 | 版本 |
|------|------|------|
| 后端框架 | Spring Boot | 3.2.5 |
| 后端语言 | Java | 17 |
| 数据库 | MySQL | 8.0+ |
| 移动端框架 | Flutter (Dart) | SDK ^3.8.1 |
| 安全认证 | JWT (jjwt) | 0.12.5 |
| ORM | Spring Data JPA / Hibernate | - |
| 音视频处理 | FFmpeg | 系统安装 |
| 状态管理 | Provider | 6.1.2 |
| HTTP 客户端 | Dio | 5.4.3 |

### 系统架构

```
[Android/iOS Flutter App] --HTTP/REST--> [Spring Boot 后端 :8080] --JDBC--> [MySQL]
                                              |
                                         [FFmpeg 音视频处理]
```

---

## 目录结构

```
├── backend/                    # Spring Boot 后端工程
│   ├── pom.xml                 # Maven 依赖配置
│   └── src/main/
│       ├── java/com/videoedit/
│       │   ├── VideoEditApplication.java   # 启动入口
│       │   ├── config/         # 安全、CORS、JWT过滤器、数据初始化、异常处理
│       │   ├── controller/     # REST 控制器 (Auth/User/Video/Music/Template)
│       │   ├── service/        # 业务逻辑层
│       │   ├── repository/     # 数据访问层 (Spring Data JPA)
│       │   ├── entity/         # 数据实体 (User/VideoProject/MusicResource/VideoTemplate)
│       │   ├── dto/            # 请求/响应 DTO
│       │   └── util/           # 工具类 (JWT、FFmpeg封装)
│       └── resources/
│           └── application.yml # 后端配置 (端口、数据库、JWT、上传路径、FFmpeg)
│
├── frontend/                   # Flutter 移动端工程
│   ├── pubspec.yaml            # Flutter 依赖配置
│   ├── lib/
│   │   ├── main.dart           # 应用入口
│   │   ├── providers/          # 状态管理 (AuthProvider)
│   │   ├── services/           # API 服务封装 (Dio + JWT 拦截器)
│   │   ├── screens/            # 页面 (启动/登录/首页/项目列表/编辑器/音乐/模板/个人中心)
│   │   └── utils/              # 常量、主题
│   └── android/                # Android 工程配置
│
├── 部署与启动说明.txt            # 详细部署文档 (面向部署人员)
├── 代码说明文档.txt              # 代码结构说明 (面向开发人员)
├── 需求文档                     # 项目需求说明
└── README.md                   # 本文件
```

---

## 快速启动 (Quick Start)

### 环境要求

- **JDK 17** (推荐 Eclipse Temurin)
- **Apache Maven 3.8+**
- **MySQL 8.0+**
- **FFmpeg** (加入系统 PATH)
- **Flutter SDK** (stable, ^3.8.1)
- **Android Studio** (含 Android SDK + 模拟器)

### 第一步：创建数据库

```sql
CREATE DATABASE IF NOT EXISTS video_edit
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 第二步：配置后端

编辑 `backend/src/main/resources/application.yml`，修改数据库密码：

```yaml
spring:
  datasource:
    password: 你的MySQL密码    # 默认为 root
```

### 第三步：启动后端

```bash
cd backend
mvn spring-boot:run
```

看到 `Tomcat started on port(s): 8080` 即成功。

### 第四步：配置前端

编辑 `frontend/android/local.properties`：

```properties
sdk.dir=你的AndroidSDK路径
flutter.sdk=你的FlutterSDK路径
```

### 第五步：启动前端

```bash
cd frontend
flutter pub get
flutter run
```

### 第六步：使用

App 启动后点击 **注册** 创建账号，然后登录即可使用全部功能。

---

## API 接口概览

| 模块 | 路径前缀 | 说明 | 鉴权 |
|------|----------|------|------|
| 认证 | `/api/auth` | 登录(`POST /login`)、注册(`POST /register`) | 无需 |
| 用户 | `/api/user` | 个人信息、头像、改密、统计 | 需要 JWT |
| 视频 | `/api/video` | 项目 CRUD、素材上传、裁剪/合成/导出 | 需要 JWT |
| 音乐 | `/api/music` | 音乐列表、推荐 | 需要 JWT |
| 模板 | `/api/templates` | 模板列表 | 需要 JWT |
| 静态资源 | `/uploads/**` | 上传文件的 HTTP 访问 | 公开 |

---

## 核心功能

1. **用户系统** — 注册/登录/JWT鉴权/个人中心/头像上传
2. **视频项目管理** — 创建/编辑/删除视频剪辑项目
3. **视频剪辑** — 片段裁剪、拼接、时间轴编辑
4. **音频配适** — 背景音乐添加、音乐库浏览与推荐
5. **模板系统** — 预设模板一键套用
6. **视频导出** — FFmpeg 驱动的视频渲染与导出
7. **智能功能** — 语音识别(百度ASR)、场景识别

---

## 注意事项

- 模拟器访问本机后端使用 `10.0.2.2:8080`（非 localhost）
- 真机调试需改 `frontend/lib/utils/constants.dart` 中 `baseUrl` 为电脑局域网 IP
- 项目路径建议使用**纯英文路径**以避免编译问题
- 详细部署步骤请参阅 `部署与启动说明.txt`
- 代码架构详解请参阅 `代码说明文档.txt`

---

## 验证清单

- [ ] `java -version` → 17
- [ ] `mvn -v` → Maven 3.8+
- [ ] MySQL 服务运行，`video_edit` 库已创建
- [ ] `ffmpeg -version` → 正常输出
- [ ] 后端启动成功，监听 8080
- [ ] `flutter doctor` 无致命错误
- [ ] `flutter run` → App 安装到模拟器，注册/登录成功
