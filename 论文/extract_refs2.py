import docx
doc = docx.Document(r"F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx")

in_refs = False
refs = []
for i, p in enumerate(doc.paragraphs):
    text = p.text.strip()
    if '参考文献' in text and len(text) < 20:
        in_refs = True
        continue
    if in_refs and text.startswith('[') and ']' in text[:6]:
        num = text.split(']')[0].replace('[','')
        refs.append((num, text))
    elif in_refs and ('致谢' in text or '附录' in text):
        break

with open(r"F:\26毕设2\移动端短视频智能剪辑app\论文\refs_list.txt", "w", encoding="utf-8") as f:
    for num, text in refs:
        f.write(f"[{num}] {text}\n\n")

print(f"Total refs: {len(refs)}")
for num, text in refs:
    print(f"  [{num}]")
