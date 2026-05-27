import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import numpy as np
import os

plt.rcParams['font.family'] = 'SimSun'
plt.rcParams['font.size'] = 14
plt.rcParams['axes.unicode_minus'] = False

OUTPUT_DIR = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def draw_box(ax, x, y, w, h, text, color='white', edge_color='black', fontsize=13, bold=False, text_color='black'):
    box = FancyBboxPatch((x - w/2, y - h/2), w, h,
                         boxstyle="round,pad=0.05",
                         facecolor=color, edgecolor=edge_color, linewidth=1.5)
    ax.add_patch(box)
    weight = 'bold' if bold else 'normal'
    ax.text(x, y, text, ha='center', va='center', fontsize=fontsize,
            fontfamily='SimSun', fontweight=weight, color=text_color)

def draw_arrow(ax, x1, y1, x2, y2, color='black'):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color=color, lw=1.5))

def draw_double_arrow(ax, x1, y1, x2, y2, color='black'):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='<->', color=color, lw=1.5))

# ============================================================
# 图3.1 系统总体架构图
# ============================================================
def gen_fig31():
    fig, ax = plt.subplots(1, 1, figsize=(14, 10))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 10)
    ax.axis('off')

    # Layer 1: 移动端表示层
    layer1 = FancyBboxPatch((0.5, 7.2), 13, 2.3, boxstyle="round,pad=0.1",
                            facecolor='white', edgecolor='black', linewidth=2)
    ax.add_patch(layer1)
    ax.text(7, 9.15, '移动端表示层（Flutter + Dart）', ha='center', va='center',
            fontsize=16, fontfamily='SimSun', fontweight='bold', color='black')

    draw_box(ax, 2.5, 8.0, 3.0, 0.8, 'Provider\n状态管理', 'white', 'black', 12)
    draw_box(ax, 5.8, 8.0, 2.8, 0.8, 'Dio\n网络通信', 'white', 'black', 12)
    draw_box(ax, 9.0, 8.0, 3.0, 0.8, '界面渲染\n用户交互', 'white', 'black', 12)
    draw_box(ax, 12.0, 8.0, 2.0, 0.8, '路由\n导航', 'white', 'black', 12)

    # Arrow between layers
    ax.annotate('', xy=(7, 6.95), xytext=(7, 7.2),
                arrowprops=dict(arrowstyle='<->', color='black', lw=2.5))
    ax.text(8.5, 7.05, 'HTTP / RESTful API', ha='center', va='center',
            fontsize=12, fontfamily='SimSun', color='white', fontweight='bold')

    # Layer 2: 后端服务层
    layer2 = FancyBboxPatch((0.5, 3.8), 13, 3.0, boxstyle="round,pad=0.1",
                            facecolor='white', edgecolor='black', linewidth=2)
    ax.add_patch(layer2)
    ax.text(7, 6.5, '后端服务层（Spring Boot + Java 17）', ha='center', va='center',
            fontsize=16, fontfamily='SimSun', fontweight='bold', color='black')

    draw_box(ax, 3.0, 5.6, 4.5, 0.7, '控制器层（Controller）', 'white', 'black', 13)
    draw_box(ax, 10.0, 5.6, 4.5, 0.7, 'JWT认证过滤器', 'white', 'black', 13)
    draw_arrow(ax, 3.0, 5.2, 3.0, 4.95)
    draw_box(ax, 3.0, 4.55, 4.5, 0.7, '服务层（Service）', 'white', 'black', 13)
    draw_box(ax, 10.0, 4.55, 4.5, 0.7, 'FFmpeg工具封装', 'white', 'black', 13)
    draw_arrow(ax, 3.0, 4.15, 3.0, 3.95)

    # Arrow between layers
    ax.annotate('', xy=(7, 3.5), xytext=(7, 3.8),
                arrowprops=dict(arrowstyle='<->', color='black', lw=2.5))
    ax.text(8.8, 3.6, 'JDBC / 文件I/O', ha='center', va='center',
            fontsize=12, fontfamily='SimSun', color='white', fontweight='bold')

    # Layer 3: 数据与服务支撑层
    layer3 = FancyBboxPatch((0.5, 0.5), 13, 2.8, boxstyle="round,pad=0.1",
                            facecolor='white', edgecolor='black', linewidth=2)
    ax.add_patch(layer3)
    ax.text(7, 3.0, '数据与服务支撑层', ha='center', va='center',
            fontsize=16, fontfamily='SimSun', fontweight='bold', color='black')

    draw_box(ax, 3.0, 1.8, 3.5, 1.0, 'MySQL\n数据库', 'white', 'black', 14, True)
    draw_box(ax, 7.5, 1.8, 3.5, 1.0, 'FFmpeg\n音视频引擎', 'white', 'black', 14, True)
    draw_box(ax, 11.8, 1.8, 2.8, 1.0, '文件\n存储系统', 'white', 'black', 14, True)

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig31_architecture.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("图3.1 完成")


