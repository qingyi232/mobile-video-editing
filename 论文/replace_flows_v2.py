# -*- coding: utf-8 -*-
import docx, shutil, os, sys
sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf-8', buffering=1)
from docx.oxml.ns import qn

DOC = r'F:\26毕设2\移动端短视频智能剪辑app\论文\22103423郭湘_移动端短视频智能剪辑APP的设计与实现_毕业设计说明书5.20_修改版.docx'
FIG = r'F:\26毕设2\移动端短视频智能剪辑app\论文\figures'

FLOW_FILES = {
    'fig_flow_auth.png': '用户认证模块流程图',
    'fig_flow_video.png': '视频处理模块流程图',
    'fig_flow_scene.png': '场景识别模块流程图',
    'fig_flow_subtitle.png': '字幕生成模块流程图',
    'fig427_workflow.png': '视频编辑操作流程图',
}

bak = DOC + '.bak_v2'
shutil.copy2(DOC, bak)
print(f'Backup saved')

doc = docx.Document(DOC)

body = doc.element.body
elements = list(body)

flow_images = {}
for i, child in enumerate(elements):
    tag = child.tag.split('}')[-1] if '}' in child.tag else child.tag
    if tag != 'p':
        continue
    drawings = child.findall('.//' + qn('wp:inline')) + child.findall('.//' + qn('wp:anchor'))
    for d in drawings:
        blip = d.find('.//' + qn('a:blip'))
        if blip is None:
            continue
        embed = blip.get(qn('r:embed'))
        rel = doc.part.rels.get(embed)
        if not rel or 'image' not in rel.reltype:
            continue

        nearby_text = ''
        for offset in range(-3, 4):
            ci = i + offset
            if 0 <= ci < len(elements):
                el = elements[ci]
                t = el.tag.split('}')[-1] if '}' in el.tag else el.tag
                if t == 'p':
                    text = ''.join(tx.text or '' for tx in el.findall('.//' + qn('w:t')))
                    nearby_text += text

        for fig_name, fig_desc in FLOW_FILES.items():
            if fig_desc in nearby_text or ('流程图' in nearby_text and fig_desc[:4] in nearby_text):
                flow_images[fig_name] = {'rel_id': embed, 'target': rel.target_ref, 'elem': i}

print(f'Found {len(flow_images)} matching flow images:')
for k, v in flow_images.items():
    print(f'  {k} -> {v["rel_id"]} ({v["target"]})')

replaced = 0
for fig_name, info in flow_images.items():
    new_img = os.path.join(FIG, fig_name)
    if not os.path.exists(new_img):
        print(f'WARNING: {new_img} not found')
        continue

    rel = doc.part.rels.get(info['rel_id'])
    if rel is None:
        print(f'WARNING: rel {info["rel_id"]} not found')
        continue

    with open(new_img, 'rb') as f:
        rel.target_part._blob = f.read()

    replaced += 1
    print(f'Replaced {info["rel_id"]} <- {fig_name}')

if replaced < len(FLOW_FILES):
    print(f'\nWARNING: Only {replaced}/{len(FLOW_FILES)} replaced. Trying fallback...')
    all_img_rels = {}
    for rel_id, rel in doc.part.rels.items():
        if 'image' in rel.reltype:
            all_img_rels[rel_id] = rel.target_ref
    
    replaced_names = set(flow_images.keys())
    missing = set(FLOW_FILES.keys()) - replaced_names
    
    target_map = {
        'fig_flow_auth.png': 'image44',
        'fig_flow_video.png': 'image43',
        'fig_flow_scene.png': 'image42',
        'fig_flow_subtitle.png': 'image41',
        'fig427_workflow.png': 'image40',
    }
    
    for fig_name in missing:
        target_key = target_map.get(fig_name)
        if not target_key:
            continue
        for rel_id, target in all_img_rels.items():
            if target_key in target:
                new_img = os.path.join(FIG, fig_name)
                rel = doc.part.rels.get(rel_id)
                if rel:
                    with open(new_img, 'rb') as f:
                        rel.target_part._blob = f.read()
                    replaced += 1
                    print(f'Fallback replaced {rel_id} ({target}) <- {fig_name}')
                break

doc.save(DOC)
print(f'\nDone! {replaced} images replaced. Saved.')
