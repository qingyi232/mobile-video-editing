import re

with open('gen_figures.py', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(r"arrowprops=dict\(arrowstyle='[^']+', color='white'", 
                 lambda m: m.group(0).replace("color='white'", "color='black'"), content)

content = content.replace("color='white', lw=", "color='black', lw=")

with open('gen_figures.py', 'w', encoding='utf-8') as f:
    f.write(content)

remaining = content.count("color='white'")
print(f'Remaining color=white: {remaining}')
print('Done')
