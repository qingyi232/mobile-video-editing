import docx

doc_path = r"F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx"
doc = docx.Document(doc_path)

in_refs = False
refs = []
for i, p in enumerate(doc.paragraphs):
    text = p.text.strip()
    style = p.style.name if p.style else ""
    if '参考文献' in text and len(text) < 20:
        in_refs = True
        print(f"P{i} === 参考文献开始 ===")
        continue
    if in_refs:
        if text.startswith('[') and ']' in text[:6]:
            refs.append((i, text))
            print(f"P{i} {text[:120].encode('gbk', errors='replace').decode('gbk')}")
        elif text and not text.startswith('['):
            if '致谢' in text or '附录' in text:
                in_refs = False
                print(f"P{i} === 参考文献结束 ===")
            else:
                print(f"P{i} (xu) {text[:120].encode('gbk', errors='replace').decode('gbk')}")

print(f"\n总共 {len(refs)} 条参考文献")
