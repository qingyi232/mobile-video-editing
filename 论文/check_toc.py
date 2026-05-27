# -*- coding: utf-8 -*-
import docx

doc = docx.Document(r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v4.docx')

lines = []
lines.append('=== TOC area (paragraphs 0-130) ===\n')
for i in range(0, 130):
    p = doc.paragraphs[i]
    t = p.text.strip()
    if t:
        style = p.style.name if p.style else 'None'
        font_info = ''
        if p.runs:
            r = p.runs[0]
            font_info = f'font={r.font.name}, size={r.font.size}, bold={r.font.bold}'
        lines.append(f'[{i}] style={style} | {font_info} | {t[:80]}')

with open(r'F:\26毕设2\移动端短视频智能剪辑app\论文\toc_info.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print('Done')
