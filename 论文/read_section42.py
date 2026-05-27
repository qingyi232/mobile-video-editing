# -*- coding: utf-8 -*-
import docx

doc = docx.Document(r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v3.docx')

lines = []
lines.append('=== 4.2 后端服务实现 (全部小节) ===\n')

for i in range(221, 252):
    p = doc.paragraphs[i]
    t = p.text.strip()
    chars = len(t)
    lines.append('[{}] ({} chars) {}'.format(i, chars, t))

with open(r'F:\26毕设2\移动端短视频智能剪辑app\论文\section42_full.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print('Done')
