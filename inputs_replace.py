from mwrogue.esports_client import EsportsClient
from mwrogue.auth_credentials import AuthCredentials
from mwcleric.errors import RetriedLoginAndStillFailed
import mwparserfromhell

credentials = AuthCredentials(user_file="bot")
site = EsportsClient("lol", credentials=credentials, max_retries=0)

response = site.cargo_client.query(
    tables="Teamnames=T, Teamnames__Inputs=I, Teamnames__Inputs=I2",
    where="I._value LIKE '%,%' AND I2._value NOT LIKE '%,%'",
    join_on="T._ID=I._rowID, I._rowID=I2._rowID",
    fields="I._value=BadInput, I2._value=GoodInput, T.Link",
    group_by="T._ID"
)

for item in response:
    for page in site.client.pages[item["Link"]].backlinks():
        page_text = page.text()
        page_wikitext = mwparserfromhell.parse(page_text)
        for template in page_wikitext.filter_templates():
            for param in template.params:
                if param.value.lower() == item["BadInput"]:
                    template.add(param.name, item["GoodInput"])
        if str(page_text) != str(page_wikitext):
            try:
                site.save(page=page, text=str(page_wikitext), summary="Changing team inputs with comma")
            except RetriedLoginAndStillFailed:
                pass
            print(f"Saved {page.name}")
