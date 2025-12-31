import os
import re
import sys

def main():
    body = os.environ.get('ISSUE_BODY', '')
    payload = {}

    # 1. Parse the Body by "### Header"
    sections = re.split(r'^###\s+', body, flags=re.MULTILINE)
    
    for section in sections:
        if not section.strip(): continue
        parts = section.strip().split('\n', 1)
        key = parts[0].strip()
        val = parts[1].strip() if len(parts) > 1 else ''
        payload[key] = val

    # 2. Extract Fields
    set_name = payload.get('Label Set Name') or payload.get('Theme Name', 'Unknown')
    # Sanitize version: remove anything that isn't a digit, default to 1
    # --- SMART VERSION PARSING ---
    raw_version = payload.get('Version', '1')
    # Find the FIRST sequence of digits. 
    # Input "1.0" -> finds "1". Input "v2.5" -> finds "2".
    match = re.search(r'\d+', raw_version)
    if match:
        version = match.group(0)
    else:
        version = "1"
    language = payload.get('Language', 'Unknown')
    progress = payload.get('Game Progress', 'Unknown')
    notes = payload.get('Creator\'s Notes', 'None')
    file_field = payload.get('Upload File') or payload.get('File Upload', '')

    # 3. Extract File URL
    match = re.search(r'\[(.*?)\]\((.*?)\)', file_field)
    filename = match.group(1) if match else ""
    file_url = match.group(2) if match else ""

    # 4. Output
    env_file = os.environ.get('GITHUB_ENV')
    if env_file:
        with open(env_file, 'a') as f:
            f.write(f"SET_NAME={set_name}\n")
            f.write(f"VERSION={version}\n")
            f.write(f"LANGUAGE={language}\n")
            f.write(f"PROGRESS={progress}\n")
            clean_notes = notes.replace('\n', ' ').replace('\r', '')
            f.write(f"NOTES={clean_notes}\n")
            f.write(f"ORIGINAL_FILENAME={filename}\n")
            f.write(f"FILE_URL={file_url}\n")
            
    print(f"Parsed: {set_name} v{version} ({language})")

if __name__ == "__main__":
    main()