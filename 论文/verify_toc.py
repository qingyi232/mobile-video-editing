# -*- coding: utf-8 -*-
import win32com.client
import os

doc_path = os.path.abspath(r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v4.docx')

word = win32com.client.Dispatch("Word.Application")
word.Visible = False
word.DisplayAlerts = 0

try:
    doc = word.Documents.Open(doc_path)
    
    toc_range = doc.TablesOfContents(1).Range
    toc_text = toc_range.Text
    lines = toc_text.split('\r')
    
    result = []
    result.append('=== Full Updated TOC ===\n')
    for line in lines:
        clean = line.strip()
        if clean:
            result.append(clean)
    
    with open(r'F:\26毕设2\移动端短视频智能剪辑app\论文\toc_final.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(result))
    
    print(f'Total pages: {doc.ComputeStatistics(2)}')
    doc.Close(0)

except Exception as e:
    print(f"Error: {e}")
    try:
        doc.Close(0)
    except:
        pass
finally:
    word.Quit()
    print('Done')
