"""Rebuild wiki search after editing a guide: python tools/build-guide-search.py."""
import json
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAMES = {
    "megabonk": "Megabonk",
    "tf2": "TF2 & TF2 Classified",
    "half-life-1": "Half-Life 1",
    "source-games": "Source Games",
    "l4d": "Left 4 Dead 1 & 2",
    "last-of-us": "The Last of Us Part I",
    "gta5": "GTA 5",
    "fivem": "FiveM",
    "redm": "RedM",
    "rdr2": "Red Dead Redemption 2",
    "cs2": "Counter-Strike 2",
    "sbox": "S&box (Sandbox)",
    "gmod": "Garry's Mod (GMOD)",
    "general": "General help",
}


SEARCH_ALIASES = {
    "megabonk": ["Mega Bonk", "Megabonk", "Lua", "spawner", "unlocks", "languages", "hotkeys"],
    "tf2": ["Team Fortress 2", "TF2", "TF2 Classified", "Classified", "retail", "tf2c", "Lua", "TF2 cheat"],
    "half-life-1": [
        "HL1",
        "Half Life",
        "Half-Life",
        "GoldSrc",
        "Source Games",
        "Opposing Force",
        "Blue Shift",
        "Half-Life cheat",
        "HL1 cheat"
    ],
    "l4d": [
        "L4D",
        "L4D1",
        "L4D2",
        "Left 4 Dead",
        "Left 4 Dead 2",
        "infected",
        "Lua",
        "L4D cheat",
        "L4D1 cheat",
        "L4D2 cheat",
        "Left 4 Dead cheat",
        "Left 4 Dead 2 cheat"
    ],
    "sbox": [
        "S&box",
        "Sbox",
        "Sandbox",
        "S&box cheat",
        "Sbox cheat",
        "Sandbox cheat"
    ],
    "last-of-us": [
        "The Last of Us",
        "TLOU",
        "TLOU1",
        "Part I",
        "Part 1",
        "The Last of Us cheat",
        "TLOU cheat"
    ],
    "gmod": [
        "GMOD",
        "Garry's Mod",
        "Garrys Mod",
        "GMOD cheat",
        "Garry's Mod cheat"
    ],
    "cs2": [
        "CS2",
        "Counter-Strike 2",
        "CS2 cheat",
        "Counter-Strike 2 cheat"
    ],
    "fivem": [
        "FiveM cheat"
    ],
    "redm": [
        "RedM cheat"
    ],
    "gta5": [
        "GTA5",
        "GTA V",
        "GTA 5 mod menu",
        "GTA 5 cheat",
        "GTA5 cheat",
        "GTA V cheats",
        "GTA Online cheats"
    ],
    "rdr2": [
        "RDR2",
        "Red Dead Redemption 2",
        "RDR2 mod menu",
        "RDR2 cheat",
        "Red Dead Redemption 2 cheats",
        "Red Dead Online cheats"
    ]
}


