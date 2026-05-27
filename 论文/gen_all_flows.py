# -*- coding: utf-8 -*-
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import os

plt.rcParams['font.family'] = 'SimSun'
plt.rcParams['axes.unicode_minus'] = False

OUT = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"
os.makedirs(OUT, exist_ok=True)

BW, BH = 2.8, 0.7
DS = 0.55
FS = 12
FSS = 10

def box(ax, cx, cy, text, w=BW, h=BH):
    r = mpatches.FancyBboxPatch((cx-w/2, cy-h/2), w, h,
        boxstyle='square,pad=0', fc='white', ec='black', lw=1.5)
    ax.add_patch(r)
    ax.text(cx, cy, text, ha='center', va='center', fontsize=FS)
    return cy-h/2, cy+h/2

def oval(ax, cx, cy, text, w=1.6, h=0.55):
    e = mpatches.Ellipse((cx, cy), w, h, fc='white', ec='black', lw=1.8)
    ax.add_patch(e)
    ax.text(cx, cy, text, ha='center', va='center', fontsize=FS)
    return cy-h/2, cy+h/2

def diamond(ax, cx, cy, text, s=DS):
    pts = [(cx, cy+s), (cx+s*1.6, cy), (cx, cy-s), (cx-s*1.6, cy)]
    p = plt.Polygon(pts, closed=True, fc='white', ec='black', lw=1.5)
    ax.add_patch(p)
    ax.text(cx, cy, text, ha='center', va='center', fontsize=FSS)
    return cy-s, cy+s, cx-s*1.6, cx+s*1.6

def arr_v(ax, x, y1, y2):
    ax.annotate('', xy=(x, y2), xytext=(x, y1),
                arrowprops=dict(arrowstyle='->', color='black', lw=1.5,
                                connectionstyle='arc3,rad=0'))

def arr_h(ax, x1, x2, y):
    ax.annotate('', xy=(x2, y), xytext=(x1, y),
                arrowprops=dict(arrowstyle='->', color='black', lw=1.5,
                                connectionstyle='arc3,rad=0'))

def line_v(ax, x, y1, y2):
    ax.plot([x, x], [y1, y2], 'k-', lw=1.5, solid_capstyle='butt')

def line_h(ax, x1, x2, y):
    ax.plot([x1, x2], [y, y], 'k-', lw=1.5, solid_capstyle='butt')

def label(ax, x, y, text, ha='center'):
    ax.text(x, y, text, ha=ha, va='center', fontsize=FSS)

GAP = 1.2


