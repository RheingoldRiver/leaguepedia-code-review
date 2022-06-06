from mwrogue.esports_client import EsportsClient
import requests
from datetime import datetime
from pytz import timezone
import math

site = EsportsClient("lol")

rpgid = input().strip()

match_data_and_timeline = site.get_data_and_timeline(rpgid)
match_data = match_data_and_timeline[0]
match_timeline = match_data_and_timeline[1]

patch = match_data["gameVersion"]
patch = ".".join(patch.split(".", 2)[:2])
ddragon_patch = patch + ".1"

runes = requests.get(
    f"https://raw.communitydragon.org/{patch}/plugins/rcp-be-lol-game-data/global/default/v1/perks.json")
runes = runes.json()
champions = requests.get(f"https://ddragon.leagueoflegends.com/cdn/{ddragon_patch}/data/en_US/champion.json")
champions = champions.json()["data"]
items = requests.get(f"https://ddragon.leagueoflegends.com/cdn/{ddragon_patch}/data/en_US/item.json")
items = items.json()["data"]
spells = requests.get(f"https://ddragon.leagueoflegends.com/cdn/{ddragon_patch}/data/en_US/summoner.json")
spells = spells.json()["data"]

champion_ids = {}
spell_ids = {}
rune_ids = {
    8000: "Precision",
    8100: "Domination",
    8200: "Sorcery",
    8300: "Inspiration",
    8400: "Resolve"
}
item_ids = {}

for key, champion in champions.items():
    champion_ids[int(champion["key"])] = champion["name"]

for key, spell in spells.items():
    spell_ids[int(spell["key"])] = spell["name"]

for rune in runes:
    rune_ids[rune["id"]] = rune["name"]

for key, item in items.items():
    item_ids[int(key)] = item["name"]

item_ids[0] = ""

game_length = int(match_data["gameDuration"])
game_length_pretty = '{}:{}'.format(str(math.floor(game_length / 60)), str(int(round(game_length % 60, 0))).zfill(2))

game_start_timestamp = int(match_data["gameCreation"] / 1000)
game_start = datetime.utcfromtimestamp(game_start_timestamp)
kst = timezone("Asia/Seoul")
kst_object = game_start.astimezone(kst)
start_date = kst_object.strftime("%Y-%m-%d")
start_time = kst_object.strftime("%H:%M")

matchschedule_info = site.cargo_client.query(
    tables="MatchScheduleGame=MSG, MatchSchedule=MS, Tournaments=T",
    fields="MSG.Blue, MSG.Red, MSG.Winner, MS.DateTime_UTC, MS.DST, MS.OverviewPage, T.StandardName",
    where=f"MSG.RiotPlatformGameId = '{rpgid.upper()}'",
    join_on="MSG.MatchId = MS.MatchId, MS.OverviewPage=T.OverviewPage"
)
if len(matchschedule_info) > 1 or not matchschedule_info:
    print("More than one game found in data!")
    exit()

matchschedule_info = matchschedule_info[0]
teams = {"team1": matchschedule_info["Blue"], "team2": matchschedule_info["Red"]}
winner_data = str(matchschedule_info["Winner"])
dst = matchschedule_info["DST"]
tournament = matchschedule_info["StandardName"]

for team in match_data["teams"]:
    if team["win"] == True or team["win"] == "Win":
        winner_team_id = int(team["teamId"])

if winner_team_id == 100:
    winner = "1"
elif winner_team_id == 200:
    winner = "2"
else:
    print("No winner team could be found!")
    exit()

if winner != winner_data:
    print("Winner team does not match!")
    exit()

# teamstats = {"team1": {}, "team2": {}}

participantstats = []
participantids_dict = {
    0: "blue1",
    1: "blue2",
    2: "blue3",
    3: "blue4",
    4: "blue5",
    5: "red1",
    6: "red2",
    7: "red3",
    8: "red4",
    9: "red5"
}

rune_keys = ["primary_1", "primary_2", "primary_3", "primary_4", "secondary_1", "secondary_2", "offense", "flex",
             "defense"]

player_templates = ["", ""]
teamgold = {"team1": 0, "team2": 0}

