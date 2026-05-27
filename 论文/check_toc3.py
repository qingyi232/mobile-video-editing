# -*- coding: utf-8 -*-
import zipfile
from lxml import etree

ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

for label, path in [
    ('V4', r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v4.docx'),
    ('修改', r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改.docx'),
]:
    print(f'=== {label} ===')
    try:
        with zipfile.ZipFile(path, 'r') as z:
            with z.open('word/document.xml') as f:
                tree = etree.parse(f)
                root = tree.getroot()
                body = root.find('.//w:body', ns)
                
                # Search for SDT (structured document tags - often used for TOC)
                sdts = body.findall('.//w:sdt', ns)
                print(f'  SDT count: {len(sdts)}')
                for sdt in sdts:
                    alias = sdt.find('.//w:sdtPr/w:alias', ns)
                    docPartObj = sdt.find('.//w:sdtPr/w:docPartObj/w:docPartGallery', ns)
                    tag = sdt.find('.//w:sdtPr/w:tag', ns)
                    if alias is not None:
                        print(f'  SDT alias: {alias.get(ns["w"]+"val", "?")}')
                    if docPartObj is not None:
                        print(f'  SDT gallery: {docPartObj.get(ns["w"]+"val", "?")}')
                    if tag is not None:
                        print(f'  SDT tag: {tag.get(ns["w"]+"val", "?")}')
                    
                    # Get text content
                    texts = sdt.findall('.//w:t', ns)
                    text = ''.join(t.text or '' for t in texts)[:200]
                    print(f'  SDT text: {text[:100]}')
                
                # Search for TOC field in fldChar
                instrs = body.findall('.//w:instrText', ns)
                for instr in instrs:
                    if instr.text and 'TOC' in instr.text.upper():
                        print(f'  TOC FIELD found: {instr.text.strip()}')
                
                print()
    except Exception as e:
        print(f'  Error: {e}')
        print()
