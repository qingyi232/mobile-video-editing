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

def table_box(ax, x, y, title, fields, w=3.0, title_h=0.45, row_h=0.3, fs_title=14, fs_field=12):
    total_h = title_h + len(fields) * row_h
    r = FancyBboxPatch((x - w/2, y - total_h), w, total_h, boxstyle="square,pad=0",
                        facecolor='white', edgecolor='black', linewidth=1.5)
    ax.add_patch(r)
    ax.plot([x - w/2, x + w/2], [y - title_h, y - title_h], color='black', linewidth=1.5)
    ax.text(x, y - title_h/2, title, ha='center', va='center', fontsize=fs_title,
            fontfamily='SimSun', fontweight='bold')
    for i, field in enumerate(fields):
        fy = y - title_h - (i + 0.5) * row_h
        ax.text(x - w/2 + 0.15, fy, field, ha='left', va='center', fontsize=fs_field, fontfamily='SimSun')
    return y - total_h

def arrow(ax, x1, y1, x2, y2, label='', lbl_offset=(0, 0.15)):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color='black', lw=1.5))
    if label:
        mx, my = (x1+x2)/2 + lbl_offset[0], (y1+y2)/2 + lbl_offset[1]
        ax.text(mx, my, label, ha='center', va='center', fontsize=12, fontfamily='SimSun')

user_fields = ['id (PK)', 'username', 'password', 'nickname', 'avatar', 'email', 'phone', 'created_at']
project_fields = ['id (PK)', 'title', 'video_url', 'duration', 'status', 'user_id (FK)', 'template_id (FK)', 'project_data']
music_fields = ['id (PK)', 'title', 'artist', 'file_url', 'category', 'mood', 'bpm']
template_fields = ['id (PK)', 'name', 'category', 'config_data', 'aspect_ratio', 'usage_count']

table_box(ax, 2.5, 7.5, 'User（用户表）', user_fields)
table_box(ax, 7.5, 7.5, 'VideoProject（视频项目表）', project_fields)
table_box(ax, 2.5, 3.5, 'MusicResource（音乐资源表）', music_fields)
table_box(ax, 7.5, 3.5, 'VideoTemplate（视频模板表）', template_fields)

ax.annotate('', xy=(6.0, 5.7), xytext=(4.0, 5.7),
            arrowprops=dict(arrowstyle='->', color='black', lw=2))
ax.text(5.0, 6.0, '1 : N', ha='center', va='center', fontsize=13, fontfamily='SimSun', fontweight='bold')
ax.text(5.0, 5.4, '创建', ha='center', va='center', fontsize=12, fontfamily='SimSun')

ax.annotate('', xy=(7.5, 3.5), xytext=(7.5, 4.6),
            arrowprops=dict(arrowstyle='->', color='black', lw=2))
ax.text(8.2, 4.0, 'N : 1', ha='center', va='center', fontsize=13, fontfamily='SimSun', fontweight='bold')
ax.text(8.2, 3.7, '引用', ha='center', va='center', fontsize=12, fontfamily='SimSun')

plt.tight_layout()
plt.savefig(os.path.join(OUTPUT, 'fig33_er.png'), dpi=250, bbox_inches='tight', facecolor='white')
plt.close()
print('fig33 compact done')
