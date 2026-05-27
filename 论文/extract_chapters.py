import docx
from docx.oxml.ns import qn

doc_path = r"F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20.docx"
doc = docx.Document(doc_path)

output_lines = []

in_ch3 = False
in_ch4 = False
in_ch5 = False

for i, para in enumerate(doc.paragraphs):
    text = para.text.strip()
    style_name = para.style.name if para.style else "None"
    
    if '系统设计' in text and ('Heading' in style_name or '标题' in style_name):
        in_ch3 = True
        in_ch4 = False
    if '系统实现' in text and ('Heading' in style_name or '标题' in style_name):
        in_ch3 = False
        in_ch4 = True
    if '系统测试' in text and ('Heading' in style_name or '标题' in style_name):
        in_ch4 = False
        in_ch5 = True
    if '总结' in text and ('Heading' in style_name or '标题' in style_name):
        in_ch5 = False

    if in_ch3 or in_ch4:
        has_drawing = bool(para._element.findall('.//' + qn('wp:inline')) or para._element.findall('.//' + qn('wp:anchor')))
        marker = "[IMG]" if has_drawing else ""
        if text or has_drawing:
            output_lines.append(f"P{i} [{style_name}] {marker} {text}")

result = "\n".join(output_lines)
with open(r"F:\26毕设2\移动端短视频智能剪辑app\论文\chapters_34.txt", "w", encoding="utf-8") as f:
    f.write(result)

print(f"Done. {len(output_lines)} lines.")
