# -*- coding: utf-8 -*-
import docx, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

doc = docx.Document(r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx')

count = 0
for rid, rel in sorted(doc.part.rels.items()):
    if 'image' in rel.reltype:
        count += 1
        print(f'{rid}: {rel.target_ref}')

print(f'\nTotal image rels: {count}')
