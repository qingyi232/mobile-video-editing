import graphviz, os
os.environ['PATH'] += r';C:\Program Files\Graphviz\bin'
OUTPUT = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"

g = graphviz.Digraph('arch', format='png',
    graph_attr={
        'rankdir': 'TB', 'dpi': '200', 'bgcolor': 'white',
        'fontname': 'SimSun', 'fontsize': '20',
        'margin': '0.5', 'pad': '0.5',
        'nodesep': '0.6', 'ranksep': '1.2',
        'compound': 'true',
    },
    node_attr={
        'fontname': 'SimSun', 'fontsize': '16',
        'shape': 'box', 'style': 'filled',
        'fillcolor': 'white', 'color': 'black',
        'penwidth': '2', 'margin': '0.2,0.1',
    },
    edge_attr={
        'fontname': 'SimSun', 'fontsize': '14',
        'color': 'black', 'penwidth': '1.5',
    }
)

with g.subgraph(name='cluster_layer1') as c:
    c.attr(label='移动端表示层（Flutter + Dart）', style='rounded',
           color='black', penwidth='2.5', fontsize='20', labeljust='c',
           fillcolor='white', margin='20')
    with c.subgraph() as s:
        s.attr(rank='same')
        s.node('provider', 'Provider\n状态管理')
        s.node('dio', 'Dio\n网络通信')
        s.node('ui', '界面渲染\n用户交互')
        s.node('router', '路由\n导航')

with g.subgraph(name='cluster_layer2') as c:
    c.attr(label='后端服务层（Spring Boot + Java 17）', style='rounded',
           color='black', penwidth='2.5', fontsize='20', labeljust='c',
           fillcolor='white', margin='20')
    with c.subgraph() as s:
        s.attr(rank='same')
        s.node('controller', '控制器层\n（Controller）')
        s.node('jwt', 'JWT认证\n过滤器')
    with c.subgraph() as s:
        s.attr(rank='same')
        s.node('service', '服务层\n（Service）')
        s.node('ffutil', 'FFmpeg\n工具封装')
    c.edge('controller', 'service', label='调用', dir='both')

with g.subgraph(name='cluster_layer3') as c:
    c.attr(label='数据与服务支撑层', style='rounded',
           color='black', penwidth='2.5', fontsize='20', labeljust='c',
           fillcolor='white', margin='20')
    with c.subgraph() as s:
        s.attr(rank='same')
        s.node('mysql', 'MySQL\n数据库')
        s.node('ffmpeg', 'FFmpeg\n音视频引擎')
        s.node('fs', '文件\n存储系统')

g.edge('ui', 'controller', label='  HTTP / RESTful API  ',
       ltail='cluster_layer1', lhead='cluster_layer2',
       dir='both', style='bold', penwidth='2.5')

g.edge('service', 'mysql', label='  JDBC  ', dir='both',
       ltail='cluster_layer2', lhead='cluster_layer3')
g.edge('service', 'ffmpeg', label='  命令行调用  ',
       ltail='cluster_layer2', lhead='cluster_layer3')
g.edge('service', 'fs', label='  文件I/O  ', dir='both',
       ltail='cluster_layer2', lhead='cluster_layer3')

out = os.path.join(OUTPUT, 'fig31_architecture')
g.render(out, cleanup=True)
print(f'Done: {out}.png')
