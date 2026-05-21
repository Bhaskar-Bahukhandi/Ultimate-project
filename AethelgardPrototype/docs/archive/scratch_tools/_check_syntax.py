import re
import sys

with open('scripts/game_manager.gd', 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Total lines: {len(lines)}')

brace_stack = []
issues = []

for i, line in enumerate(lines, 1):
    stripped = line.rstrip('\n')
    leading = ''
    for ch in stripped:
        if ch in (' ', '\t'):
            leading += ch
        else:
            break
    if ' ' in leading and '\t' in leading:
        issues.append(f'Line {i}: Mixed tabs/spaces')

    # Remove comments (simple)
    code = stripped
    hash_pos = -1
    in_str = False
    str_char = ''
    for j, ch in enumerate(code):
        if in_str:
            if ch == str_char:
                in_str = False
        elif ch in ('"', "'"):
            in_str = True
            str_char = ch
        elif ch == '#':
            hash_pos = j
            break
    if hash_pos >= 0:
        code = code[:hash_pos]

    # Balance brackets
    in_str = False
    str_char = ''
    for ch in code:
        if in_str:
            if ch == str_char:
                in_str = False
            continue
        if ch in ('"', "'"):
            in_str = True
            str_char = ch
            continue
        if ch in '({[':
            brace_stack.append((ch, i))
        elif ch == ')':
            if brace_stack and brace_stack[-1][0] == '(':
                brace_stack.pop()
            else:
                issues.append('Line %d: Unmatched )' % i)
        elif ch == ']':
            if brace_stack and brace_stack[-1][0] == '[':
                brace_stack.pop()
            else:
                issues.append('Line %d: Unmatched ]' % i)
        elif ch == '}': # noqa
            if brace_stack and brace_stack[-1][0] == '{':
                brace_stack.pop()
            else:
                issues.append('Line %d: Unmatched close-brace' % i)

for ch, ln in brace_stack:
    issues.append('Line %d: Unclosed %s' % (ln, ch))

# Duplicate func check
func_names = {}
for i, line in enumerate(lines, 1):
    m = re.match(r'^func\s+(\w+)', line)
    if m:
        name = m.group(1)
        if name in func_names:
            issues.append(f'Line {i}: Duplicate func "{name}" (first at line {func_names[name]})')
        func_names[name] = i

# Check for lines ending with unfinished expressions (trailing operators)
for i, line in enumerate(lines, 1):
    stripped = line.rstrip()
    if stripped.endswith((' +', ' -', ' *', ' /', ' and', ' or', ' =')):
        # Could be multi-line but GDScript doesn't support implicit
        if not stripped.endswith('\\'):
            issues.append(f'Line {i}: Possible dangling operator: ...{stripped[-20:]}')

# Check for 'var' or 'const' inside functions at wrong indent
# Check for empty match branches
# Check for 'else' without 'if'

if issues:
    print('\nISSUES FOUND:')
    for issue in issues[:50]:
        print(f'  {issue}')
else:
    print('\nNo obvious syntax issues found')

print('\nFunction definitions:')
for i, line in enumerate(lines, 1):
    if re.match(r'^func\s+', line):
        print(f'  Line {i}: {line.rstrip()}')
