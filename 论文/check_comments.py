# -*- coding: utf-8 -*-
import zipfile
from lxml import etree

doc_path = r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v3.docx'
ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

with zipfile.ZipFile(doc_path, 'r') as z:
    with z.open('word/document.xml') as f:
        tree = etree.parse(f)
        root = tree.getroot()
        body = root.find('.//w:body', ns)
        paragraphs = body.findall('./w:p', ns)

        lines = []
        for i, p in enumerate(paragraphs):
            starts = p.findall('.//w:commentRangeStart', ns)
            ends = p.findall('.//w:commentRangeEnd', ns)
            comment_refs = p.findall('.//w:commentReference', ns)

            if starts or ends or comment_refs:
                texts = p.findall('.//w:t', ns)
                text = ''.join(t.text or '' for t in texts)[:120]

                wid = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}id'
                start_ids = [s.get(wid) for s in starts]
                end_ids = [e.get(wid) for e in ends]
                ref_ids = [r.get(wid) for r in comment_refs]

                info_parts = []
                if start_ids:
                    info_parts.append('START=' + str(start_ids))
                if end_ids:
                    info_parts.append('END=' + str(end_ids))
                if ref_ids:
                    info_parts.append('REF=' + str(ref_ids))

                lines.append('[{}] {}'.format(i, ' | '.join(info_parts)))
                lines.append('     ' + text)
                lines.append('')

        with open(r'F:\26毕设2\移动端短视频智能剪辑app\论文\comment_locations.txt', 'w', encoding='utf-8') as out:
            out.write('\n'.join(lines))

print('Done')
