# -*- coding: utf-8 -*-
import docx, json
from docx.oxml.ns import qn

doc_path = r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx'
doc = docx.Document(doc_path)

body = doc.element.body
elements = list(body)
results = []

for i, child in enumerate(elements):
    tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
    if tag != 'p':
        continue
    drawings = child.findall('.//' + qn('wp:inline')) + child.findall('.//' + qn('wp:anchor'))
    for d in drawings:
        blip = d.find('.//' + qn('a:blip'))
        if blip is None:
            continue
        embed = blip.get(qn('r:embed'))
        rel = doc.part.rels.get(embed)
        if not rel:
            continue

        context = []
        for offset in range(-5, 6):
            ci = i + offset
            if 0 <= ci < len(elements):
                el = elements[ci]
                t = el.tag.split('}')[-1] if '}' in el.tag else el.tag
                if t == 'p':
                    text = ''.join(tx.text or '' for tx in el.findall('.//' + qn('w:t')))
                    if text.strip():
                        marker = ' >>>' if ci == i else '    '
                        context.append(f'{marker}[{ci}] {text[:100]}')

        results.append({
            'elem_idx': i,
            'rel_id': embed,
            'target': rel.target_ref,
            'context': context
        })

import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

for r in results:
    print(f"\n=== Image at elem {r['elem_idx']}, rel={r['rel_id']}, target={r['target']} ===")
    for c in r['context']:
        print(c)

print(f"\nTotal images found: {len(results)}")
