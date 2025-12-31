import os
from datetime import datetime

def main():
    # 1. Setup Paths and Vars
    # We assume this runs from the root of the 'community-sets' branch
    table_path = "community_sets/README.md"
    
    creator = os.environ.get('CREATOR', 'Unknown')
    # Sanitize pipes in Set Name to prevent table breakage
    set_name = os.environ.get('SET_NAME', 'Unknown').replace("|", "-") 
    version = os.environ.get('FINAL_VERSION', '1')
    language = os.environ.get('LANGUAGE', 'Unknown')
    progress = os.environ.get('PROGRESS', 'Unknown')
    
    # Sanitize notes (remove newlines and pipes)
    raw_notes = os.environ.get('NOTES', '')
    notes = raw_notes.replace('\n', ' ').replace('\r', '').replace('|', '-')
    if not notes.strip():
        notes = "-"

    date = datetime.now().strftime("%Y-%m-%d")
    
    # 2. Construct the Link
    # We use the absolute GitHub blob link so it works from any branch/view
    repo = os.environ['GITHUB_REPOSITORY']
    folder = os.environ['FINAL_FOLDER'] # e.g. community_sets/user/set_v1
    link = f"https://github.com/{repo}/blob/community-sets/{folder}/pra-custom-names.txt"
    
    # 3. Define the New Row
    new_row = f"| {creator} | {set_name} | v{version} | {language} | {progress} | {notes} | {date} | [Download]({link}) |"
    
    # 4. Read Existing Table
    lines = []
    if not os.path.exists(table_path):
        print(f"Creating new table at {table_path}")
        # Create header if file is missing
        lines.append("| Creator | Set Name | Version | Language | Progress | Notes | Date | Link |\n")
        lines.append("|---|---|---|---|---|---|---|---|\n")
    else:
        with open(table_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    
    # 5. Update or Append (Upsert Logic)
    updated = False
    new_lines = []
    
    # We identify a set by "Creator + Set Name"
    search_key = f"| {creator} | {set_name} |"
    
    for line in lines:
        if line.strip().startswith(search_key):
            # Found existing entry -> Replace it with new version info
            new_lines.append(new_row + "\n")
            updated = True
            print(f"Updated entry for: {set_name} (v{version})")
        else:
            new_lines.append(line)
    
    # If not found, append to the end
    if not updated:
        new_lines.append(new_row + "\n")
        print(f"Added new entry for: {set_name}")
        
    # 6. Save
    with open(table_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    main()