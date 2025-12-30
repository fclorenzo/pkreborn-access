import re
import sys
from pathlib import Path

def load_wordlist(file_path):
    if not Path(file_path).exists():
        return set()
    with open(file_path, 'r', encoding='utf-8') as f:
        return {line.strip().lower() for line in f if line.strip() and not line.startswith('#')}

def scan_for_badwords(content: str, badwords: set, whitelist: set):
    flagged = []
    for i, line in enumerate(content.splitlines(), start=1):
        text = line.lower()
        if any(w in text for w in whitelist):
            continue
        for bad in badwords:
            if re.search(rf'\b{re.escape(bad)}\b', text):
                preview = line.strip()
                flagged.append((i, bad, preview[:120]))
                break
    return flagged

def main():
    file_path = sys.argv[1]
    badwords_file = '.github/scripts/filters/badwords_en.txt'
    whitelist_file = '.github/scripts/filters/whitelist.txt'

    badwords = load_wordlist(badwords_file)
    whitelist = load_wordlist(whitelist_file)
    content = Path(file_path).read_text(encoding='utf-8')

    flagged = scan_for_badwords(content, badwords, whitelist)

    if flagged:
        print("FLAGGED_LINES_START")
        for i, bad, preview in flagged:
            print(f"{i}|{bad}|{preview}")
        print("FLAGGED_LINES_END")
    else:
        print("NO_FLAGS")

if __name__ == "__main__":
    main()
