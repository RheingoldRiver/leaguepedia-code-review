from mwrogue.esports_client import EsportsClient
from mwrogue.auth_credentials import AuthCredentials
from mwcleric.errors import RetriedLoginAndStillFailed
from mwclient.errors import MaximumRetriesExceeded
import mwparserfromhell

credentials = AuthCredentials(user_file="bot")
site = EsportsClient("lol", credentials=credentials, max_retries_mwc=2, max_retries=2, retry_interval=10)

response = site.cargo_client.query(
    tables="Teamnames=T, Teamnames__Inputs=I, Teamnames__Inputs=I2",
    where="I._value LIKE '%,%' AND I2._value NOT LIKE '%,%'",
    join_on="T._ID=I._rowID, I._rowID=I2._rowID",
    fields="I._value=BadInput, I2._value=GoodInput, T.Link",
    group_by="T._ID"
)

failed_pages = []

for item in response:
    for page in site.client.pages[item["Link"]].backlinks():
        original_text = page.text()
        page_wikitext = mwparserfromhell.parse(original_text)
        for template in page_wikitext.filter_templates():
            for param in template.params:
                if param.value.lower() == item["BadInput"]:
                    template.add(param.name, item["GoodInput"])
        if original_text != str(page_wikitext):
            print(page.name)
            try:
                site.save_title(title=page.name, text=str(page_wikitext), summary="Changing team inputs with comma")
            except RetriedLoginAndStillFailed:
                failed_pages.append(page.name)
                pass
            except MaximumRetriesExceeded:
                failed_pages.append(page.name)
                pass
            print(f"Saved {page.name}")

print("Failures:")
print('\n'.join(failed_pages))
