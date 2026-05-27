# -*- coding: utf-8 -*-
import zipfile
from lxml import etree

ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
wid = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}id'

for label, doc_path in [
    ('V2', r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v2.docx'),
    ('ORIG', r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改.docx'),
]:
    lines = []
    lines.append('=== {} ==='.format(label))
    with zipfile.ZipFile(doc_path, 'r') as z:
        # Comments
        if 'word/comments.xml' in z.namelist():
            with z.open('word/comments.xml') as f:
                tree = etree.parse(f)
                root = tree.getroot()
                comments = root.findall('.//w:comment', ns)
                lines.append('Comments count: {}'.format(len(comments)))
                for c in comments:
                    cid = c.get(wid)
                    texts = c.findall('.//w:t', ns)
                    text = ''.join(t.text or '' for t in texts)
                    lines.append('  [#{}] {}'.format(cid, text))
        
        # Comment references in body
        with z.open('word/document.xml') as f:
            tree = etree.parse(f)
            root = tree.getroot()
            body = root.find('.//w:body', ns)
            paragraphs = body.findall('./w:p', ns)
            
            lines.append('')
            lines.append('Comment refs in body:')
            for i, p in enumerate(paragraphs):
                for elem in p.iter():
                    tag = etree.QName(elem.tag).localname if '}' in elem.tag else elem.tag
                    if 'comment' in tag.lower():
                        eid = elem.get(wid, '?')
                        texts = p.findall('.//w:t', ns)
                        text = ''.join(t.text or '' for t in texts)[:80]
                        lines.append('  [{}] {} id={} | {}'.format(i, tag, eid, text))
    
    lines.append('')
    with open(r'F:\26毕设2\移动端短视频智能剪辑app\论文\v2_orig_comments.txt', 'a', encoding='utf-8') as out:
        out.write('\n'.join(lines) + '\n\n')

print('Done')