# ============================================================
# 图3.2 系统功能模块结构图
# ============================================================
def gen_fig32():
    fig, ax = plt.subplots(1, 1, figsize=(16, 9))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 9)
    ax.axis('off')

    # Root
    draw_box(ax, 8, 8.2, 6, 0.9, '移动端短视频智能剪辑系统', 'white', 'black', 16, True)

    # 5 main modules
    modules = [
        (1.8, 6.2, '用户管理\n模块', 'white', 'white'),
        (5.0, 6.2, '视频编辑\n模块', 'white', 'white'),
        (8.2, 6.2, '智能辅助\n模块', 'white', 'white'),
        (11.4, 6.2, '模板管理\n模块', 'white', 'white'),
        (14.2, 6.2, '音乐资源\n模块', 'white', 'white'),
    ]

    for mx, my, mtxt, mc, me in modules:
        draw_box(ax, mx, my, 2.6, 0.9, mtxt, mc, me, 13, True)
        draw_arrow(ax, 8, 7.7, mx, 6.7)

    # Sub-modules
    subs = {
        0: ['注册登录', '个人信息', '头像管理', '密码修改'],
        1: ['视频裁剪', '视频拼接', '转场特效', '滤镜处理', '画面比例', '视频导出'],
        2: ['场景识别', '清晰度分析', '智能剪辑', '智能配乐'],
        3: ['模板浏览', '模板筛选', '模板应用', '热度统计'],
        4: ['音乐浏览', '分类筛选', '在线试听', '人声分离'],
    }

    for idx, (mx, my, mtxt, mc, me) in enumerate(modules):
        sub_list = subs[idx]
        n = len(sub_list)
        start_y = 4.5
        for j, stxt in enumerate(sub_list):
            sy = start_y - j * 0.85
            draw_box(ax, mx, sy, 2.4, 0.6, stxt, 'white', me, 11)
            draw_arrow(ax, mx, my - 0.5, mx, sy + 0.35)

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig32_modules.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("图3.2 完成")


