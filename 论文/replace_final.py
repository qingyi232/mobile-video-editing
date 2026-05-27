# -*- coding: utf-8 -*-
import docx, shutil, os

DOC = r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx'
FIG = r'F:\26毕设2\移动端短视频智能剪辑app\论文\figures'

TARGET_MAP = {
    'image44': os.path.join(FIG, 'fig_flow_auth.png'),
    'image43': os.path.join(FIG, 'fig_flow_video.png'),
    'image42': os.path.join(FIG, 'fig_flow_scene.png'),
    'image41': os.path.join(FIG, 'fig_flow_subtitle.png'),
    'image40': os.path.join(FIG, 'fig427_workflow.png'),
}

bak = DOC + '.bak_final_replace'
shutil.copy2(DOC, bak)

doc = docx.Document(DOC)

replaced = 0
for rel_id, rel in doc.part.rels.items():
    if 'image' not in rel.reltype:
        continue
    target = rel.target_ref
    for key, new_img in TARGET_MAP.items():
        if key + '.' in target:
            with open(new_img, 'rb') as f:
                rel.target_part._blob = f.read()
            replaced += 1
            print(f'OK: {rel_id} ({target}) <- {os.path.basename(new_img)}')
            break

doc.save(DOC)
print(f'\nDone! {replaced}/5 images replaced.')
