# -*- coding: utf-8 -*-
import win32com.client
import os
import time

doc_path = os.path.abspath(r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书修改_v4.docx')
print(f"Opening: {doc_path}")
print(f"File exists: {os.path.exists(doc_path)}")

word = win32com.client.Dispatch("Word.Application")
word.Visible = False
word.DisplayAlerts = 0  # wdAlertsNone

try:
    doc = word.Documents.Open(doc_path)
    print(f"Document opened, pages: {doc.ComputeStatistics(2)}")  # wdStatisticPages

    # Update all TOC fields
    toc_count = doc.TablesOfContents.Count
    print(f"TOC count: {toc_count}")
    
    for i in range(1, toc_count + 1):
        toc = doc.TablesOfContents(i)
        print(f"  TOC {i}: updating...")
        toc.Update()
        print(f"  TOC {i}: updated successfully")

    # Also update all fields in the document
    for section in doc.Sections:
        for header in section.Headers:
            header.Range.Fields.Update()
        for footer in section.Footers:
            footer.Range.Fields.Update()

    doc.Save()
    print("Document saved")

    # Verify by reading TOC text
    if toc_count > 0:
        toc_range = doc.TablesOfContents(1).Range
        toc_text = toc_range.Text[:500]
        lines = toc_text.split('\r')
        print("\n=== Updated TOC (first 15 entries) ===")
        for line in lines[:15]:
            clean = line.strip()
            if clean:
                print(f"  {clean}")

    doc.Close()
    print("\nDocument closed")

except Exception as e:
    print(f"Error: {e}")
    try:
        doc.Close(0)  # wdDoNotSaveChanges
    except:
        pass

finally:
    word.Quit()
    print("Word quit")