# ============================================================
# 图3.3 系统E-R图
# ============================================================
def gen_fig33():
    fig, ax = plt.subplots(1, 1, figsize=(14, 10))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 10)
    ax.axis('off')

    def draw_entity(ax, x, y, name, attrs, color='white', edge='white'):
        h_title = 0.6
        h_attr = len(attrs) * 0.45 + 0.3
        total_h = h_title + h_attr
        w = 4.0
        # Title
        title_box = FancyBboxPatch((x - w/2, y - h_title/2), w, h_title,
                                   boxstyle="round,pad=0.03", facecolor=edge, edgecolor=edge, linewidth=1.5)
        ax.add_patch(title_box)
        ax.text(x, y, name, ha='center', va='center', fontsize=14,
                fontfamily='SimSun', fontweight='bold', color='black')
        # Attrs
        attr_box = FancyBboxPatch((x - w/2, y - h_title/2 - h_attr), w, h_attr,
                                  boxstyle="round,pad=0.03", facecolor=color, edgecolor=edge, linewidth=1.5)
        ax.add_patch(attr_box)
        for i, attr in enumerate(attrs):
            ay = y - h_title/2 - 0.35 - i * 0.45
            prefix = 'PK ' if i == 0 else '   '
            ax.text(x - w/2 + 0.2, ay, f'{prefix}{attr}', ha='left', va='center',
                    fontsize=11, fontfamily='SimSun')
        return y - h_title/2, y - h_title/2 - h_attr

    def draw_diamond(ax, x, y, text):
        diamond = plt.Polygon([(x, y+0.4), (x+0.8, y), (x, y-0.4), (x-0.8, y)],
                              facecolor='white', edgecolor='black', linewidth=1.5)
        ax.add_patch(diamond)
        ax.text(x, y, text, ha='center', va='center', fontsize=11, fontfamily='SimSun', fontweight='bold')

    # Users entity
    u_top, u_bot = draw_entity(ax, 3, 8.5, '用户（User）',
        ['id（主键）', 'username（用户名）', 'password（密码）', 'nickname（昵称）',
         'email（邮箱）', 'phone（手机号）', 'avatar（头像）'],
        'white', 'white')

    # VideoProject entity
    vp_top, vp_bot = draw_entity(ax, 11, 8.5, '视频项目（VideoProject）',
        ['id（主键）', 'title（项目标题）', 'description（描述）', 'status（状态）',
         'videoUrl（视频地址）', 'userId（外键）', 'templateId（外键）'],
        'white', 'white')

    # MusicResource entity
    mr_top, mr_bot = draw_entity(ax, 3, 3.0, '音乐资源（MusicResource）',
        ['id（主键）', 'title（标题）', 'artist（艺术家）', 'category（分类）',
         'mood（情绪标签）', 'duration（时长）', 'fileUrl（文件地址）'],
        'white', 'white')

    # VideoTemplate entity
    vt_top, vt_bot = draw_entity(ax, 11, 3.0, '视频模板（VideoTemplate）',
        ['id（主键）', 'name（模板名称）', 'description（描述）', 'category（分类）',
         'aspectRatio（画面比例）', 'transitionConfig（转场配置）', 'usageCount（使用次数）'],
        'white', 'white')

    # Relationships
    draw_diamond(ax, 7, 8.5, '创建')
    ax.plot([5, 6.2], [8.5, 8.5], color='black', lw=1.5)
    ax.plot([7.8, 9], [8.5, 8.5], color='black', lw=1.5)
    ax.text(5.5, 8.75, '1', fontsize=13, fontfamily='SimSun', fontweight='bold')
    ax.text(8.5, 8.75, 'N', fontsize=13, fontfamily='SimSun', fontweight='bold')

    draw_diamond(ax, 11, 5.8, '引用')
    ax.plot([11, 11], [vp_bot, 6.2], color='black', lw=1.5)
    ax.plot([11, 11], [5.4, vt_top + 0.05], color='black', lw=1.5)
    ax.text(11.3, 6.5, 'N', fontsize=13, fontfamily='SimSun', fontweight='bold')
    ax.text(11.3, 4.8, '1', fontsize=13, fontfamily='SimSun', fontweight='bold')

    draw_diamond(ax, 7, 3.0, '配乐')
    ax.plot([5, 6.2], [3.0, 3.0], color='black', lw=1.5)
    ax.plot([7.8, 9], [3.0, 3.0], color='black', lw=1.5)
    ax.text(5.8, 3.25, '独立资源', fontsize=10, fontfamily='SimSun', color='black')

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig33_er.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("图3.3 完成")


