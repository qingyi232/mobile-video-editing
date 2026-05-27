import graphviz, os
os.environ['PATH'] += r';C:\Program Files\Graphviz\bin'
OUT = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"

g = graphviz.Digraph('modules', format='png',
    graph_attr={'rankdir': 'TB', 'dpi': '200', 'bgcolor': 'white',
                'fontname': 'SimSun', 'fontsize': '22',
                'nodesep': '0.15', 'ranksep': '0.5',
                'margin': '0.2', 'splines': 'line'},
    node_attr={'fontname': 'SimSun', 'fontsize': '16',
               'shape': 'box', 'style': 'filled',
               'fillcolor': 'white', 'color': 'black',
               'penwidth': '1.5', 'height': '0.4', 'width': '0.8',
               'margin': '0.08,0.04'},
    edge_attr={'color': 'black', 'penwidth': '1.2', 'arrowhead': 'none'})

g.node('root', '移动端短视频\n智能剪辑系统', fontsize='20', penwidth='2', height='0.6')

mods = [
    ('m0', '用户管理\n模块'),
    ('m1', '视频编辑\n模块'),
    ('m2', '智能辅助\n模块'),
    ('m3', '模板管理\n模块'),
    ('m4', '音乐资源\n模块'),
]

subs = [
    ['注册\n登录', '个人\n信息', '头像\n管理', '密码\n修改'],
    ['视频\n裁剪', '视频\n拼接', '转场\n特效', '滤镜\n处理', '画面\n比例', '视频\n导出'],
    ['场景\n识别', '清晰度\n分析', '智能\n剪辑', '智能\n配乐'],
    ['模板\n浏览', '模板\n筛选', '模板\n应用', '热度\n统计'],
    ['音乐\n浏览', '分类\n筛选', '在线\n试听', '人声\n分离'],
]

with g.subgraph() as s:
    s.attr(rank='same')
    for mid, mlabel in mods:
        s.node(mid, mlabel, fontsize='16')

for mid, _ in mods:
    g.edge('root', mid)

for i, (mid, _) in enumerate(mods):
    with g.subgraph() as s:
        s.attr(rank='same')
        for j, sub in enumerate(subs[i]):
            sid = f's{i}_{j}'
            s.node(sid, sub, fontsize='14')
    for j, sub in enumerate(subs[i]):
        sid = f's{i}_{j}'
        g.edge(mid, sid)

g.render(os.path.join(OUT, 'fig32_modules'), cleanup=True)
print('fig32 done')
