import graphviz, os
os.environ['PATH'] += r';C:\Program Files\Graphviz\bin'
OUT = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"

COMMON = {
    'fontname': 'SimSun', 'fontsize': '18',
    'shape': 'box', 'style': 'filled',
    'fillcolor': 'white', 'color': 'black',
    'penwidth': '2', 'margin': '0.2,0.1',
}
EDGE = {'fontname': 'SimSun', 'fontsize': '16', 'color': 'black', 'penwidth': '1.5'}
GRAPH = {'dpi': '200', 'bgcolor': 'white', 'fontname': 'SimSun', 'fontsize': '20',
         'margin': '0.4', 'pad': '0.4', 'splines': 'line'}

def gen_fig32():
    g = graphviz.Digraph('modules', format='png',
        graph_attr={**GRAPH, 'rankdir': 'TB', 'nodesep': '0.3', 'ranksep': '0.8'},
        node_attr=COMMON, edge_attr=EDGE)
    g.node('root', '移动端短视频智能剪辑系统', fontsize='22', penwidth='2.5')
    mods = ['用户管理\n模块', '视频编辑\n模块', '智能辅助\n模块', '模板管理\n模块', '音乐资源\n模块']
    subs = [
        ['注册登录', '个人信息', '头像管理', '密码修改'],
        ['视频裁剪', '视频拼接', '转场特效', '滤镜处理', '画面比例', '视频导出'],
        ['场景识别', '清晰度分析', '智能剪辑', '智能配乐'],
        ['模板浏览', '模板筛选', '模板应用', '热度统计'],
        ['音乐浏览', '分类筛选', '在线试听', '人声分离'],
    ]
    for i, (mod, sub) in enumerate(zip(mods, subs)):
        mid = f'm{i}'
        g.node(mid, mod, fontsize='18')
        g.edge('root', mid)
        for j, s in enumerate(sub):
            sid = f's{i}_{j}'
            g.node(sid, s, fontsize='16', penwidth='1.5')
            g.edge(mid, sid)
    g.render(os.path.join(OUT, 'fig32_modules'), cleanup=True)
    print('fig32 done')

def gen_fig33():
    g = graphviz.Graph('er', format='png', engine='neato',
        graph_attr={**GRAPH, 'overlap': 'false', 'splines': 'line', 'sep': '1.5'},
        node_attr={'fontname': 'SimSun', 'fontsize': '16', 'color': 'black', 'penwidth': '2',
                   'fillcolor': 'white', 'style': 'filled'},
        edge_attr={'fontname': 'SimSun', 'fontsize': '14', 'color': 'black', 'penwidth': '1.5'})
    entities = {
        'user': ('用户\n(User)', [('用户ID','PK'), ('用户名',''), ('密码',''), ('邮箱',''), ('头像',''), ('创建时间','')]),
        'project': ('视频项目\n(VideoProject)', [('项目ID','PK'), ('标题',''), ('源视频路径',''), ('导出路径',''), ('状态',''), ('创建时间','')]),
        'music': ('音乐资源\n(MusicResource)', [('音乐ID','PK'), ('名称',''), ('分类',''), ('情绪标签',''), ('文件路径','')]),
        'template': ('视频模板\n(VideoTemplate)', [('模板ID','PK'), ('名称',''), ('分类',''), ('转场配置',''), ('使用次数','')]),
    }
    for eid, (label, attrs) in entities.items():
        g.node(eid, label, shape='box', fontsize='20', penwidth='2.5')
        for ai, (aname, pk) in enumerate(attrs):
            aid = f'{eid}_a{ai}'
            lbl = f'<<u>{aname}</u>>' if pk == 'PK' else aname
            g.node(aid, lbl, shape='ellipse', fontsize='14', penwidth='1')
            g.edge(eid, aid)
    g.edge('user', 'project', label='1 : N\n创建', fontsize='14', penwidth='2')
    g.edge('project', 'template', label='N : 1\n引用', fontsize='14', penwidth='2')
    g.render(os.path.join(OUT, 'fig33_er'), cleanup=True)
    print('fig33 done')

