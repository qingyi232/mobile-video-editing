# -*- coding: utf-8 -*-
import docx

lines = []

# Check audio tab description in ORIG vs V2
for label, doc_path in [
    ('ORIG', r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改.docx'),
    ('V3', r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v3.docx'),
]:
    doc = docx.Document(doc_path)
    lines.append('=== {} ==='.format(label))
    
    # Find audio tab, template tab, and video processing sections
    for i, p in enumerate(doc.paragraphs):
        t = p.text.strip()
        if '音频标签页' in t and len(t) > 20:
            lines.append('\n[{}] AUDIO TAB ({} chars):'.format(i, len(t)))
            lines.append(t[:300])
        if '模板导出标签页' in t or '模板导出' in t and '标签页' in t:
            if len(t) > 20:
                lines.append('\n[{}] TEMPLATE TAB ({} chars):'.format(i, len(t)))
                lines.append(t[:300])
        if '模板选择界面' in t and len(t) > 10:
            lines.append('\n[{}] TEMPLATE SELECTION ({} chars):'.format(i, len(t)))
            lines.append(t[:200])
        if '音乐选择界面' in t and len(t) > 10:
            lines.append('\n[{}] MUSIC SELECTION ({} chars):'.format(i, len(t)))
            lines.append(t[:200])
        if '视频处理模块' in t and len(t) > 20:
            lines.append('\n[{}] VIDEO PROC ({} chars):'.format(i, len(t)))
            lines.append(t[:300])
    
    lines.append('\n' + '='*50 + '\n')

with open(r'F:\26毕设2\移动端短视频智能剪辑app\论文\content_compare.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print('Done')
