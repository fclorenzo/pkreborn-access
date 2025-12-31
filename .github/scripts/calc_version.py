import os
import glob
import re

user = os.environ['USER']
set_name = os.environ['SET_NAME']
# Clean set name for folder safety
safe_set_name = re.sub(r'[^a-zA-Z0-9_-]', '', set_name)

req_ver = int(os.environ['REQ_VERSION'])
base_dir = f"community_sets/{user}"

# Check existing versions
existing_vers = []
if os.path.exists(base_dir):
    # Look for folders like "SafeSetName_v1", "SafeSetName_v2"
    for path in glob.glob(f"{base_dir}/{safe_set_name}_v*"):
        try:
            v_str = path.split('_v')[-1]
            existing_vers.append(int(v_str))
        except:
            pass

max_ver = max(existing_vers) if existing_vers else 0

# Smart Logic:
# If existing max is 2, and user asks for 1 -> Force 3
# If existing max is 2, and user asks for 3 -> Allow 3
final_ver = req_ver
if req_ver <= max_ver:
    final_ver = max_ver + 1
    print(f"Auto-bumping version from {req_ver} to {final_ver}")

final_folder = f"{base_dir}/{safe_set_name}_v{final_ver}"

with open(os.environ['GITHUB_ENV'], 'a') as f:
    f.write(f"FINAL_VERSION={final_ver}\n")
    f.write(f"FINAL_FOLDER={final_folder}\n")
    f.write(f"SAFE_SET_NAME={safe_set_name}\n")