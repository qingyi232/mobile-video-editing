# -*- coding: utf-8 -*-
import zipfile
from lxml import etree

doc_path = r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v3.docx'
ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
wid = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}id'

with zipfile.ZipFile(doc_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = etree.parse(f)
        root = tree.getroot()
        body = root.find('.//w:body', ns)
        paragraphs = body.findall('./w:p', ns)

        lines = []
        lines.append("=== All comment elements by paragraph ===\n")
        
        for i, p in enumerate(paragraphs):
            found = []
            for elem in p.iter():
                tag = etree.QName(elem.tag).localname if '}' in elem.tag else elem.tag
                if 'comment' in tag.lower():
                    eid = elem.get(wid, '?')
                    found.append('{} id={}'.format(tag, eid))
            
            if found:
                texts = p.findall('.//w:t', ns)
                text = ''.join(t.text or '' for t in texts)[:120]
                lines.append('[{}] {}'.format(i, ', '.join(found)))
                lines.append('     ' + text)
                lines.append('')
        
        # Also check around paragraph 270-280 area
        lines.append("\n=== Context paragraphs 266-295 ===\n")
        for i in range(266, min(295, len(paragraphs))):
            p = paragraphs[i]
            texts = p.findall('.//w:t', ns)
            text = ''.join(t.text or '' for t in texts)[:100]
            has_img = bool(p.findall('.//{http://schemas.openxmlformats.org/drawingml/2006/main}blip'))
            lines.append('[{}] img={} | {}'.format(i, has_img, text))

        with open(r'F:\26毕设2\移动端短视频智能剪辑app\论文\comment_locations2.txt', 'w', encoding='utf-8') as out:
            out.write('\n'.join(lines))

print('Done')
