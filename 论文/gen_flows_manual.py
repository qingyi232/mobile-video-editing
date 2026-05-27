import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
import matplotlib.patches as mpatches
import os

plt.rcParams['font.family'] = 'SimSun'
plt.rcParams['axes.unicode_minus'] = False

OUTPUT = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"

def box(ax, x, y, w, h, text, fs=13, lw=1.5, style='square'):
    r = FancyBboxPatch((x-w/2, y-h/2), w, h, boxstyle=f"{style},pad=0.02",
                        facecolor='white', edgecolor='black', linewidth=lw)
    ax.add_patch(r)
    ax.text(x, y, text, ha='center', va='center', fontsize=fs, fontfamily='SimSun')

def diamond(ax, x, y, w, h, text, fs=12):
    pts = [(x, y+h/2), (x+w/2, y), (x, y-h/2), (x-w/2, y)]
    poly = plt.Polygon(pts, fill=True, facecolor='white', edgecolor='black', linewidth=1.5)
    ax.add_patch(poly)
    ax.text(x, y, text, ha='center', va='center', fontsize=fs, fontfamily='SimSun')

def oval(ax, x, y, w, h, text, fs=13, lw=2):
    e = mpatches.Ellipse((x, y), w, h, facecolor='white', edgecolor='black', linewidth=lw)
    ax.add_patch(e)
    ax.text(x, y, text, ha='center', va='center', fontsize=fs, fontfamily='SimSun')

def arrow_v(ax, x, y1, y2):
    ax.annotate('', xy=(x, y2), xytext=(x, y1),
                arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

def arrow_h(ax, x1, x2, y):
    ax.annotate('', xy=(x2, y), xytext=(x1, y),
                arrowprops=dict(arrowstyle='->', color='black', lw=1.5))

def line_v(ax, x, y1, y2):
    ax.plot([x, x], [y1, y2], color='black', linewidth=1.5)

def line_h(ax, x1, x2, y):
    ax.plot([x1, x2], [y, y], color='black', linewidth=1.5)

def label(ax, x, y, text, fs=11):
    ax.text(x, y, text, ha='center', va='center', fontsize=fs, fontfamily='SimSun')

def gen_flow_auth():
    fig, ax = plt.subplots(1, 1, figsize=(8, 14))
    ax.set_xlim(0, 8); ax.set_ylim(0, 14); ax.axis('off'); ax.set_aspect('equal')
    cx = 4.0
    oval(ax, cx, 13.5, 1.5, 0.6, '开始')
    arrow_v(ax, cx, 13.2, 12.8)
    box(ax, cx, 12.5, 3.0, 0.6, '接收登录/注册请求')
    arrow_v(ax, cx, 12.2, 11.7)
    diamond(ax, cx, 11.3, 2.5, 0.8, '判断请求类型')

    lx, rx = 2.0, 6.0
    line_h(ax, cx-1.25, lx, 11.3)
    arrow_v(ax, lx, 11.3, 10.7)
    label(ax, 2.8, 11.5, '登录')
    line_h(ax, cx+1.25, rx, 11.3)
    arrow_v(ax, rx, 11.3, 10.7)
    label(ax, 5.3, 11.5, '注册')

    box(ax, lx, 10.4, 2.5, 0.6, '查询用户名\n对应记录', fs=12)
    arrow_v(ax, lx, 10.1, 9.6)
    box(ax, lx, 9.3, 2.5, 0.6, 'BCrypt\n密码比对', fs=12)
    arrow_v(ax, lx, 9.0, 8.5)
    diamond(ax, lx, 8.1, 2.0, 0.7, '验证\n通过？', fs=11)

    box(ax, rx, 10.4, 2.5, 0.6, '检查用户名\n是否已存在', fs=12)
    arrow_v(ax, rx, 10.1, 9.6)
    diamond(ax, rx, 9.2, 2.0, 0.7, '用户名\n已存在？', fs=11)

    line_h(ax, rx+1.0, 7.5, 9.2)
    arrow_v(ax, 7.5, 9.2, 7.7)
    box(ax, 7.5, 7.4, 1.8, 0.6, '返回\n错误', fs=11)
    label(ax, 7.0, 9.5, '是')

    line_h(ax, rx-1.0, rx, 8.8)
    arrow_v(ax, rx, 8.8, 8.3)
    label(ax, 5.3, 8.6, '否')
    box(ax, rx, 8.0, 2.5, 0.6, 'BCrypt\n加密密码', fs=12)
    arrow_v(ax, rx, 7.7, 7.2)
    box(ax, rx, 6.9, 2.5, 0.6, '保存用户\n到数据库', fs=12)

    line_h(ax, lx-1.0, 0.5, 8.1)
    arrow_v(ax, 0.5, 8.1, 7.7)
    box(ax, 0.5, 7.4, 1.2, 0.6, '返回\n错误', fs=10)
    label(ax, 1.3, 8.4, '否')

    arrow_v(ax, lx, 7.7, 6.2)
    label(ax, 1.5, 7.9, '是')

    line_h(ax, rx, cx, 6.6)
    arrow_v(ax, cx, 6.6, 5.8)

    line_h(ax, lx, cx, 5.8)

    box(ax, cx, 5.5, 3.5, 0.6, '生成JWT令牌\n（包含用户ID信息）', fs=12)
    arrow_v(ax, cx, 5.2, 4.7)
    box(ax, cx, 4.4, 3.0, 0.6, '返回响应给客户端')
    arrow_v(ax, cx, 4.1, 3.6)
    oval(ax, cx, 3.3, 1.5, 0.6, '结束')

    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT, 'fig_flow_auth.png'), dpi=250, bbox_inches='tight', facecolor='white')
    plt.close()
    print('fig_flow_auth done')

gen_flow_auth()