# ============================================================
# 图4.x 后端服务流程图 - 用户认证
# ============================================================
def gen_flow_auth():
    fig, ax = plt.subplots(1, 1, figsize=(12, 14))
    ax.set_xlim(0, 12)
    ax.set_ylim(0, 14)
    ax.axis('off')

    ax.text(6, 13.5, '用户认证模块流程图', ha='center', va='center',
            fontsize=18, fontfamily='SimSun', fontweight='bold')

    # Start
    ellipse = matplotlib.patches.Ellipse((6, 12.8), 2.5, 0.6, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ellipse)
    ax.text(6, 12.8, '开始', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')

    draw_arrow(ax, 6, 12.5, 6, 12.1)

    # Receive request
    draw_box(ax, 6, 11.7, 4.5, 0.7, '接收HTTP请求\n（登录/注册）', 'white', 'black', 13)
    draw_arrow(ax, 6, 11.3, 6, 10.8)

    # Diamond: login or register?
    diamond = plt.Polygon([(6, 10.7), (7.5, 10.2), (6, 9.7), (4.5, 10.2)],
                          facecolor='white', edgecolor='black', linewidth=2)
    ax.add_patch(diamond)
    ax.text(6, 10.2, '登录/注册?', ha='center', va='center', fontsize=13, fontfamily='SimSun', fontweight='bold')

    # Login branch (left)
    ax.text(4.0, 10.5, '登录', fontsize=12, fontfamily='SimSun', fontweight='bold', color='black')
    ax.plot([4.5, 3], [10.2, 10.2], color='black', lw=1.5)
    ax.annotate('', xy=(3, 9.7), xytext=(3, 10.2), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

    draw_box(ax, 3, 9.3, 3.5, 0.6, '查询用户名对应记录', 'white', 'black', 12)
    draw_arrow(ax, 3, 8.95, 3, 8.5)
    draw_box(ax, 3, 8.15, 3.5, 0.6, 'BCrypt密码比对验证', 'white', 'black', 12)
    draw_arrow(ax, 3, 7.8, 3, 7.4)

    diamond2 = plt.Polygon([(3, 7.3), (4.2, 6.9), (3, 6.5), (1.8, 6.9)],
                           facecolor='white', edgecolor='black', linewidth=1.5)
    ax.add_patch(diamond2)
    ax.text(3, 6.9, '验证\n通过?', ha='center', va='center', fontsize=11, fontfamily='SimSun')

    ax.text(1.3, 7.1, '否', fontsize=12, fontfamily='SimSun', color='red')
    ax.plot([1.8, 0.8], [6.9, 6.9], color='black', lw=1.5)
    ax.annotate('', xy=(0.8, 6.2), xytext=(0.8, 6.9), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))
    draw_box(ax, 1.5, 5.9, 2.2, 0.5, '返回错误', 'white', 'black', 12)

    ax.text(3.5, 6.3, '是', fontsize=12, fontfamily='SimSun', color='black')
    draw_arrow(ax, 3, 6.5, 3, 5.3)

    # Register branch (right)
    ax.text(8.0, 10.5, '注册', fontsize=12, fontfamily='SimSun', fontweight='bold', color='black')
    ax.plot([7.5, 9], [10.2, 10.2], color='black', lw=1.5)
    ax.annotate('', xy=(9, 9.7), xytext=(9, 10.2), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

    draw_box(ax, 9, 9.3, 3.5, 0.6, '检查用户名是否存在', 'white', 'black', 12)
    draw_arrow(ax, 9, 8.95, 9, 8.5)

    diamond3 = plt.Polygon([(9, 8.4), (10.2, 8.0), (9, 7.6), (7.8, 8.0)],
                           facecolor='white', edgecolor='black', linewidth=1.5)
    ax.add_patch(diamond3)
    ax.text(9, 8.0, '已\n存在?', ha='center', va='center', fontsize=11, fontfamily='SimSun')

    ax.text(10.5, 8.2, '是', fontsize=12, fontfamily='SimSun', color='red')
    ax.plot([10.2, 11.2], [8.0, 8.0], color='black', lw=1.5)
    ax.annotate('', xy=(11.2, 7.3), xytext=(11.2, 8.0), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))
    draw_box(ax, 11.2, 7.0, 2.0, 0.5, '返回错误', 'white', 'black', 12)

    ax.text(9.3, 7.4, '否', fontsize=12, fontfamily='SimSun', color='black')
    draw_arrow(ax, 9, 7.6, 9, 7.1)
    draw_box(ax, 9, 6.7, 3.5, 0.6, 'BCrypt加密密码', 'white', 'black', 12)
    draw_arrow(ax, 9, 6.35, 9, 5.95)
    draw_box(ax, 9, 5.6, 3.5, 0.6, '保存用户到数据库', 'white', 'black', 12)
    draw_arrow(ax, 9, 5.25, 9, 4.85)

    # Merge: Generate JWT
    ax.plot([3, 3], [4.8, 4.5], color='black', lw=1.5)
    ax.plot([9, 9], [4.8, 4.5], color='black', lw=1.5)
    ax.plot([3, 9], [4.5, 4.5], color='black', lw=1.5)
    ax.annotate('', xy=(6, 4.1), xytext=(6, 4.5), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

    draw_box(ax, 6, 3.7, 5, 0.7, 'JwtUtil生成JWT令牌\n（包含用户ID信息）', 'white', 'black', 13, True)
    draw_arrow(ax, 6, 3.3, 6, 2.8)
    draw_box(ax, 6, 2.5, 5, 0.6, '封装LoginResponse返回客户端', 'white', 'black', 13)
    draw_arrow(ax, 6, 2.15, 6, 1.7)

    # End
    ellipse2 = matplotlib.patches.Ellipse((6, 1.4), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ellipse2)
    ax.text(6, 1.4, '结束', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig_flow_auth.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("用户认证流程图 完成")


# ============================================================
# 视频处理模块流程图
# ============================================================
def gen_flow_video():
    fig, ax = plt.subplots(1, 1, figsize=(14, 12))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 12)
    ax.axis('off')

    ax.text(7, 11.5, '视频处理模块流程图', ha='center', va='center',
            fontsize=18, fontfamily='SimSun', fontweight='bold')

    # Start
    ellipse = matplotlib.patches.Ellipse((7, 10.8), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ellipse)
    ax.text(7, 10.8, '接收视频处理请求', ha='center', va='center', fontsize=13, fontfamily='SimSun', fontweight='bold')
    draw_arrow(ax, 7, 10.5, 7, 10.1)

    draw_box(ax, 7, 9.7, 5, 0.7, 'JWT身份认证\n验证用户权限', 'white', 'black', 13)
    draw_arrow(ax, 7, 9.3, 7, 8.8)

    # Operation type decision
    diamond = plt.Polygon([(7, 8.7), (9, 8.2), (7, 7.7), (5, 8.2)],
                          facecolor='white', edgecolor='black', linewidth=2)
    ax.add_patch(diamond)
    ax.text(7, 8.2, '操作类型', ha='center', va='center', fontsize=13, fontfamily='SimSun', fontweight='bold')

    # Branches
    ops = [
        (1.5, 6.5, '视频裁剪', 'FFmpeg -ss/-to\n精确时间截取', 'white', 'white'),
        (4.2, 6.5, '视频拼接', 'FFmpeg concat\n协议无缝拼接', 'white', 'white'),
        (7.0, 6.5, '转场特效', 'FFmpeg xfade\n滤镜处理', 'white', 'white'),
        (9.8, 6.5, '背景音乐', 'FFmpeg amix\n音频混合', 'white', 'white'),
        (12.5, 6.5, '人声分离', 'highpass/lowpass\n频率滤波器', 'white', 'white'),
    ]

    for ox, oy, title, detail, c, e in ops:
        ax.plot([7, ox], [7.7, 7.3], color='black', lw=1.2)
        ax.annotate('', xy=(ox, 7.0), xytext=(ox, 7.3), arrowprops=dict(arrowstyle='->', color='black', lw=1.2))
        draw_box(ax, ox, oy, 2.3, 0.7, title, c, e, 12, True)
        draw_arrow(ax, ox, 6.1, ox, 5.6)
        draw_box(ax, ox, 5.2, 2.3, 0.7, detail, 'white', e, 10)

    # Merge
    for ox, _, _, _, _, _ in ops:
        ax.plot([ox, ox], [4.8, 4.3], color='black', lw=1.2)

    ax.plot([1.5, 12.5], [4.3, 4.3], color='black', lw=1.5)
    ax.annotate('', xy=(7, 3.9), xytext=(7, 4.3), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

    draw_box(ax, 7, 3.5, 5.5, 0.7, 'ProcessBuilder创建子进程\n执行FFmpeg命令', 'white', 'black', 13)
    draw_arrow(ax, 7, 3.1, 7, 2.6)
    draw_box(ax, 7, 2.2, 5.5, 0.7, '检查进程退出码\n合并标准输出与错误输出', 'white', 'black', 13)
    draw_arrow(ax, 7, 1.8, 7, 1.35)

    # End
    ellipse2 = matplotlib.patches.Ellipse((7, 1.0), 3.0, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ellipse2)
    ax.text(7, 1.0, '返回处理结果', ha='center', va='center', fontsize=13, fontfamily='SimSun', fontweight='bold')

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig_flow_video.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("视频处理流程图 完成")


# ============================================================
# 场景识别流程图
# ============================================================
def gen_flow_scene():
    fig, ax = plt.subplots(1, 1, figsize=(13, 15))
    ax.set_xlim(0, 13)
    ax.set_ylim(0, 15)
    ax.axis('off')

    ax.text(6.5, 14.5, '场景识别模块流程图', ha='center', va='center',
            fontsize=18, fontfamily='SimSun', fontweight='bold')

    y = 13.8
    # Start
    ell = matplotlib.patches.Ellipse((6.5, y), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ell)
    ax.text(6.5, y, '输入视频文件', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')
    y -= 0.7
    draw_arrow(ax, 6.5, y+0.35, 6.5, y)

    # Phase 1: CNN
    phase1_box = FancyBboxPatch((0.5, y-2.7), 12, 2.7, boxstyle="round,pad=0.1",
                                facecolor='white', edgecolor='black', linewidth=2, linestyle='--')
    ax.add_patch(phase1_box)
    ax.text(6.5, y-0.1, '阶段一：CNN特征提取', ha='center', va='center',
            fontsize=15, fontfamily='SimSun', fontweight='bold', color='black')

    y -= 0.7
    draw_box(ax, 4, y, 4.5, 0.6, 'FFmpeg均匀采样提取8个关键帧', 'white', 'black', 12)
    draw_box(ax, 10, y, 3.5, 0.6, '提取视频宽高比', 'white', 'black', 12)
    draw_arrow(ax, 4, y-0.35, 4, y-0.75)

    y -= 1.1
    draw_box(ax, 4, y, 4.5, 0.6, '计算每帧Laplacian方差\n作为清晰度特征', 'white', 'black', 12)
    draw_arrow(ax, 4, y-0.35, 6.5, y-0.75)
    draw_arrow(ax, 10, y+0.75, 6.5, y-0.75)

    y -= 1.0
    draw_box(ax, 6.5, y, 5.5, 0.55, '输出空间特征向量（均值/最大/最小/标准差）', 'white', 'black', 12)

    y -= 0.85
    draw_arrow(ax, 6.5, y+0.55, 6.5, y+0.15)

    # Phase 2: LSTM
    phase2_box = FancyBboxPatch((0.5, y-1.8), 12, 2.0, boxstyle="round,pad=0.1",
                                facecolor='white', edgecolor='black', linewidth=2, linestyle='--')
    ax.add_patch(phase2_box)
    ax.text(6.5, y, '阶段二：LSTM时序建模', ha='center', va='center',
            fontsize=15, fontfamily='SimSun', fontweight='bold', color='black')

    y -= 0.7
    draw_box(ax, 4, y, 5, 0.55, '计算相邻帧清晰度变化量\n（运动强度度量）', 'white', 'black', 12)
    draw_box(ax, 10.5, y, 3.5, 0.55, '计算时序趋势特征\n（前后半段差值）', 'white', 'black', 12)
    draw_arrow(ax, 4, y-0.35, 6.5, y-0.75)
    draw_arrow(ax, 10.5, y-0.35, 6.5, y-0.75)

    y -= 1.0
    draw_box(ax, 6.5, y, 5.5, 0.5, '合并时序特征与空间特征 → 完整视频表示向量', 'white', 'black', 12)

    y -= 0.85
    draw_arrow(ax, 6.5, y+0.55, 6.5, y+0.15)

    # Phase 3: Classification
    phase3_box = FancyBboxPatch((0.5, y-2.5), 12, 2.6, boxstyle="round,pad=0.1",
                                facecolor='white', edgecolor='black', linewidth=2, linestyle='--')
    ax.add_patch(phase3_box)
    ax.text(6.5, y, '阶段三：全连接分类', ha='center', va='center',
            fontsize=15, fontfamily='SimSun', fontweight='bold', color='black')

    y -= 0.8
    cats = [('风景', 1.8), ('人像', 4.8), ('运动', 7.8), ('静态', 10.8)]
    for name, cx in cats:
        draw_box(ax, cx, y, 2.2, 0.55, f'{name}场景\n加权评分', 'white', 'black', 11)

    y -= 0.95
    draw_arrow(ax, 1.8, y+0.65, 6.5, y+0.2)
    draw_arrow(ax, 4.8, y+0.65, 6.5, y+0.2)
    draw_arrow(ax, 7.8, y+0.65, 6.5, y+0.2)
    draw_arrow(ax, 10.8, y+0.65, 6.5, y+0.2)

    draw_box(ax, 6.5, y-0.1, 5.5, 0.55, '选取最高分 → 归一化置信度（0.55~0.95）', 'white', 'black', 12)

    y -= 0.85
    draw_arrow(ax, 6.5, y+0.45, 6.5, y+0.1)
    draw_box(ax, 6.5, y-0.2, 5.5, 0.55, '返回JSON：场景类型/标签/置信度/概率分布', 'white', 'black', 12)

    y -= 0.7
    draw_arrow(ax, 6.5, y+0.15, 6.5, y-0.15)
    ell2 = matplotlib.patches.Ellipse((6.5, y-0.4), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ell2)
    ax.text(6.5, y-0.4, '结束', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig_flow_scene.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("场景识别流程图 完成")


# ============================================================
# 字幕生成流程图
# ============================================================
def gen_flow_subtitle():
    fig, ax = plt.subplots(1, 1, figsize=(12, 13))
    ax.set_xlim(0, 12)
    ax.set_ylim(0, 13)
    ax.axis('off')

    ax.text(6, 12.5, '字幕生成模块流程图', ha='center', va='center',
            fontsize=18, fontfamily='SimSun', fontweight='bold')

    y = 11.8
    ell = matplotlib.patches.Ellipse((6, y), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ell)
    ax.text(6, y, '输入视频文件', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')

    y -= 0.8
    draw_arrow(ax, 6, y+0.55, 6, y+0.15)
    draw_box(ax, 6, y-0.1, 5, 0.6, '获取视频总时长信息', 'white', 'black', 13)

    y -= 0.9
    draw_arrow(ax, 6, y+0.5, 6, y+0.15)
    draw_box(ax, 6, y-0.1, 5, 0.65, '按15秒窗口切割为\n多个音频片段', 'white', 'black', 13)

    y -= 1.0
    draw_arrow(ax, 6, y+0.55, 6, y+0.15)

    # Loop box
    loop_box = FancyBboxPatch((1, y-2.6), 10, 2.7, boxstyle="round,pad=0.1",
                              facecolor='white', edgecolor='black', linewidth=2, linestyle='--')
    ax.add_patch(loop_box)
    ax.text(6, y, '循环处理每个音频片段', ha='center', va='center',
            fontsize=14, fontfamily='SimSun', fontweight='bold', color='black')

    y -= 0.75
    draw_box(ax, 4, y, 4.5, 0.55, 'FFmpeg提取音频片段\n转换为PCM格式', 'white', 'black', 12)
    draw_box(ax, 9.5, y, 3.0, 0.55, 'Base64编码\nPCM数据', 'white', 'black', 12)
    draw_arrow(ax, 6.3, y, 8, y)

    y -= 0.85
    draw_box(ax, 6, y, 5.5, 0.55, '调用百度语音识别API\n（dev_pid=80001 普通话模式）', 'white', 'black', 12)

    y -= 0.75
    draw_box(ax, 6, y, 5, 0.5, '获取识别文本结果', 'white', 'black', 12)

    y -= 0.85
    draw_arrow(ax, 6, y+0.6, 6, y+0.15)
    draw_box(ax, 6, y-0.1, 5.5, 0.6, '按时间轴聚合\n生成完整字幕文本', 'white', 'black', 13)

    y -= 1.0
    draw_arrow(ax, 6, y+0.6, 6, y+0.15)

    diamond = plt.Polygon([(6, y), (7.5, y-0.5), (6, y-1), (4.5, y-0.5)],
                          facecolor='white', edgecolor='black', linewidth=2)
    ax.add_patch(diamond)
    ax.text(6, y-0.5, '是否烧录\n字幕?', ha='center', va='center', fontsize=12, fontfamily='SimSun')

    ax.text(8, y-0.2, '是', fontsize=12, fontfamily='SimSun', color='black')
    ax.plot([7.5, 9.5], [y-0.5, y-0.5], color='black', lw=1.5)
    ax.annotate('', xy=(9.5, y-1.2), xytext=(9.5, y-0.5), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))
    draw_box(ax, 9.5, y-1.5, 3.5, 0.55, 'FFmpeg drawtext\n滤镜烧录字幕', 'white', 'black', 12)

    ax.text(5.5, y-1.2, '否', fontsize=12, fontfamily='SimSun', color='black')
    draw_arrow(ax, 6, y-1, 6, y-1.8)

    y -= 2.0
    ax.plot([9.5, 9.5], [y+0.25, y], color='black', lw=1.5)
    ax.plot([6, 9.5], [y, y], color='black', lw=1.5)
    ax.annotate('', xy=(6, y-0.4), xytext=(6, y), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

    draw_box(ax, 6, y-0.7, 4.5, 0.5, '返回字幕文本结果', 'white', 'black', 13)

    y -= 1.3
    draw_arrow(ax, 6, y+0.3, 6, y)
    ell2 = matplotlib.patches.Ellipse((6, y-0.3), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ell2)
    ax.text(6, y-0.3, '结束', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig_flow_subtitle.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("字幕生成流程图 完成")


# ============================================================
# 图4.27 视频编辑操作流程图
# ============================================================
def gen_fig427():
    fig, ax = plt.subplots(1, 1, figsize=(14, 14))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 14)
    ax.axis('off')

    y = 13.3
    ell = matplotlib.patches.Ellipse((7, y), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ell)
    ax.text(7, y, '用户启动应用', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')

    y -= 0.8
    draw_arrow(ax, 7, y+0.55, 7, y+0.15)
    draw_box(ax, 7, y-0.1, 4, 0.6, '登录/注册认证', 'white', 'black', 14)

    y -= 0.9
    draw_arrow(ax, 7, y+0.5, 7, y+0.15)
    draw_box(ax, 7, y-0.1, 4, 0.6, '进入主页', 'white', 'black', 14)

    y -= 0.9
    draw_arrow(ax, 7, y+0.5, 7, y+0.15)
    draw_box(ax, 7, y-0.1, 4.5, 0.6, '创建/选择视频项目', 'white', 'black', 14)

    y -= 0.9
    draw_arrow(ax, 7, y+0.5, 7, y+0.15)
    draw_box(ax, 7, y-0.1, 4.5, 0.6, '进入视频编辑器', 'white', 'black', 14, True)

    y -= 0.9
    draw_arrow(ax, 7, y+0.5, 7, y+0.15)

    # Branch into 5 tabs
    diamond = plt.Polygon([(7, y), (9, y-0.5), (7, y-1), (5, y-0.5)],
                          facecolor='white', edgecolor='black', linewidth=2)
    ax.add_patch(diamond)
    ax.text(7, y-0.5, '选择功能\n标签页', ha='center', va='center', fontsize=12, fontfamily='SimSun', fontweight='bold')

    tabs = [
        (1.8, '基础编辑', '裁剪/拼接/转场/滤镜', 'white', 'white'),
        (4.6, '音频处理', '配乐/音量/人声分离', 'white', 'white'),
        (7.4, '智能辅助', '场景识别/清晰度\n智能剪辑/配乐推荐', 'white', 'white'),
        (10.2, '模板导出', '模板选择/比例调整\n视频导出', 'white', 'white'),
        (12.8, '字幕', '语音转字幕\n字幕烧录', 'white', 'white'),
    ]

    tab_y = y - 2.2
    for tx, tname, tdetail, tc, te in tabs:
        ax.plot([7, tx], [y-1, tab_y+0.9], color='black', lw=1.2)
        draw_box(ax, tx, tab_y+0.5, 2.4, 0.65, tname, tc, te, 12, True)
        draw_arrow(ax, tx, tab_y+0.15, tx, tab_y-0.3)
        draw_box(ax, tx, tab_y-0.7, 2.4, 0.7, tdetail, 'white', te, 10)

    # Merge
    merge_y = tab_y - 1.8
    for tx, _, _, _, _ in tabs:
        ax.plot([tx, tx], [tab_y-1.1, merge_y+0.3], color='black', lw=1.2)
    ax.plot([1.8, 12.8], [merge_y+0.3, merge_y+0.3], color='black', lw=1.5)
    ax.annotate('', xy=(7, merge_y), xytext=(7, merge_y+0.3), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

    draw_box(ax, 7, merge_y-0.35, 5, 0.6, '调用后端API执行处理', 'white', 'black', 14)

    merge_y -= 1.0
    draw_arrow(ax, 7, merge_y+0.35, 7, merge_y)
    draw_box(ax, 7, merge_y-0.35, 5, 0.6, '预览处理结果', 'white', 'black', 14)

    merge_y -= 1.0
    draw_arrow(ax, 7, merge_y+0.35, 7, merge_y)

    diamond2 = plt.Polygon([(7, merge_y-0.05), (8.5, merge_y-0.5), (7, merge_y-0.95), (5.5, merge_y-0.5)],
                           facecolor='white', edgecolor='black', linewidth=1.5)
    ax.add_patch(diamond2)
    ax.text(7, merge_y-0.5, '继续\n编辑?', ha='center', va='center', fontsize=12, fontfamily='SimSun')

    ax.text(9, merge_y-0.3, '是', fontsize=12, fontfamily='SimSun', color='black')
    ax.plot([8.5, 12.5], [merge_y-0.5, merge_y-0.5], color='black', lw=1.5)
    ax.plot([12.5, 12.5], [merge_y-0.5, y-0.5], color='black', lw=1.5)
    ax.annotate('', xy=(9, y-0.5), xytext=(12.5, y-0.5), arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

    ax.text(6.5, merge_y-1.1, '否', fontsize=12, fontfamily='SimSun', color='black')
    merge_y -= 1.5
    draw_arrow(ax, 7, merge_y+0.6, 7, merge_y+0.15)

    draw_box(ax, 7, merge_y-0.15, 4.5, 0.6, '导出最终视频文件', 'white', 'black', 14, True)

    merge_y -= 0.9
    draw_arrow(ax, 7, merge_y+0.4, 7, merge_y)
    ell2 = matplotlib.patches.Ellipse((7, merge_y-0.3), 2.5, 0.5, facecolor='white', edgecolor='black', lw=2)
    ax.add_patch(ell2)
    ax.text(7, merge_y-0.3, '结束', ha='center', va='center', fontsize=14, fontfamily='SimSun', fontweight='bold')

    plt.tight_layout()
    fig.savefig(os.path.join(OUTPUT_DIR, 'fig427_workflow.png'), dpi=200, bbox_inches='tight',
                facecolor='white', edgecolor='none')
    plt.close()
    print("图4.27 完成")


if __name__ == '__main__':
    gen_fig31()
    gen_fig32()
    gen_fig33()
    gen_flow_auth()
    gen_flow_video()
    gen_flow_scene()
    gen_flow_subtitle()
    gen_fig427()
    print("\n所有图表生成完成！")
    print(f"输出目录: {OUTPUT_DIR}")
    for f in os.listdir(OUTPUT_DIR):
        path = os.path.join(OUTPUT_DIR, f)
        size_kb = os.path.getsize(path) / 1024
        print(f"  {f} ({size_kb:.1f} KB)")