def gen_auth():
    fig, ax = plt.subplots(figsize=(9, 15))
    fig.patch.set_facecolor('white')
    ax.set_xlim(-0.5, 9.5); ax.set_ylim(0, 15); ax.axis('off'); ax.set_aspect('equal')

    cx = 4.5
    y = 14.2
    ob, ot = oval(ax, cx, y, '开始')

    y -= GAP
    bb, bt = box(ax, cx, y, '接收登录/注册请求')
    arr_v(ax, cx, ob, bt)

    y -= GAP
    db, dt, dl, dr = diamond(ax, cx, y, '判断请求类型')
    arr_v(ax, cx, bb, dt)

    lx, rx = 2.0, 7.0
    line_h(ax, dl, lx, y)
    label(ax, (dl+lx)/2, y+0.18, '登录')
    line_h(ax, dr, rx, y)
    label(ax, (dr+rx)/2, y+0.18, '注册')

    y_l1 = y - GAP
    bb_l1, bt_l1 = box(ax, lx, y_l1, '查询用户名\n对应记录')
    arr_v(ax, lx, y, bt_l1)
    bb_r1, bt_r1 = box(ax, rx, y_l1, '检查用户名\n是否已存在')
    arr_v(ax, rx, y, bt_r1)

    y_l2 = y_l1 - GAP
    bb_l2, bt_l2 = box(ax, lx, y_l2, 'BCrypt密码比对')
    arr_v(ax, lx, bb_l1, bt_l2)

    y_r2 = y_l1 - GAP
    db2, dt2, dl2, dr2 = diamond(ax, rx, y_r2, '用户名\n已存在？')
    arr_v(ax, rx, bb_r1, dt2)

    y_l3 = y_l2 - GAP
    db3, dt3, dl3, dr3 = diamond(ax, lx, y_l3, '验证通过？')
    arr_v(ax, lx, bb_l2, dt3)

    fail_rx = 9.0
    line_h(ax, dr2, fail_rx, y_r2)
    label(ax, (dr2+fail_rx)/2, y_r2+0.18, '是')
    bb_fr, bt_fr = box(ax, fail_rx, y_l3, '返回\n错误', w=1.2)
    arr_v(ax, fail_rx, y_r2, bt_fr)

    y_r3 = y_r2 - GAP
    bb_r3, bt_r3 = box(ax, rx, y_r3, 'BCrypt加密密码')
    arr_v(ax, rx, db2, bt_r3)
    label(ax, rx+0.2, (db2+bt_r3)/2, '否', ha='left')

    y_r4 = y_r3 - GAP
    bb_r4, bt_r4 = box(ax, rx, y_r4, '保存用户到数据库')
    arr_v(ax, rx, bb_r3, bt_r4)

    fail_lx = 0.0
    line_h(ax, dl3, fail_lx, y_l3)
    label(ax, (dl3+fail_lx)/2, y_l3+0.18, '否')
    bb_fl, bt_fl = box(ax, fail_lx, y_r4, '返回\n错误', w=1.2)
    arr_v(ax, fail_lx, y_l3, bt_fl)

    y_merge = y_r4 - 0.6
    line_v(ax, lx, db3, y_merge)
    label(ax, lx+0.2, (db3+y_merge)/2, '是', ha='left')
    line_h(ax, rx, cx, y_merge)
    line_h(ax, lx, cx, y_merge)

    y_jwt = y_merge - GAP + 0.3
    bb_jwt, bt_jwt = box(ax, cx, y_jwt, '生成JWT令牌\n（包含用户ID信息）')
    arr_v(ax, cx, y_merge, bt_jwt)

    y_resp = y_jwt - GAP
    bb_resp, bt_resp = box(ax, cx, y_resp, '返回响应给客户端')
    arr_v(ax, cx, bb_jwt, bt_resp)

    y_end = y_resp - GAP
    oval(ax, cx, y_end, '结束')
    arr_v(ax, cx, bb_resp, y_end+0.28)

    fig.savefig(os.path.join(OUT, 'fig_flow_auth.png'), dpi=200, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print('fig_flow_auth.png done')


def gen_video():
    fig, ax = plt.subplots(figsize=(8, 14))
    fig.patch.set_facecolor('white')
    ax.set_xlim(-0.5, 8.5); ax.set_ylim(0, 14); ax.axis('off'); ax.set_aspect('equal')

    cx = 3.5; y = 13.2
    ob, ot = oval(ax, cx, y, '开始')

    y -= GAP
    bb1, bt1 = box(ax, cx, y, '接收视频处理请求')
    arr_v(ax, cx, ob, bt1)

    y -= GAP
    bb2, bt2 = box(ax, cx, y, '获取视频文件路径')
    arr_v(ax, cx, bb1, bt2)

    y -= GAP
    db, dt, dl, dr = diamond(ax, cx, y, '判断操作类型')
    arr_v(ax, cx, bb2, dt)

    fail_x = 7.0
    line_h(ax, dr, fail_x, y)
    label(ax, (dr+fail_x)/2, y+0.18, '无效')
    bb_f, bt_f = box(ax, fail_x, y - GAP, '返回参数错误', w=2.2)
    arr_v(ax, fail_x, y, bt_f)

    y -= GAP
    bb3, bt3 = box(ax, cx, y, '执行对应FFmpeg命令\n（裁剪/拼接/转场/导出）')
    arr_v(ax, cx, db, bt3)
    label(ax, cx+0.2, (db+bt3)/2, '有效', ha='left')

    y -= GAP
    bb4, bt4 = box(ax, cx, y, '检查进程退出码')
    arr_v(ax, cx, bb3, bt4)

    y -= GAP
    db2, dt2, dl2, dr2 = diamond(ax, cx, y, '处理成功？')
    arr_v(ax, cx, bb4, dt2)

    lx2, rx2 = 1.5, 5.5
    line_h(ax, dl2, lx2, y)
    label(ax, (dl2+lx2)/2, y+0.18, '是')
    line_h(ax, dr2, rx2, y)
    label(ax, (dr2+rx2)/2, y+0.18, '否')

    y -= GAP
    bb_ok, bt_ok = box(ax, lx2, y, '返回处理结果', w=2.2)
    arr_v(ax, lx2, y+GAP, bt_ok)
    bb_err, bt_err = box(ax, rx2, y, '返回错误信息', w=2.2)
    arr_v(ax, rx2, y+GAP, bt_err)

    y_merge = y - 0.5
    line_v(ax, lx2, bb_ok, y_merge)
    line_v(ax, rx2, bb_err, y_merge)
    line_h(ax, lx2, cx, y_merge)
    line_h(ax, rx2, cx, y_merge)

    y -= GAP
    ob2, ot2 = oval(ax, cx, y, '结束')
    arr_v(ax, cx, y_merge, ot2)

    fig.savefig(os.path.join(OUT, 'fig_flow_video.png'), dpi=200, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print('fig_flow_video.png done')


def gen_subtitle():
    fig, ax = plt.subplots(figsize=(8, 16))
    fig.patch.set_facecolor('white')
    ax.set_xlim(-0.5, 8.5); ax.set_ylim(0, 16); ax.axis('off'); ax.set_aspect('equal')

    cx = 3.5; y = 15.2
    ob, ot = oval(ax, cx, y, '开始')

    steps = ['获取视频总时长', '按15秒窗口切割音频片段',
             'FFmpeg提取音频\n转PCM格式', 'Base64编码PCM数据',
             '调用百度语音识别API\n（dev_pid=80001）']

    prev_b = ob
    for s in steps:
        y -= GAP
        bb, bt = box(ax, cx, y, s)
        arr_v(ax, cx, prev_b, bt)
        prev_b = bb

    y -= GAP
    db, dt, dl, dr = diamond(ax, cx, y, '识别成功？')
    arr_v(ax, cx, prev_b, dt)

    lx, rx = 1.5, 6.0
    line_h(ax, dl, lx, y)
    label(ax, (dl+lx)/2, y+0.18, '是')
    line_h(ax, dr, rx, y)
    label(ax, (dr+rx)/2, y+0.18, '否')

    y -= GAP
    bb_ok, bt_ok = box(ax, lx, y, '提取识别文本')
    arr_v(ax, lx, y+GAP, bt_ok)
    bb_skip, bt_skip = box(ax, rx, y, '跳过该片段', w=2.0)
    arr_v(ax, rx, y+GAP, bt_skip)

    loop_y = prev_b - 0.15
    line_v(ax, rx, bb_skip, bb_skip-0.3)
    line_h(ax, rx, rx+1.2, bb_skip-0.3)
    line_v(ax, rx+1.2, bb_skip-0.3, loop_y)
    line_h(ax, rx+1.2, cx+BW/2, loop_y)

    y -= GAP
    bb_agg, bt_agg = box(ax, lx, y, '按时间轴聚合\n生成完整字幕')
    arr_v(ax, lx, bb_ok, bt_agg)

    y_merge = y - 0.4
    line_v(ax, lx, bb_agg, y_merge)
    line_h(ax, lx, cx, y_merge)

    y -= GAP
    bb_ret, bt_ret = box(ax, cx, y, '返回字幕文本')
    arr_v(ax, cx, y_merge, bt_ret)

    y -= GAP
    oval(ax, cx, y, '结束')
    arr_v(ax, cx, bb_ret, y+0.28)

    fig.savefig(os.path.join(OUT, 'fig_flow_subtitle.png'), dpi=200, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print('fig_flow_subtitle.png done')


def gen_scene():
    fig, ax = plt.subplots(figsize=(8, 16))
    fig.patch.set_facecolor('white')
    ax.set_xlim(-0.5, 8.5); ax.set_ylim(0, 16); ax.axis('off'); ax.set_aspect('equal')

    cx = 4.0; y = 15.2
    ob, ot = oval(ax, cx, y, '开始')

    steps = [
        'FFmpeg均匀采样\n提取8个关键帧',
        '计算每帧Laplacian方差\n（清晰度特征）',
        '提取视频宽高比\n（构图特征）',
        '计算帧级统计特征\n（均值/最大/最小/标准差）',
        '计算相邻帧清晰度变化量\n（运动强度）',
        '计算时序趋势特征',
        '加权评分\n（风景/人像/运动/静态）',
        '选取最高分场景类型',
        '归一化置信度\n（0.55~0.95）',
        '返回JSON结果',
    ]

    prev_b = ob
    for s in steps:
        y -= GAP
        bb, bt = box(ax, cx, y, s)
        arr_v(ax, cx, prev_b, bt)
        prev_b = bb

    y -= GAP
    oval(ax, cx, y, '结束')
    arr_v(ax, cx, prev_b, y+0.28)

    fig.savefig(os.path.join(OUT, 'fig_flow_scene.png'), dpi=200, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print('fig_flow_scene.png done')


def gen_workflow():
    fig, ax = plt.subplots(figsize=(8, 16))
    fig.patch.set_facecolor('white')
    ax.set_xlim(-0.5, 8.5); ax.set_ylim(0, 16); ax.axis('off'); ax.set_aspect('equal')

    cx = 3.5; y = 15.2
    ob, ot = oval(ax, cx, y, '开始')

    steps = [
        '登录/注册认证', '进入主页', '创建/选择视频项目',
        '进入视频编辑器', '基础编辑\n（裁剪/拼接/转场/滤镜）',
        '智能辅助\n（场景识别/配乐/字幕）', '预览处理结果',
    ]

    prev_b = ob
    for s in steps:
        y -= GAP
        bb, bt = box(ax, cx, y, s)
        arr_v(ax, cx, prev_b, bt)
        prev_b = bb

    edit_back_target = prev_b

    y -= GAP
    db, dt, dl, dr = diamond(ax, cx, y, '是否满意？')
    arr_v(ax, cx, prev_b, dt)

    lx, rx = 1.5, 5.5
    line_h(ax, dl, lx, y)
    label(ax, (dl+lx)/2, y+0.18, '是')
    line_h(ax, dr, rx, y)
    label(ax, (dr+rx)/2, y+0.18, '否')

    y -= GAP
    bb_exp, bt_exp = box(ax, lx, y, '导出最终视频')
    arr_v(ax, lx, y+GAP, bt_exp)
    bb_back, bt_back = box(ax, rx, y, '返回继续编辑')
    arr_v(ax, rx, y+GAP, bt_back)

    line_v(ax, rx, bb_back, bb_back - 0.3)
    line_h(ax, rx, rx+1.5, bb_back - 0.3)
    line_v(ax, rx+1.5, bb_back - 0.3, edit_back_target)
    arr_h(ax, rx+1.5, cx+BW/2, edit_back_target)

    y_merge = y - 0.5
    line_v(ax, lx, bb_exp, y_merge)
    line_h(ax, lx, cx, y_merge)

    y -= GAP
    oval(ax, cx, y, '结束')
    arr_v(ax, cx, y_merge, y+0.28)

    fig.savefig(os.path.join(OUT, 'fig427_workflow.png'), dpi=200, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print('fig427_workflow.png done')


if __name__ == '__main__':
    gen_auth()
    gen_video()
    gen_subtitle()
    gen_scene()
    gen_workflow()
    print('All 5 flowcharts regenerated!')
