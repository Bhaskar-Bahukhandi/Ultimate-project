"""Helper script to write game files. Run with: python _rewrite_helper.py <file_key>"""
import sys, os

BASE = os.path.dirname(os.path.abspath(__file__))

def write_file(rel_path, content):
    full = os.path.join(BASE, rel_path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print(f"Written: {rel_path} ({len(content)} bytes)")

if __name__ == "__main__":
    key = sys.argv[1] if len(sys.argv) > 1 else ""
    # Read content from stdin
    content = sys.stdin.read()
    if key and content:
        write_file(key, content)
    else:
        print("Usage: echo CONTENT | python _rewrite_helper.py scripts/path.gd")