PAGE_SEARCH_ALIASES = {
    "gta5/dlcs": ["Addons", "add-on", "addon vehicles", "addon peds", "DLCs", "DLC models", "GTA5-Mods", "Legacy Enhanced", "asset conversion", "CodeWalker", "Sollumz"],
    "gta5/vehicles": ["Vehicles", "modded vehicles", "saved vehicles", "Nenyoo", "download vehicles", "Menyoo", "JSON", "XML", "INI", "import", "Legacy Enhanced"],
    "gta5/outfits": ["Outfits", "saved outfits", "Nenyoo", "download outfits", "clothing presets", "character model", "JSON", "XML", "Legacy Enhanced"],
    "gta5/lua-scripts": ["Lua scripts", "Lua Editor", "Scripts", "Open Lua Folder", "Refresh Scripts", "Run Reload", "dependencies"],
    "gta5/themes": ["themes", "Appearance", "Open Themes Folder", "theme bundle", "ClickUI", "ListUI", "Save Load Scope", "background image"],
    "general/free-key": ["free key", "freekey", "ScoobyKEY", "BSTLAR", "24 hours", "24h", "24-hour reset", "daily key", "renew key", "all free versions", "copy key", "Free login"],
    "general/connection": ["website not opening", "site not found", "connection not found", "server not found", "site cannot be reached", "loader cannot connect", "loader connection issues", "timeout", "backend outage", "server hosting", "hosting provider", "server down", "DNS", "ISP blocking", "country block", "country restrictions", "network filtering", "VPN", "proxy", "Cloudflare", "1.1.1.1", "WARP", "Proton VPN"],
    "general/faq": ["antivirus", "AV", "Defender", "Windows Security", "exclusion", "exception", "quarantine", "blocked download", "Norton", "AVG", "Avast", "McAfee", "Bitdefender", "ESET", "Malwarebytes", "uninstall antivirus"],
    "general/crashing": ["crash", "settings backup", "rename folder", "VC runtime", "Visual C++", "graphics driver"],
    "general/universal": ["login failed", "authentication", "expired key", "invalid key", "game not detected", "loading failed", "injection failed"],
    "general/hwid": ["hardware ID", "HWID mismatch", "reset HWID", "7 days", "7-day cooldown", "portal dashboard"],
    "general/linux-mac": ["Linux", "Mac", "macOS", "Steam Deck", "Wine", "Lutris", "CrossOver", "Proton compatibility"],
    "gta5/plus-setup": ["Plus", "bootloader", "UEFI", "BIOS", "motherboard", "ASUS", "MSI", "Gigabyte", "AORUS", "ASRock", "Secure Boot", "Fast Boot", "Memory Integrity", "Load Driver At Next Boot", "ClickUI", "ListUI", "F1", "Insert", "F2"],
    "gta5/hypervisor-vbs": ["check_vbs.bat", "VBS diagnostic", "hypervisor is running", "HVCI", "Device Guard", "Credential Guard", "virtualization", "download script"],
}
LOADING_GUIDES = {
    "gta5/free-setup", "gta5/premium-free-setup", "rdr2/rdr2-launch", "fivem/fivem-inject", "redm/redm-inject",
    "cs2/cs2-inject", "l4d/getting-started", "gmod/getting-started",
    "half-life-1/getting-started", "megabonk/getting-started", "sbox/getting-started",
    "tf2/getting-started", "last-of-us/getting-started",
}
LOADING_ALIASES = ["loading guide", "loader screenshots", "sign in", "signin", "login", "Free key", "Premium account", "choose game", "loading progress", "loaded", "completion"]


class GuideParser(HTMLParser):
    def __init__(self, slug, name):
        super().__init__(convert_charrefs=True)
        self.slug, self.name = slug, name
        self.depth = 0
        self.heading = False
        self.topic = None
        self.topics = []
        self.noindex = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "meta" and attrs.get("name", "").lower() == "robots":
            self.noindex = "noindex" in [token.strip().lower() for token in attrs.get("content", "").split(",")]
        if tag == "div":
            if "guide-card" in attrs.get("class", "").split() and attrs.get("id"):
                self.topic = {"game": self.name, "title": [], "text": [],
                              "href": f"/guides/{self.slug}/#{attrs['id']}"}
                self.depth = 0
            if self.topic is not None:
                self.depth += 1
        if self.topic is not None and tag == "h2" and not self.topic["title"]:
            self.heading = True

    def handle_data(self, data):
        if self.topic is not None:
            self.topic["text"].append(data)
            if self.heading:
                self.topic["title"].append(data)

    def handle_endtag(self, tag):
        if tag == "h2":
            self.heading = False
        if tag == "div" and self.topic is not None:
            self.depth -= 1
            if self.depth == 0:
                for field in ("title", "text"):
                    self.topic[field] = " ".join(" ".join(self.topic[field]).split())
                self.topics.append(self.topic)
                self.topic = None


