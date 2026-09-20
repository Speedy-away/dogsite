"""Rebuild wiki search after editing a guide: python tools/build-guide-search.py."""
import json
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GAMES = {
    "gta5": "GTA 5",
    "fivem": "FiveM",
    "redm": "RedM",
    "rdr2": "Red Dead Redemption 2",
    "cs2": "Counter-Strike 2",
    "sbox": "S&box (Sandbox)",
    "gmod": "Garry's Mod (GMOD)",
    "general": "General help",
}


class GuideParser(HTMLParser):
    def __init__(self, slug, name):
        super().__init__(convert_charrefs=True)
        self.slug, self.name = slug, name
        self.depth = 0
        self.heading = False
        self.topic = None
        self.topics = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == "div":
            if "guide-card" in attrs.get("class", "").split() and attrs.get("id"):
                self.topic = {"game": self.name, "title": [], "text": [],
                              "href": f"/guides/{self.slug}/#{attrs['id']}"}
                self.depth = 0
            if self.topic is not None:
                self.depth += 1
        if self.topic is not None and tag == "h2":
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
            for topic in parser.topics:
                topic["href"] = f"/guides/{slug}/{article.parent.name}/"
            topics.extend(parser.topics)
    target = ROOT / "assets" / "data" / "guide-search.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(topics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Indexed {len(topics)} guide topics.")
