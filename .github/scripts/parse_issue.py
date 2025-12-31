import os
import re
import sys

def main():
    # Read the issue body from the environment variable
    body = os.environ.get('ISSUE_BODY', '')
    payload = {}

    # 1. Parse the Body by "### Header"
    # This regex splits the markdown into sections based on level 3 headers
    sections = re.split(r'^###\s+', body, flags=re.MULTILINE)
    
    for section in sections:
        if not section.strip(): continue
        # Split into Key (first line) and Value (rest)
        parts = section.strip().split('\n', 1)
        key = parts[0].strip()
        val = parts[1].strip() if len(parts) > 1 else ''
        payload[key] = val

    # 2. Extract Standard Fields
    # We Map the "Form Label" to a "Variable Name"
    set_name = payload.get('Label Set Name') or payload.get('Theme Name', 'Unknown')
    language = payload.get('Language', 'Unknown')
    progress = payload.get('Game Progress', 'Unknown')
    notes = payload.get('Creator\'s Notes', 'None')
    file_field = payload.get('Upload File') or payload.get('File Upload', '')

    # 3. Extract File URL
    # Looks for markdown link: [filename](url)
    match = re.search(r'\[(.*?)\]\((.*?)\)', file_field)
    
    filename = match.group(1) if match else ""
    file_url = match.group(2) if match else ""

    # 4. Output to GitHub Actions Environment
    # This makes these variables available to next steps as ${{ env.VAR_NAME }}
    env_file = os.environ.get('GITHUB_ENV')
    if env_file:
        with open(env_file, 'a') as f:
            f.write(f"SET_NAME={set_name}\n")
            f.write(f"LANGUAGE={language}\n")
            f.write(f"PROGRESS={progress}\n")
            # Sanitize notes to be one line for safety
            clean_notes = notes.replace('\n', ' ').replace('\r', '')
            f.write(f"NOTES={clean_notes}\n")
            f.write(f"ORIGINAL_FILENAME={filename}\n")
            f.write(f"FILE_URL={file_url}\n")
            
    # Print for debugging logs
    print(f"Parsed: {set_name} ({language}) - File: {filename}")

if __name__ == "__main__":
    main()