# .github/scripts/scraper.py
import requests
from bs4 import BeautifulSoup
import json
import time
import re

# 1. Get the list of Pokémon with IDs from PokeAPI
def get_pokemon_list():
    print("Fetching Pokemon list from PokeAPI...")
    url = "https://pokeapi.co/api/v2/pokemon-species?limit=10000"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        results = []
        for entry in data['results']:
            # Extract ID from URL (e.g., https://pokeapi.co/api/v2/pokemon-species/1/)
            p_id = int(entry['url'].split('/')[-2])
            results.append((p_id, entry['name']))
        return results
    except Exception as e:
        print(f"Failed to fetch from PokeAPI: {e}")
        return []

# 2. Format Slug (Same as before)
def format_for_bulbapedia(slug):
    special_cases = {
        "nidoran-f": "Nidoran♀",
        "nidoran-m": "Nidoran♂",
        "mr-mime": "Mr._Mime",
        "mime-jr": "Mime_Jr.",
        "type-null": "Type:_Null",
        "ho-oh": "Ho-Oh",
        "porygon-z": "Porygon-Z",
        "jangmo-o": "Jangmo-o",
        "hakamo-o": "Hakamo-o",
        "kommo-o": "Kommo-o",
        "tapu-koko": "Tapu_Koko",
        "tapu-lele": "Tapu_Lele",
        "tapu-bulu": "Tapu_Bulu",
        "tapu-fini": "Tapu_Fini",
        "sirfetchd": "Sirfetch'd",
        "mr-rime": "Mr._Rime",
        "flabebe": "Flabébé",
        "great-tusk": "Great_Tusk",
        "scream-tail": "Scream_Tail",
        # Add other paradox/new mons as needed
    }
    if slug in special_cases: return special_cases[slug]
    return slug.replace("-", " ").title().replace(" ", "_")

# 3. Text Sanitization (Same as before)
def clean_text(text):
    text = re.sub(r'\[.*?\]', '', text) # Remove citations
    text = text.replace(u'\xa0', u' ')
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

# 4. Main Scrape Logic
def scrape_biology():
    pokemon_list = get_pokemon_list()
    final_data = {}
    
    print(f"Found {len(pokemon_list)} species. Starting scrape...")

    with requests.Session() as session:
        for index, (p_id, slug) in enumerate(pokemon_list):
            wiki_name = format_for_bulbapedia(slug)
            clean_name = wiki_name.replace("_", " ").upper()
            
            url = f"https://bulbapedia.bulbagarden.net/wiki/{wiki_name}_(Pok%C3%A9mon)"
            
            try:
                response = session.get(url, headers={'User-Agent': 'PokemonRebornAccessMod/1.0'})
                if response.status_code == 404:
                    url = f"https://bulbapedia.bulbagarden.net/wiki/{wiki_name}"
                    response = session.get(url)

                if response.status_code == 200:
                    soup = BeautifulSoup(response.content, 'html.parser')
                    
                    # --- Parsing Logic ---
                    bio_span = soup.find('span', {'id': 'Biology'})
                    
                    if bio_span:
                        forms_data = {}
                        current_form = "default"
                        forms_data[current_form] = []
                        
                        # Start iterating from the parent H2's next sibling
                        header_node = bio_span.parent 
                        curr = header_node.next_sibling
                        
                        while curr:
                            # Stop at next main section (H2)
                            if curr.name == 'h2': 
                                break
                            
                            # Handle Subheaders (H3 or H4 for forms)
                            if curr.name in ['h3', 'h4']:
                                header_text = curr.get_text().strip()
                                # Stop if we hit an Evolution section inside Biology (rare but possible)
                                if "Evolution" in header_text:
                                    break
                                
                                # This is likely a form header (e.g., "Alolan Vulpix")
                                # Switch the current key to this new form
                                current_form = clean_text(header_text)
                                if current_form not in forms_data:
                                    forms_data[current_form] = []
                            
                            # Handle Paragraphs
                            if curr.name == 'p':
                                raw_text = curr.get_text()
                                cleaned = clean_text(raw_text)
                                if cleaned:
                                    forms_data[current_form].append(cleaned)
                                    
                            curr = curr.next_sibling
                        
                        # Clean up: Join lists into strings and remove empty forms
                        clean_forms = {}
                        for form_name, paras in forms_data.items():
                            if paras:
                                clean_forms[form_name] = "\n\n".join(paras)
                        
                        if clean_forms:
                            final_data[clean_name] = {
                                "id": p_id,
                                "forms": clean_forms
                            }
                            print(f"[{index+1}/{len(pokemon_list)}] Scraped: {clean_name} (Forms: {list(clean_forms.keys())})")
                        else:
                            print(f"[{index+1}/{len(pokemon_list)}] Empty Biology: {clean_name}")
                            
                    else:
                        print(f"[{index+1}/{len(pokemon_list)}] No Biology section: {wiki_name}")
                else:
                    print(f"[{index+1}/{len(pokemon_list)}] HTTP {response.status_code}: {url}")
            
            except Exception as e:
                print(f"Error processing {slug}: {e}")
            
            time.sleep(0.5)

    return final_data

if __name__ == "__main__":
    data = scrape_biology()
    with open('pokemon_biology.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("Scrape complete. Saved to pokemon_biology.json")