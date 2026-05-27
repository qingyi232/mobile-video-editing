# -*- coding: utf-8 -*-
import docx, shutil, os

DOC = r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx'
FIG = r'F:\26毕设2\移动端短视频智能剪辑app\论文\figures'

REPLACE_MAP = {
    'rId76': os.path.join(FIG, 'fig_flow_auth.png'),
    'rId75': os.path.join(FIG, 'fig_flow_video.png'),
    'rId74': os.path.join(FIG, 'fig_flow_scene.png'),
    'rId73': os.path.join(FIG, 'fig_flow_subtitle.png'),
    'rId72': os.path.join(FIG, 'fig427_workflow.png'),
}

bak = DOC + '.bak_before_flow_replace'
shutil.copy2(DOC, bak)
print(f'Backup: {bak}')

doc = docx.Document(DOC)

replaced = 0
for rel_id, new_img_path in REPLACE_MAP.items():
    rel = doc.part.rels.get(rel_id)
    if rel is None:
        print(f'WARNING: rel {rel_id} not found, skipping')
        continue

    with open(new_img_path, 'rb') as f:
        img_data = f.read()

    image_part = rel.target_part
    image_part._blob = img_data

    replaced += 1
    print(f'Replaced {rel_id} ({rel.target_ref}) <- {os.path.basename(new_img_path)}')

doc.save(DOC)
print(f'\nDone! {replaced}/{len(REPLACE_MAP)} images replaced.')
print(f'Saved: {DOC}')
