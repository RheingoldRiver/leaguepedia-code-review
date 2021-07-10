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
        for param in template.params:
            param: Parameter
            if param.name.matches('runes'):
                w = param.value
                for tl in w.filter_templates():
                    tl: Template
                    runes = tl.params[0]
                    primary = rune_parser.get_primary(runes)
                    if primary:
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