if __name__ == "__main__":
    topics = []
    for slug, name in GAMES.items():
        for article in sorted((ROOT / "guides" / slug).glob("*/index.html")):
            parser = GuideParser(slug, name)
            parser.feed(article.read_text(encoding="utf-8"))
            if parser.noindex:
                continue
            for topic in parser.topics:
                topic["href"] = f"/guides/{slug}/{article.parent.name}/"
                page_key = f"{slug}/{article.parent.name}"
                aliases = [slug] + SEARCH_ALIASES.get(slug, []) + PAGE_SEARCH_ALIASES.get(page_key, [])
                if page_key in LOADING_GUIDES:
                    aliases += LOADING_ALIASES
                topic["tags"] = list(dict.fromkeys(aliases))
            topics.extend(parser.topics)
    target = ROOT / "assets" / "data" / "guide-search.json"
    topics.extend([
        {
            "game": "All games", "title": "How to load Scooby",
            "href": "/guides/loading/",
            "text": "Premium account and Free key sign-in, game selection, loading progress and completion screenshots. " + " ".join(GAMES.values()) + " MTA:SA",
            "tags": ["load", "loading", "loader", "setup", "screenshots", "all games", "sign in", "signin", "login", "game selection", "progress", "completion"],
        },
        {
            "game": "General help", "title": "Premium sign-in & redeem a license key",
            "href": "/guides/loading/#redeem-key",
            "text": "Sign in to the Scooby portal with the account you created. Dashboard, Redeem license key, paste purchased license, Redeem key. In the loader use Premium, username and password. Free keys work only in the loader's Free login, not the portal or dashboard.",
            "tags": ["Premium", "redeem key", "redeem code", "license", "licence", "activation code", "activate", "account", "login", "signin", "sign in", "password", "portal", "dashboard"],
        },
        {
            "game": "General help", "title": "Free key reset: renew every 24 hours",
            "href": "/guides/general/free-key/#copy-free-key",
            "text": "One free key supports all Scooby Free versions. Get a new key every 24 hours, complete the access steps, copy the key and enter it in the loader's Free tab. Free keys do not sign in to the portal or dashboard.",
            "tags": PAGE_SEARCH_ALIASES["general/free-key"],
        },
        {
            "game": "General help", "title": "Website or loader won't connect: VPN & network help",
            "href": "/guides/general/free-key/#key-site-connection",
            "text": "The website or loader says server not found, site cannot be reached or connection timed out. Check the address, try a hotspot, or test a VPN or trusted proxy. ISP or country restrictions, DNS problems and temporary outages are possible causes. Free options: Cloudflare 1.1.1.1 with WARP and Proton VPN. Backend or hosting-provider outages can be outside Scooby's direct control; wait and retry later. A VPN cannot fix a server outage.",
            "tags": PAGE_SEARCH_ALIASES["general/connection"] + ["BSTLAR", "free key website"],
        },
        {
            "game": "General help", "title": "Loader connection: backend & hosting outages",
            "href": "/guides/general/connection/#server-outage",
            "text": "The loader cannot connect or keeps timing out across different networks. Backend services or server-hosting providers may be having an outage outside Scooby's direct control. Wait for recovery and retry later. A VPN or proxy cannot fix a server-side outage.",
            "tags": ["loader connection issues", "backend outage", "server hosting", "hosting provider", "server down", "timeout", "cannot connect", "service unavailable"],
        },
        {
            "game": "MTA:SA", "title": "MTA:SA loading status",
            "href": "/guides/mta-sa/#load-guide",
            "text": "Multi Theft Auto: San Andreas. Current native loader Testing / Paused status and runtime requirements.",
            "tags": ["MTA", "MTA:SA", "loading", "loader", "paused", "testing"],
        },
    ])
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(topics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Indexed {len(topics)} guide topics.")
