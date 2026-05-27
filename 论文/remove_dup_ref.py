"""Remove duplicate [6] from P137"""
import docx
from docx import Document
from docx.oxml.ns import qn

DOC_PATH = r"F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx"
doc = Document(DOC_PATH)

# Find P137 and remove the last superscript [6] run (keep first)
para = doc.paragraphs[137]
found_first = False
to_remove = []
for run in para.runs:
    if run.text == '[6]':
        rPr = run._element.find(qn('w:rPr'))
        if rPr is not None:
            va = rPr.find(qn('w:vertAlign'))
            if va is not None and va.get(qn('w:val')) == 'superscript':
                if found_first:
                    to_remove.append(run)
                else:
                    found_first = True

for run in to_remove:
    run._element.getparent().remove(run._element)
    print(f"Removed duplicate [6] from P137")

doc.save(DOC_PATH)
print("Done.")
