import re

with open('gen_figures.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if 'draw_box' in line or 'draw_entity' in line:
        colors = re.findall(r"'#[A-Fa-f0-9]{6}'", line)
        if len(colors) >= 2:
            line = line.replace(colors[0], "'white'")
            line = line.replace(colors[1], "'black'")
        elif len(colors) == 1:
            line = line.replace(colors[0], "'white'")
    else:
        hex_matches = list(re.finditer(r"'#[A-Fa-f0-9]{6}'", line))
        for m in reversed(hex_matches):
            start, end = m.start(), m.end()
            before = line[:start].rstrip()
            if before.endswith('edgecolor=') or before.endswith('edge_color=') or before.endswith('edge='):
                line = line[:start] + "'black'" + line[end:]
            else:
                line = line[:start] + "'white'" + line[end:]
    new_lines.append(line)

with open('gen_figures.py', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

remaining = sum(1 for l in new_lines if re.search(r"'#[A-Fa-f0-9]{6}'", l))
print(f'Remaining hex colors: {remaining}')
print('Done')
