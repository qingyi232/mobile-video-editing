with open('gen_figures.py', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace("color='white')", "color='black')")
c = c.replace("linestyle='white'", "linestyle='--'")

with open('gen_figures.py', 'w', encoding='utf-8') as f:
    f.write(c)

count = c.count("color='white'")
print(f'Remaining color=white: {count}')
print('Done')