def gen_flow(name, title, steps):
    g = graphviz.Digraph(name, format='png',
        graph_attr={**GRAPH, 'rankdir': 'TB', 'nodesep': '0.4', 'ranksep': '0.6'},
        node_attr=COMMON, edge_attr=EDGE)
    g.node('start', '开始', shape='ellipse', fontsize='18', penwidth='2.5')
    g.node('end', '结束', shape='ellipse', fontsize='18', penwidth='2.5')
    prev = 'start'
    for i, step in enumerate(steps):
        if isinstance(step, tuple):
            sid = f's{i}'
            g.node(sid, step[0], shape='diamond', fontsize='16')
            g.edge(prev, sid)
            yes_id = f's{i}_y'
            no_id = f's{i}_n'
            g.node(yes_id, step[1], fontsize='16')
            g.node(no_id, step[2], fontsize='16')
            g.edge(sid, yes_id, label='是')
            g.edge(sid, no_id, label='否')
            if len(step) > 3 and step[3] == 'end_no':
                g.edge(no_id, 'end')
            prev = yes_id
        else:
            sid = f's{i}'
            g.node(sid, step, fontsize='16')
            g.edge(prev, sid)
            prev = sid
    g.edge(prev, 'end')
    g.render(os.path.join(OUT, name), cleanup=True)
    print(f'{name} done')

def gen_fig427():
    gen_flow('fig427_workflow', '视频编辑操作流程图', [
        '登录/注册认证',
        '进入主页',
        '创建/选择视频项目',
        '进入视频编辑器',
        '基础编辑\n（裁剪/拼接/转场/滤镜）',
        '智能辅助\n（场景识别/配乐/字幕）',
        '预览处理结果',
        ('是否满意？', '导出最终视频', '返回继续编辑', 'end_no'),
    ])

def gen_flow_auth():
    g = graphviz.Digraph('fig_flow_auth', format='png',
        graph_attr={**GRAPH, 'rankdir': 'TB', 'nodesep': '0.4', 'ranksep': '0.6'},
        node_attr=COMMON, edge_attr=EDGE)
    g.node('start', '开始', shape='ellipse', penwidth='2.5')
    g.node('end', '结束', shape='ellipse', penwidth='2.5')
    g.node('recv', '接收登录/注册请求')
    g.node('check', '判断请求类型', shape='diamond')
    g.node('login_query', '查询用户名对应记录')
    g.node('bcrypt_check', 'BCrypt密码比对')
    g.node('login_ok', '验证通过？', shape='diamond')
    g.node('reg_check', '检查用户名是否已存在')
    g.node('reg_exists', '用户名已存在？', shape='diamond')
    g.node('bcrypt_enc', 'BCrypt加密密码')
    g.node('save_user', '保存用户到数据库')
    g.node('gen_jwt', '生成JWT令牌')
    g.node('resp', '返回响应给客户端')
    g.node('err', '返回错误提示')
    g.edge('start', 'recv')
    g.edge('recv', 'check')
    g.edge('check', 'login_query', label='登录')
    g.edge('check', 'reg_check', label='注册')
    g.edge('login_query', 'bcrypt_check')
    g.edge('bcrypt_check', 'login_ok')
    g.edge('login_ok', 'gen_jwt', label='是')
    g.edge('login_ok', 'err', label='否')
    g.edge('reg_check', 'reg_exists')
    g.edge('reg_exists', 'err', label='是')
    g.edge('reg_exists', 'bcrypt_enc', label='否')
    g.edge('bcrypt_enc', 'save_user')
    g.edge('save_user', 'gen_jwt')
    g.edge('gen_jwt', 'resp')
    g.edge('resp', 'end')
    g.edge('err', 'end')
    g.render(os.path.join(OUT, 'fig_flow_auth'), cleanup=True)
    print('fig_flow_auth done')

def gen_flow_video():
    gen_flow('fig_flow_video', '视频处理模块流程图', [
        '接收视频处理请求',
        '获取视频文件路径',
        ('判断操作类型', '执行对应FFmpeg命令\n（裁剪/拼接/转场/导出）', '返回参数错误'),
        '检查进程退出码',
        ('处理成功？', '返回处理结果', '返回错误信息', 'end_no'),
    ])

def gen_flow_scene():
    gen_flow('fig_flow_scene', '场景识别模块流程图', [
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
    ])

def gen_flow_subtitle():
    gen_flow('fig_flow_subtitle', '字幕生成模块流程图', [
        '获取视频总时长',
        '按15秒窗口切割音频片段',
        'FFmpeg提取音频\n转PCM格式',
        'Base64编码PCM数据',
        '调用百度语音识别API\n（dev_pid=80001）',
        ('识别成功？', '提取识别文本', '跳过该片段', 'end_no'),
        '按时间轴聚合\n生成完整字幕',
        '返回字幕文本',
    ])

gen_fig32()
gen_fig33()
gen_fig427()
gen_flow_auth()
gen_flow_video()
gen_flow_scene()
gen_flow_subtitle()
print('\nAll done!')
