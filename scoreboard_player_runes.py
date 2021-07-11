import re
import json

from mwcleric.fandom_client import FandomClient
from mwcleric.auth_credentials import AuthCredentials
from mwcleric.template_modifier import TemplateModifierBase
from mwparserfromhell.nodes import Template
from mwparserfromhell.nodes.extras.parameter import Parameter

from runes_reforged_parser import RunesReforgedParser

rune_parser = RunesReforgedParser()

class TemplateModifier(TemplateModifierBase):
    def update_template(self, template: Template):
        if template.has('primary'):
            return
        if not template.has('runes'):
            return
        param = template.get('runes')
        param: Parameter
        w = param.value
        for tl in w.filter_templates():
            tl: Template
            rune_names = tl.get('1').value.strip()
            primary = rune_parser.get_primary(rune_names)
            if primary is not None:
                template.add('primary', primary,
                             before='secondary')
        return

def add_primary_rune_tree():
    credentials = AuthCredentials(user_file='bot')
    site = FandomClient(wiki='lol', credentials=credentials)

    summary = "add primary rune tree"

    TemplateModifier(site, 'Scoreboard/Player',
                     page_list=site.pages_using('Scoreboard/Player/Runes'),
                     summary=summary).run()


if __name__ == '__main__':
    add_primary_rune_tree()
