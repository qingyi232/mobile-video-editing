import re

with open('gen_figures.py', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
fixed = 0
for line in lines:
    if 'ax.text' in line and "color='white'" in line:
        line = line.replace("color='white'", "color='black'")
        fixed += 1
    if "text_color='white'" in line:
        line = line.replace("text_color='white'", "text_color='black'")
        fixed += 1
    new_lines.append(line)

with open('gen_figures.py', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print(f'Fixed {fixed} text color issues')
