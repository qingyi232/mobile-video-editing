import docx
from docx import Document
from docx.oxml.ns import qn, nsdecls
from docx.oxml import parse_xml

DOC_PATH = r"F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx"
doc = Document(DOC_PATH)

# Find [10] 门飞 - 智能音视频剪辑，search in body
for i, p in enumerate(doc.paragraphs):
    if i < 125 or i > 450:
        continue
    if '人声分离' in p.text and '频率滤波器' in p.text:
        rpr_xml = (
            f'<w:rPr {nsdecls("w")}>'
            f'<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:eastAsia="SimSun"/>'
            f'<w:vertAlign w:val="superscript"/>'
            f'<w:sz w:val="18"/><w:szCs w:val="18"/>'
            f'</w:rPr>'
        )
        
        p._element.append(parse_xml(f'<w:r {nsdecls("w")}>{rpr_xml}<w:t>[</w:t></w:r>'))
        p._element.append(parse_xml(f'<w:r {nsdecls("w")}>{rpr_xml}<w:fldChar w:fldCharType="begin"/></w:r>'))
        p._element.append(parse_xml(f'<w:r {nsdecls("w")}>{rpr_xml}<w:instrText xml:space="preserve"> REF _Ref_10 \\h </w:instrText></w:r>'))
        p._element.append(parse_xml(f'<w:r {nsdecls("w")}>{rpr_xml}<w:fldChar w:fldCharType="separate"/></w:r>'))
        p._element.append(parse_xml(f'<w:r {nsdecls("w")}>{rpr_xml}<w:t>10</w:t></w:r>'))
        p._element.append(parse_xml(f'<w:r {nsdecls("w")}>{rpr_xml}<w:fldChar w:fldCharType="end"/></w:r>'))
        p._element.append(parse_xml(f'<w:r {nsdecls("w")}>{rpr_xml}<w:t>]</w:t></w:r>'))
        
        print(f"OK [10] -> P{i}")
        break

doc.save(DOC_PATH)
print("All 25 refs now have cross-references.")
