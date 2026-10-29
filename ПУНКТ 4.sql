CREATE TABLE users (
    user_id       integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      varchar(50)  NOT NULL UNIQUE,
    password_hash varchar(255) NOT NULL,
    role          varchar(10)  NOT NULL DEFAULT 'User'
                  CHECK (role IN ('Admin', 'User')),
    created_at    timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE heroes (
    hero_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           varchar(80) NOT NULL UNIQUE,
    localized_name varchar(80),
    is_active      boolean     NOT NULL DEFAULT true
);

CREATE TABLE items (
    item_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           varchar(80) NOT NULL UNIQUE,
    localized_name varchar(80)
);

CREATE TABLE matches (
    match_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          integer     NOT NULL REFERENCES users(user_id),
    played_at        timestamptz NOT NULL,
    duration_seconds integer     NOT NULL CHECK (duration_seconds > 0),
    result           varchar(4)  NOT NULL CHECK (result IN ('Win', 'Loss')),
    notes            varchar(500)
);

CREATE TABLE match_players (
    match_player_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id         integer NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    hero_id          integer NOT NULL REFERENCES heroes(hero_id),
    role             varchar(20),
    kills            integer NOT NULL DEFAULT 0 CHECK (kills >= 0),
    deaths           integer NOT NULL DEFAULT 0 CHECK (deaths >= 0),
    assists          integer NOT NULL DEFAULT 0 CHECK (assists >= 0),
    gpm              integer NOT NULL DEFAULT 0 CHECK (gpm >= 0),
    xpm              integer NOT NULL DEFAULT 0 CHECK (xpm >= 0),
    hero_damage      integer NOT NULL DEFAULT 0 CHECK (hero_damage >= 0),
    tower_damage     integer NOT NULL DEFAULT 0 CHECK (tower_damage >= 0),
    performance_score smallint CHECK (performance_score BETWEEN 0 AND 100),
    is_game_mvp      boolean NOT NULL DEFAULT false
);

CREATE TABLE match_player_items (
    match_player_item_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_player_id      integer NOT NULL
                         REFERENCES match_players(match_player_id) ON DELETE CASCADE,
    item_id              integer NOT NULL REFERENCES items(item_id),
    slot_number          smallint NOT NULL CHECK (slot_number BETWEEN 0 AND 20),
    UNIQUE (match_player_id, slot_number)
);

CREATE INDEX idx_matches_user_played_at
    ON matches(user_id, played_at DESC);

CREATE INDEX idx_match_players_hero
    ON match_players(hero_id);