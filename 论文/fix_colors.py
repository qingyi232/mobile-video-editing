import re

with open('gen_figures.py', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r"facecolor='#[A-Fa-f0-9]+'", "facecolor='white'", content)
content = re.sub(r"edgecolor='#[A-Fa-f0-9]+'", "edgecolor='black'", content)
content = re.sub(r"""color='#[A-Fa-f0-9]+'""", "color='white'", content)
content = content.replace("edge_color='white'", "edge_color='black'")
content = content.replace("text_color='white'", "text_color='black'")

with open('gen_figures.py', 'w', encoding='utf-8') as f:
    f.write(content)

count_facecolor = len(re.findall(r"facecolor='white'", content))
count_edgecolor = len(re.findall(r"edgecolor='black'", content))
print(f'facecolor=white: {count_facecolor}, edgecolor=black: {count_edgecolor}')
print('All colors replaced')
