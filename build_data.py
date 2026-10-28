"""Fetch top-250 games from RAWG + generate synthetic users/activity, emit MySQL INSERTs to data.sql.

Run: python3 build_data.py [ordering]   (default -metacritic; e.g. -added = most popular)
RAWG responses cached in rawg_cache[_<ordering>].json; delete it to refetch.
"""
import json, os, random, sys, datetime as dt
import requests
from concurrent.futures import ThreadPoolExecutor
from reviews import REVIEWS

KEY = open('.env').read().split('=', 1)[1].strip().strip('"\'')
ORDERING = sys.argv[1] if len(sys.argv) > 1 else '-metacritic'
SUFFIX = '' if ORDERING == '-metacritic' else '_' + ORDERING.strip('-')
CACHE, OUT = f'rawg_cache{SUFFIX}.json', f'data{SUFFIX}.sql'
N_GAMES, N_ACH = 250, 10
TODAY = dt.date(2026, 10, 28)


def get(path, **params):
    r = requests.get(f'https://api.rawg.io/api/{path}', params={'key': KEY, **params}, timeout=30)
    r.raise_for_status()
    return r.json()


def fetch_rawg():
    games, page = [], 1
    while len(games) < N_GAMES:
        games += get('games', ordering=ORDERING, page_size=40, page=page)['results']
        page += 1
    games = games[:N_GAMES]

    def enrich(g):
        devs = get(f'games/{g["id"]}')['developers']
        g['developer'] = devs[0]['name'] if devs else None
        g['achievements'] = get(f'games/{g["id"]}/achievements', page_size=N_ACH)['results'][:N_ACH]

    with ThreadPoolExecutor(10) as pool:
        for i, _ in enumerate(pool.map(enrich, games), 1):
            print(f'{i}/{N_GAMES}', flush=True)
    return games


def sql(v):
    if v is None or v == '':
        return 'NULL'
    if isinstance(v, int):
        return str(v)
    return "'" + str(v).replace('\\', '\\\\').replace("'", "''") + "'"


def inserts(table, cols, rows):
    if not rows:
        return ''
    vals = ',\n'.join('(' + ', '.join(sql(v) for v in r) + ')' for r in rows)
    return f'INSERT INTO {table} ({", ".join(cols)}) VALUES\n{vals};\n\n'


def rand_date(start, end):
    start = min(start, end)
    return start + dt.timedelta(days=random.randint(0, (end - start).days))


if os.path.exists(CACHE):
    raw = json.load(open(CACHE))
else:
    raw = fetch_rawg()
    json.dump(raw, open(CACHE, 'w'))

# --- RAWG data, our own ids ---
games, platforms, genres, available_on, belongs_to, achievements = [], {}, {}, [], [], []
for gid, g in enumerate(raw, 1):
    games.append((gid, g['id'], g['name'], g['released'], g['developer']))
    for p in g.get('platforms') or []:
        pid = platforms.setdefault(p['platform']['name'], len(platforms) + 1)
        available_on.append((gid, pid))
    for ge in g.get('genres') or []:
        geid = genres.setdefault(ge['name'], len(genres) + 1)
        belongs_to.append((gid, geid))
    for a in g['achievements']:
        achievements.append((len(achievements) + 1, a['name'], a.get('description'), gid))

# --- synthetic users/activity ---
random.seed(436)
names = ['pixelpanda', 'noscope_nina', 'retro_rick', 'speedrun_sam', 'lootgoblin',
         'questqueen', 'tankmain_tom', 'cozygamer_cat', 'bossfight_ben', 'glitchhunter']
users = [(i, n, f'{n}@example.com', rand_date(dt.date(2023, 1, 1), dt.date(2025, 6, 1)).isoformat())
         for i, n in enumerate(names, 1)]

follows = sorted({(u, v) for u, *_ in users
                  for v in random.sample([x[0] for x in users if x[0] != u], random.randint(2, 4))})

game_release = {g[0]: dt.date.fromisoformat(g[3]) if g[3] else dt.date(2000, 1, 1) for g in games}
ach_by_game = {}
for a in achievements:
    ach_by_game.setdefault(a[3], []).append(a[0])

game_by_title = {g[2]: g[0] for g in games}
user_by_name = {u[1]: (u[0], dt.date.fromisoformat(u[3])) for u in users}
missing = [t for _, t, _, _ in REVIEWS if t not in game_by_title]
assert not missing, f'reviewed titles not in this RAWG set: {missing}'

reviews, unlocks = [], set()
for name, title, rating, text in REVIEWS:
    uid, join = user_by_name[name]
    gid = game_by_title[title]
    date = rand_date(max(join, game_release[gid]), TODAY)
    reviews.append((len(reviews) + 1, rating, text, date.isoformat(), uid, gid))
    pool = ach_by_game.get(gid, [])
    unlocks |={(uid, a) for a in random.sample(pool, random.randint(0, min(4, len(pool))))}
unlocks = sorted(unlocks)

assert all(u != v for u, v in follows)
assert len({(r[4], r[5]) for r in reviews}) == len(reviews)  # one review per user per game

with open(OUT, 'w') as f:
    f.write('SET NAMES utf8mb4;\n\n')
    f.write(inserts('platform', ['platform_id', 'name'], [(i, n) for n, i in platforms.items()]))
    f.write(inserts('genre', ['genre_id', 'name'], [(i, n) for n, i in genres.items()]))
    f.write(inserts('game', ['game_id', 'rawg_id', 'title', 'release_date', 'developer'], games))
    f.write(inserts('available_on', ['game_id', 'platform_id'], available_on))
    f.write(inserts('belongs_to', ['game_id', 'genre_id'], belongs_to))
    f.write(inserts('achievement', ['achievement_id', 'name', 'description', 'game_id'], achievements))
    f.write(inserts('`user`', ['user_id', 'username', 'email', 'join_date'], users))
    f.write(inserts('follows', ['user_id_1', 'user_id_2'], follows))
    f.write(inserts('review', ['review_id', 'rating', 'review_text', 'review_date', 'user_id', 'game_id'], reviews))
    f.write(inserts('unlocks', ['user_id', 'achievement_id'], unlocks))

print(f'games={len(games)} platforms={len(platforms)} genres={len(genres)} achievements={len(achievements)} '
      f'users={len(users)} follows={len(follows)} reviews={len(reviews)} unlocks={len(unlocks)}')
