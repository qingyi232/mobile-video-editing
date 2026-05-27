import graphviz, os
os.environ['PATH'] += r';C:\Program Files\Graphviz\bin'
OUT = r"F:\26毕设2\移动端短视频智能剪辑app\论文\figures"

g = graphviz.Digraph('er', format='png',
    graph_attr={'rankdir': 'LR', 'dpi': '200', 'bgcolor': 'white',
                'fontname': 'SimSun', 'fontsize': '18',
                'nodesep': '0.8', 'ranksep': '1.5',
                'margin': '0.3', 'splines': 'line'},
    node_attr={'fontname': 'SimSun', 'fontsize': '14',
               'shape': 'record', 'style': 'filled',
               'fillcolor': 'white', 'color': 'black',
               'penwidth': '1.5'},
    edge_attr={'fontname': 'SimSun', 'fontsize': '14',
               'color': 'black', 'penwidth': '1.5'})

g.node('user', '''{ User（用户表） |
id (PK)\\l
username\\l
password\\l
nickname\\l
avatar\\l
email\\l
phone\\l
created_at\\l
}''', fontsize='16')

g.node('project', '''{ VideoProject（视频项目表） |
id (PK)\\l
title\\l
video_url\\l
duration\\l
status\\l
user_id (FK)\\l
template_id (FK)\\l
project_data\\l
}''', fontsize='16')

g.node('music', '''{ MusicResource（音乐资源表） |
id (PK)\\l
title\\l
artist\\l
file_url\\l
category\\l
mood\\l
bpm\\l
}''', fontsize='16')

g.node('template', '''{ VideoTemplate（视频模板表） |
id (PK)\\l
name\\l
category\\l
config_data\\l
aspect_ratio\\l
usage_count\\l
}''', fontsize='16')

g.edge('user', 'project', label='  1 : N\n  创建  ', dir='both',
       arrowhead='crow', arrowtail='tee')
g.edge('project', 'template', label='  N : 1\n  引用  ', dir='both',
       arrowhead='tee', arrowtail='crow')

g.render(os.path.join(OUT, 'fig33_er'), cleanup=True)
print('fig33 done')