for i, participant in enumerate(match_data["participants"]):
    participantinfo = {
        "link": participant["summonerName"].split(" ")[1],
        "champion": champion_ids[participant["championId"]],
        "kills": str(participant["kills"]),
        "deaths": str(participant["deaths"]),
        "assists": str(participant["assists"]),
        "gold": str(int(participant["goldEarned"])),
        "cs": str(int(participant["totalMinionsKilled"]) + int(participant["neutralMinionsKilled"])),
        "visionscore": str(int(participant["visionScore"])),
        "damagetochamps": str(int(participant["totalDamageDealtToChampions"])),
        "summonerspell1": spell_ids[participant["spell1Id"]],
        "summonerspell2": spell_ids[participant["spell2Id"]],
        "trinket": item_ids[participant["item6"]],
        "pentakills": str(participant["pentaKills"]),
        "primary": rune_ids[participant["perks"]["styles"][0]["style"]],
        "secondary": rune_ids[participant["perks"]["styles"][1]["style"]],
        "keystone": rune_ids[participant["perks"]["styles"][0]["selections"][0]["perk"]],
        "primary_1": rune_ids[participant["perks"]["styles"][0]["selections"][0]["perk"]],
        "primary_2": rune_ids[participant["perks"]["styles"][0]["selections"][1]["perk"]],
        "primary_3": rune_ids[participant["perks"]["styles"][0]["selections"][2]["perk"]],
        "primary_4": rune_ids[participant["perks"]["styles"][0]["selections"][3]["perk"]],
        "secondary_1": rune_ids[participant["perks"]["styles"][1]["selections"][0]["perk"]],
        "secondary_2": rune_ids[participant["perks"]["styles"][1]["selections"][1]["perk"]],
        "offense": rune_ids[participant["perks"]["statPerks"]["offense"]],
        "flex": rune_ids[participant["perks"]["statPerks"]["flex"]],
        "defense": rune_ids[participant["perks"]["statPerks"]["defense"]]
        }
    for x in range(0, 6):
        item = item_ids.get(participant[f"item{str(x)}"])
        if item != "" and not item:
            item = participant[f"item{str(x)}"]
        participantinfo[f"item{str(x + 1)}"] = item
    ret = ''
    runes_ret = ''
    participant_key = participantids_dict[i]
    for key in participantinfo.keys():
        if key in rune_keys:
            runes_ret = runes_ret + '{},'.format(participantinfo[key])
        else:
            ret = ret + '|{}= {} '.format(key, str(participantinfo[key]))
    runes_ret = runes_ret[:-1]
    PLAYER_TEXT = '|{}={{{{Scoreboard/Player{}\n|runes={{{{Scoreboard/Player/Runes|{}}}}}}}}}\n'.format(participant_key,
                                                                                                        ret, runes_ret)
    if i < 5:
        player_templates[0] += PLAYER_TEXT
        teamgold["team1"] += int(participantinfo["gold"])
    else:
        player_templates[1] += PLAYER_TEXT
        teamgold["team2"] += int(participantinfo["gold"])

team_drakes = {}

drake_names = {
    "FIRE_DRAGON": "infernal",
    "AIR_DRAGON": "cloud",
    "EARTH_DRAGON": "mountain",
    "WATER_DRAGON": "ocean",
    "CHEMTECH_DRAGON": "chemtech",
    "HEXTECH_DRAGON": "hextech",
    "ELDER_DRAGON": "elder"
}

teamstats = []

for team in match_data["teams"]:
    if team["teamId"] == 100:
        team_key = "team1"
    elif team["teamId"] == 200:
        team_key = "team2"
    teaminfo = {
        team_key: str(teams[team_key]),
        team_key + "b": str(team["objectives"]["baron"]["kills"]),
        team_key + "k": str(team["objectives"]["champion"]["kills"]),
        team_key + "rh": str(team["objectives"]["riftHerald"]["kills"]),
        team_key + "t": str(team["objectives"]["tower"]["kills"]),
        team_key + "i": str(team["objectives"]["inhibitor"]["kills"]),
        team_key + "g": str(teamgold[team_key]),
        team_key + "infernal": 0,
        team_key + "cloud": 0,
        team_key + "mountain": 0,
        team_key + "ocean": 0,
        team_key + "chemtech": 0,
        team_key + "hextech": 0,
        team_key + "elder": 0,
        team_key + "d": 0
    }
    for i, ban in enumerate(team["bans"]):
        i += 1
        teaminfo[team_key + "ban" + str(i)] = champion_ids[ban["championId"]] or "None"
    teamstats.append(teaminfo)

for frame in match_timeline["frames"]:
    for event in frame["events"]:
        if event["type"] == "ELITE_MONSTER_KILL":
            if event["monsterType"] == "DRAGON":
                drake = drake_names[event["monsterSubType"]]
                killer_team = event["killerTeamId"]
                if killer_team == 100:
                    team_key = "team1"
                    drake_type_kills = teamstats[0].get(team_key + drake) or 0
                    teamstats[0][team_key + drake] = drake_type_kills + 1
                    drake_kills = teamstats[0].get(team_key + "d") or 0
                    teamstats[0][team_key + "d"] = drake_kills + 1
                elif killer_team == 200:
                    team_key = "team2"
                    drake_type_kills = teamstats[1].get(team_key + drake) or 0
                    teamstats[1][team_key + drake] = drake_type_kills + 1
                    drake_kills = teamstats[1].get(team_key + "d") or 0
                    teamstats[1][team_key + "d"] = drake_kills + 1

team_templates = []

for i, team in enumerate(teamstats):
    ret = ''
    for key in team.keys():
        ret = ret + '|{}= {} '.format(key, str(team[key]))
    TEAM_TEXT = '{}\n{}'.format(ret, player_templates[i])
    team_templates.append(TEAM_TEXT)

HEADER_TEXT = "{{{{Scoreboard/Header|{}|{}}}}}\n".format(teams["team1"], teams["team2"])

GAME_TEXT = f"""{{{{Scoreboard/Season 8|tournament={tournament} |patch={str(patch)} |winner={winner} \
|gamelength={game_length_pretty} |timezone=KST |date={start_date} |dst={dst} |time={start_time} |rpgid={rpgid.upper()} \
|vodlink= \n{team_templates[0]}{team_templates[1]}}}}}"""

print(HEADER_TEXT + GAME_TEXT)
