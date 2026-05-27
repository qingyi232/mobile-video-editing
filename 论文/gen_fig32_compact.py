import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
import os

plt.rcParams['font.family'] = 'SimSun'
plt.rcParams['axes.unicode_minus'] = False

OUTPUT = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"

fig, ax = plt.subplots(1, 1, figsize=(10, 8))
ax.set_xlim(0, 10)
ax.set_ylim(0, 8)
ax.axis('off')
ax.set_aspect('equal')

def box(ax, x, y, w, h, text, fs=13, lw=1.5):
    r = FancyBboxPatch((x - w/2, y - h/2), w, h, boxstyle="square,pad=0",
                        facecolor='white', edgecolor='black', linewidth=lw)
    ax.add_patch(r)
    ax.text(x, y, text, ha='center', va='center', fontsize=fs, fontfamily='SimSun')

def line(ax, x1, y1, x2, y2):
    ax.plot([x1, x2], [y1, y2], color='black', linewidth=1.2, solid_capstyle='butt')

root_x, root_y = 5.0, 7.3
box(ax, root_x, root_y, 4.0, 0.6, '移动端短视频智能剪辑系统', fs=15, lw=2)

modules = [
    (1.0, '用户管理\n模块'),
    (3.0, '视频编辑\n模块'),
    (5.0, '智能辅助\n模块'),
    (7.0, '模板管理\n模块'),
    (9.0, '音乐资源\n模块'),
]
mod_y = 6.0

for mx, mtxt in modules:
    box(ax, mx, mod_y, 1.5, 0.7, mtxt, fs=12)
    line(ax, root_x, root_y - 0.3, root_x, root_y - 0.5)

line(ax, root_x, root_y - 0.5, root_x, mod_y + 0.35 + 0.2)
line(ax, modules[0][0], mod_y + 0.55, modules[-1][0], mod_y + 0.55)
for mx, _ in modules:
    line(ax, mx, mod_y + 0.55, mx, mod_y + 0.35)

subs = [
    ['注册\n登录', '个人\n信息', '头像\n管理', '密码\n修改'],
    ['视频\n裁剪', '视频\n拼接', '转场\n特效', '滤镜\n处理', '画面\n比例', '视频\n导出'],
    ['场景\n识别', '清晰度\n分析', '智能\n剪辑', '智能\n配乐'],
    ['模板\n浏览', '模板\n筛选', '模板\n应用', '热度\n统计'],
    ['音乐\n浏览', '分类\n筛选', '在线\n试听', '人声\n分离'],
]

sub_start_y = 4.8
sub_gap = 0.85
sub_w = 1.0
sub_h = 0.6

for i, (mx, _) in enumerate(modules):
    sub_list = subs[i]
    line(ax, mx, mod_y - 0.35, mx, sub_start_y + sub_h/2 + 0.15)
    for j, stxt in enumerate(sub_list):
        sy = sub_start_y - j * sub_gap
        box(ax, mx, sy, sub_w, sub_h, stxt, fs=11)
        if j > 0:
            line(ax, mx, sy + sub_h/2, mx, sy + sub_h/2 + sub_gap - sub_h)

plt.tight_layout()
plt.savefig(os.path.join(OUTPUT, 'fig32_modules.png'), dpi=250, bbox_inches='tight', facecolor='white')
plt.close()
print('fig32 compact done')
