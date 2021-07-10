from collections import Counter
import json
import re

import requests


def guarantee_list(s):
    if isinstance(s, list):
        return s
    if isinstance(s, str):
        return re.findall(r"[^,]+", s)

class RunesReforgedParser:
    url = 'http://ddragon.leagueoflegends.com/cdn/10.16.1/data/en_US/runesReforged.json'

    def __init__(self, filename='runesReforged.min.json'):
        self.filename = filename
        self.data = self._load()

    def _fetch(self):
        resp = requests.get(self.url)
        return resp.json()

    def _simplify(self, data):
        for runePath in data:
            for k in list(runePath.keys()):
                if k not in ['name', 'slots']:
                    del runePath[k]
            for slot in runePath.get('slots', []):
                for rune in slot.get('runes', []):
                    for k in list(rune.keys()):
                        if k not in ['name']:
                            del rune[k]
        return data

    def _dump(self, data):
        with open(self.filename, 'w') as fp:
            json.dump(data, fp, separators=(',',':'))

    def _load(self):
        try:
            with open(self.filename, 'r') as fp:
                return json.load(fp)
        except FileNotFoundError:
            # Fetch ALL the data
            runes_data = self._fetch()
            # Removes unnecessary key-value pairs
            simplified = self._simplify(runes_data)
            # Dump to file
            self._dump(simplified)
            return simplified

    def get_tree_name(self, rune_name):
        for rune_path in self.data:
            for slot in rune_path.get('slots', []):
                for rune in slot.get('runes', []):
                    if rune.get('name', '') == rune_name:
                        return rune_path.get('name', '')

    def get_primary(self, runes):
        runes = guarantee_list(runes) or []
        trees = [x for x in map(self.get_tree_name, runes) if x]
        if not trees:
            return
        tally = Counter(trees)
        primary = tally.most_common()[0][0]
        return primary


def sample():
    rune_parser = RunesReforgedParser()

    rune_names = "Grasp of the Undying,Demolish,Bone Plating,Overgrowth,Taste of Blood,Ravenous Hunter,AttackSpeed,Armor,Armor"
    primary = rune_parser.get_primary(rune_names)
    print("Runes:", guarantee_list(rune_names))
    print("Primary:", primary)

    rune_names = ""
    primary = rune_parser.get_primary(rune_names)
    print("Runes:", guarantee_list(rune_names))
    print("Primary:", primary)

if __name__ == '__main__':
    sample()
