import os
import re
from datetime import datetime

def sanitize_filename(name):
    """
    Converts 'Chinese (Simplified)' -> 'Chinese_Simplified'
    Converts 'English' -> 'English'
    """
    # Replace spaces with underscores
    name = name.replace(" ", "_")
    # Remove parentheses
    name = name.replace("(", "").replace(")", "")
    # Remove any other strange characters just in case, keeping alphanumeric, - and _
    return re.sub(r'[^a-zA-Z0-9_-]', '', name)

def main():
    # 1. Setup Paths and Vars
    creator = os.environ.get('CREATOR', 'Unknown')
    set_name = os.environ.get('SET_NAME', 'Unknown').replace("|", "-") 
    version = os.environ.get('FINAL_VERSION', '1')
    language = os.environ.get('LANGUAGE', 'Other')
    progress = os.environ.get('PROGRESS', 'Unknown')
    
    # Sanitize notes
    raw_notes = os.environ.get('NOTES', '')
    notes = raw_notes.replace('\n', ' ').replace('\r', '').replace('|', '-')
    if not notes.strip():
        notes = "-"

    date = datetime.now().strftime("%Y-%m-%d")
    
    # 2. Determine the Target File based on Language
    # Ensure 'lists' directory exists
    list_dir = "community_sets/lists"
    if not os.path.exists(list_dir):
        os.makedirs(list_dir)

    safe_lang_name = sanitize_filename(language)
    table_path = f"{list_dir}/{safe_lang_name}.md"

    # 3. Construct the Link
    repo = os.environ['GITHUB_REPOSITORY']
    folder = os.environ['FINAL_FOLDER'] 
    link = f"https://github.com/{repo}/blob/community-sets/{folder}/pra-custom-names.txt"
    
    # 4. Define the New Row
    new_row = f"| {creator} | {set_name} | v{version} | {progress} | {notes} | {date} | [Download]({link}) |"
    
    # 5. Read Existing Table (or create new)
    lines = []
    if not os.path.exists(table_path):
        print(f"Creating new language list: {table_path}")
        # Header for the language specific file
        # Note: We removed the 'Language' column since the file itself is the language category
        lines.append(f"# {language} Label Sets\n\n")
        lines.append("| Creator | Set Name | Version | Progress | Notes | Date | Link |\n")
        lines.append("|---|---|---|---|---|---|---|\n")
    else:
        with open(table_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    
    # 6. Upsert Logic
    updated = False
    new_lines = []
    
    # Search key: "| Creator | Set Name |"
    search_key = f"| {creator} | {set_name} |"
    
    for line in lines:
        if line.strip().startswith(search_key):
            new_lines.append(new_row + "\n")
            updated = True
            print(f"Updated entry in {safe_lang_name}.md")
        else:
            new_lines.append(line)
    
    if not updated:
        new_lines.append(new_row + "\n")
        print(f"Added new entry to {safe_lang_name}.md")
        
    # 7. Save
    with open(table_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    main()