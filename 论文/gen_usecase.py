import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Ellipse
import os

plt.rcParams['font.family'] = 'SimSun'
plt.rcParams['font.size'] = 16
plt.rcParams['axes.unicode_minus'] = False

OUTPUT_DIR = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"

fig, ax = plt.subplots(1, 1, figsize=(10, 16))
ax.set_xlim(-2, 10)
ax.set_ylim(-1, 17)
ax.axis('off')
ax.set_aspect('equal')

rect = FancyBboxPatch((2.5, -0.3), 7, 17.3, boxstyle="round,pad=0.1",
                       facecolor='white', edgecolor='black', linewidth=2)
ax.add_patch(rect)
ax.text(6.0, 17.3, '移动端短视频智能剪辑APP', ha='center', va='center',
        fontsize=18, fontfamily='SimSun', fontweight='bold')

def draw_actor(ax, x, y, label):
    head = plt.Circle((x, y + 0.4), 0.2, fill=True, facecolor='black', edgecolor='black', linewidth=2)
    ax.add_patch(head)
    ax.plot([x, x], [y + 0.2, y - 0.2], color='black', linewidth=2.5)
    ax.plot([x - 0.35, x + 0.35], [y + 0.05, y + 0.05], color='black', linewidth=2.5)
    ax.plot([x, x - 0.25], [y - 0.2, y - 0.6], color='black', linewidth=2.5)
    ax.plot([x, x + 0.25], [y - 0.2, y - 0.6], color='black', linewidth=2.5)
    ax.text(x, y - 0.9, label, ha='center', va='top', fontsize=16, fontfamily='SimSun')

draw_actor(ax, 0.5, 7.5, '普通用户')

usecases = [
    '注册/登录',
    '个人信息管理',
    '导入视频',
    '截剪拼接视频',
    '添加转场特效',
    '添加滤镜',
    '切换画面比例',
    '场景识别',
    '智能片段筛选',
    '配乐推荐',
    '字幕生成',
    '人声分离',
    '使用模板',
    '导出视频',
]

start_y = 15.5
gap = 1.1
uc_x = 6.0

for idx, label in enumerate(usecases):
    y = start_y - idx * gap
    ellipse = Ellipse((uc_x, y), 3.5, 0.8, fill=True,
                       facecolor='white', edgecolor='black', linewidth=1.5)
    ax.add_patch(ellipse)
    ax.text(uc_x, y, label, ha='center', va='center', fontsize=15, fontfamily='SimSun')
    ax.plot([1.0, uc_x - 1.75], [7.6, y], color='black', linewidth=1.0)

plt.tight_layout()
output_path = os.path.join(OUTPUT_DIR, 'fig21_usecase.png')
plt.savefig(output_path, dpi=200, bbox_inches='tight', facecolor='white')
plt.close()
print(f"Done: {output_path}")
