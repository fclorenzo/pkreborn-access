import os
import sys
import urllib.request

def fail(msg):
    os.system(f'gh issue comment {os.environ["ISSUE_NUMBER"]} --body "{msg}"')
    os.system(f'gh issue edit {os.environ["ISSUE_NUMBER"]} --add-label "validation-failed"')
    os.system(f'gh issue edit {os.environ["ISSUE_NUMBER"]} --remove-label "automated-review"')
    sys.exit(1)

    url = os.environ.get('FILE_URL')
    if not url:
        fail('❌ **Validation Failed**\n\nNo file attachment found.')

        try:
            with urllib.request.urlopen(url) as response:
                content = response.read().decode('utf-8')
        except Exception as e:
            fail(f'❌ **Download Error**\n\n{str(e)}')

        lines = content.splitlines()
        valid_entries = 0
        errors = []

        for i, line in enumerate(lines):
            line = line.strip()
            if not line or line.startswith('#'): continue

            parts = line.split(';')
            if len(parts) < 6:
                errors.append(f'Line {i+1}: Found {len(parts)} columns (Expected 6+).')
            elif not (parts[0].isdigit() and parts[2].isdigit() and parts[3].isdigit()):
                errors.append(f'Line {i+1}: ID/X/Y are not numbers.')
            else:
                valid_entries += 1
              
            if len(errors) > 3: break

        if errors:
            fail(f'❌ **Validation Failed**\n\nErrors:\n- ' + '\n- '.join(errors))
          
        if valid_entries == 0:
            fail('❌ **Validation Failed**\n\nFile is empty or invalid.')

        # Success
        print(f"Valid entries: {valid_entries}")
        with open(os.environ['GITHUB_ENV'], 'a') as f:
            f.write(f"VALID_ENTRIES={valid_entries}\n")
