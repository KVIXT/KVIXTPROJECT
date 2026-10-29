CREATE TABLE IF NOT EXISTS users (
    user_id       integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username      varchar(50)  NOT NULL UNIQUE,
    password_hash varchar(255) NOT NULL,
    role          varchar(10)  NOT NULL DEFAULT 'User'
                  CHECK (role IN ('Admin', 'User')),
    email         varchar(100) UNIQUE,
    created_at    timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS player_profiles (
    profile_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       integer NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    steam_id      varchar(50) UNIQUE,
    player_name   varchar(100) NOT NULL,
    total_matches integer NOT NULL DEFAULT 0 CHECK (total_matches >= 0),
    total_wins    integer NOT NULL DEFAULT 0 CHECK (total_wins >= 0),
    rank          varchar(20) DEFAULT 'Uncalibrated',
    mmr           integer DEFAULT 0 CHECK (mmr >= 0),
    current_rank_tier smallint CHECK (current_rank_tier BETWEEN 0 AND 7),
    created_at    timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS heroes (
    hero_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           varchar(80) NOT NULL UNIQUE,
    localized_name varchar(80),
    complexity     smallint CHECK (complexity BETWEEN 1 AND 3),
    is_active      boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS items (
    item_id        integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           varchar(80) NOT NULL UNIQUE,
    localized_name varchar(80),
    is_active      boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS matches (
    match_id              integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    profile_id            integer NOT NULL REFERENCES player_profiles(profile_id) ON DELETE CASCADE,
    played_at             timestamptz NOT NULL,
    duration_seconds      integer NOT NULL CHECK (duration_seconds > 0),
    result                varchar(4) NOT NULL CHECK (result IN ('Win', 'Loss')),
    side                  varchar(10) CHECK (side IN ('Radiant', 'Dire')),
    game_mode             varchar(30),
    player_rank_at_match  varchar(20),
    player_mmr_at_match   integer,
    created_at            timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS match_players (
    match_player_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id          integer NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
    hero_id           integer NOT NULL REFERENCES heroes(hero_id),
    role              varchar(20),
    kills             integer NOT NULL DEFAULT 0 CHECK (kills >= 0),
    deaths            integer NOT NULL DEFAULT 0 CHECK (deaths >= 0),
    assists           integer NOT NULL DEFAULT 0 CHECK (assists >= 0),
    gpm               integer NOT NULL DEFAULT 0 CHECK (gpm >= 0),
    xpm               integer NOT NULL DEFAULT 0 CHECK (xpm >= 0),
    hero_damage       integer NOT NULL DEFAULT 0 CHECK (hero_damage >= 0),
    tower_damage      integer NOT NULL DEFAULT 0 CHECK (tower_damage >= 0),
    last_hits         integer NOT NULL DEFAULT 0 CHECK (last_hits >= 0),
    denies            integer NOT NULL DEFAULT 0 CHECK (denies >= 0),
    performance_score smallint CHECK (performance_score BETWEEN 0 AND 100),
    is_game_mvp       boolean NOT NULL DEFAULT false,
    created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS match_player_items (
    match_player_item_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_player_id      integer NOT NULL REFERENCES match_players(match_player_id) ON DELETE CASCADE,
    item_id              integer NOT NULL REFERENCES items(item_id),
    slot_number          smallint NOT NULL CHECK (slot_number BETWEEN 0 AND 20),
    UNIQUE (match_player_id, slot_number)
);

CREATE TABLE IF NOT EXISTS player_hero_stats (
    hero_stat_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    profile_id     integer NOT NULL REFERENCES player_profiles(profile_id) ON DELETE CASCADE,
    hero_id        integer NOT NULL REFERENCES heroes(hero_id),
    total_matches  integer NOT NULL DEFAULT 0 CHECK (total_matches >= 0),
    wins           integer NOT NULL DEFAULT 0 CHECK (wins >= 0),
    losses         integer NOT NULL DEFAULT 0 CHECK (losses >= 0),
    UNIQUE (profile_id, hero_id)
);

CREATE TABLE IF NOT EXISTS player_role_stats (
    role_stat_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    profile_id     integer NOT NULL REFERENCES player_profiles(profile_id) ON DELETE CASCADE,
    role           varchar(20) NOT NULL,
    total_matches  integer NOT NULL DEFAULT 0 CHECK (total_matches >= 0),
    wins           integer NOT NULL DEFAULT 0 CHECK (wins >= 0),
    losses         integer NOT NULL DEFAULT 0 CHECK (losses >= 0),
    UNIQUE (profile_id, role)
);

CREATE INDEX IF NOT EXISTS idx_matches_profile_played_at ON matches(profile_id, played_at DESC);
CREATE INDEX IF NOT EXISTS idx_match_players_hero ON match_players(hero_id);
CREATE INDEX IF NOT EXISTS idx_player_hero_stats_profile ON player_hero_stats(profile_id);
CREATE INDEX IF NOT EXISTS idx_player_role_stats_profile ON player_role_stats(profile_id);

DELETE FROM users WHERE user_id > 0;
INSERT INTO users (username, password_hash, role, email) VALUES
('yaroslav', 'hashed_password_1', 'Admin', 'yaroslav@mail.com'),
('pro_player', 'hashed_password_2', 'User', 'pro@mail.com'),
('casual_gamer', 'hashed_password_3', 'User', 'casual@mail.com'),
('streamer', 'hashed_password_4', 'User', 'streamer@mail.com'),
('dev_test', 'hashed_password_5', 'User', 'dev@mail.com');

DELETE FROM player_profiles;
INSERT INTO player_profiles (user_id, steam_id, player_name, total_matches, total_wins, rank, mmr, current_rank_tier) VALUES
(1, '76561198123456789', 'Yaroslav', 150, 85, 'Archon', 4800, 4),
(2, '76561198987654321', 'ProPlayer', 300, 180, 'Divine', 7200, 7),
(3, '76561198111222333', 'CasualGamer', 50, 22, 'Guardian', 1200, 2),
(4, '76561198444555666', 'Streamer', 250, 140, 'Legend', 5800, 5),
(5, '76561198777888999', 'DevTest', 20, 10, 'Crusader', 2400, 3);

DELETE FROM heroes;
INSERT INTO heroes (name, localized_name, complexity, is_active) VALUES
('Anti-Mage', 'Анти-Мейдж', 1, true),
('Axe', 'Топор', 1, true),
('Beastmaster', 'Повелитель зверей', 2, true),
('Bloodseeker', 'Охотник на кровь', 1, true),
('Bristleback', 'Щетинник', 1, true),
('Centaur Warrunner', 'Кентавр', 2, true),
('Chaos Knight', 'Рыцарь Хаоса', 2, true),
('Clockwerk', 'Часовой механизм', 2, true),
('Crystal Maiden', 'Хрустальная Дева', 1, true),
('Drow Ranger', 'Призрачница', 1, true),
('Earthshaker', 'Землетряс', 2, true),
('Elder Titan', 'Титан Старший', 3, true),
('Enchantress', 'Чаровница', 2, true),
('Enigma', 'Загадка', 3, true),
('Faceless Void', 'Безликий Пустотник', 2, true),
('Furion', 'Фурион', 2, true),
('Gyrocopter', 'Гирокоптер', 1, true),
('Huskar', 'Хускар', 1, true),
('Invoker', 'Чародей', 3, true),
('Jakiro', 'Джакиро', 2, true),
('Juggernaut', 'Джаггернаут', 1, true),
('Keeper of the Light', 'Хранитель Света', 2, true),
('Kunkka', 'Кункка', 2, true),
('Legion Commander', 'Командир Легиона', 1, true),
('Leshrac', 'Лешрак', 2, true),
('Lich', 'Лич', 1, true),
('Lina', 'Лина', 2, true),
('Lion', 'Лев', 1, true),
('Lifestealer', 'Пожиратель жизни', 1, true),
('Lone Druid', 'Одинокий Друид', 3, true),
('Luna', 'Луна', 1, true),
('Lycan', 'Ликан', 2, true),
('Magnataur', 'Магнетавр', 2, true),
('Mirana', 'Миран', 2, true),
('Medusa', 'Медуза', 2, true),
('Meepo', 'Мипо', 3, true),
('Morphling', 'Морфлинг', 3, true),
('Naga Siren', 'Наг Сирена', 2, true),
('Necrophos', 'Некролос', 1, true),
('Night Stalker', 'Ночной охотник', 2, true),
('Nyx Assassin', 'Найкс Убийца', 2, true),
('Ogre Magi', 'Огр-маг', 1, true),
('Omniknight', 'Вседержитель', 1, true),
('Oracle', 'Оракул', 3, true),
('Outworld Devourer', 'Пожиратель миров', 2, true),
('Phantom Assassin', 'Призрачная Убийца', 2, true),
('Phantom Lancer', 'Копейщик-Призрак', 2, true),
('Phoenix', 'Феникс', 2, true),
('Puck', 'Пак', 2, true),
('Pudge', 'Пудж', 2, true),
('Pugna', 'Пугна', 2, true),
('Queen of Pain', 'Королева боли', 2, true),
('Razor', 'Электроид', 2, true),
('Riki', 'Рики', 2, true),
('Rubick', 'Рубик', 2, true),
('Sand King', 'Король песков', 2, true),
('Shadow Demon', 'Демон-Тень', 2, true),
('Shadow Fiend', 'Повелитель теней', 3, true),
('Shadow Shaman', 'Шаман-Тень', 2, true),
('Silencer', 'Безмолвствующий', 2, true),
('Skeleton King', 'Король Скелетов', 1, true),
('Skywrath Mage', 'Небесный маг', 1, true),
('Slardar', 'Слардар', 1, true),
('Slark', 'Тьма', 2, true),
('Snapfire', 'Снэпфайр', 2, true),
('Sniper', 'Снайпер', 1, true),
('Spectre', 'Призрак', 2, true),
('Spirit Breaker', 'Разрушитель Духов', 1, true),
('Storm Spirit', 'Дух Грозы', 2, true),
('Sven', 'Свен', 1, true),
('Techies', 'Техники', 3, true),
('Templar Assassin', 'Храмовая Убийца', 2, true),
('Terrorblade', 'Клинок Ужаса', 2, true),
('Tidehunter', 'Охотник на Волны', 1, true),
('Tinker', 'Механик', 3, true),
('Tiny', 'Крошка', 2, true),
('Treant Protector', 'Защитник лесов', 1, true),
('Troll Warlord', 'Тролль-Полководец', 2, true),
('Tusk', 'Клык', 2, true),
('Underlord', 'Владыка подземелья', 2, true),
('Undying', 'Нежить', 1, true),
('Ursa', 'Урса', 1, true),
('Vengeful Spirit', 'Мстительница', 1, true),
('Venom', 'Ядовитый венок', 1, true),
('Viper', 'Гадюка', 1, true),
('Visage', 'Лик', 2, true),
('Void Spirit', 'Дух Пустоты', 2, true),
('Warlock', 'Чернокнижник', 2, true),
('Weaver', 'Ткач', 2, true),
('Windranger', 'Странница ветра', 2, true),
('Witch Doctor', 'Ведьмак', 2, true),
('Wraith King', 'Король Привидений', 1, true),
('Zeus', 'Зевс', 1, true),
('Abaddon', 'Абаддон', 1, true),
('Alchemist', 'Алхимик', 2, true),
('Batrider', 'Летучий всадник', 2, true),
('Brewmaster', 'Мастер пива', 3, true),
('Dark Willow', 'Тёмная Ива', 2, true),
('Dazzle', 'Ослепляющий', 2, true),
('Doom', 'Рок', 2, true),
('Dragon Knight', 'Рыцарь-Дракон', 1, true),
('Earth Spirit', 'Дух Земли', 3, true),
('Grim Stem', 'Мрачный стебель', 2, true),
('Grimstroke', 'Мрачный штрих', 2, true),
('Hoodwink', 'Коротышка', 2, true),
('Io', 'Ио', 3, true),
('Marci', 'Марси', 1, true),
('Mars', 'Марс', 1, true),
('Monkey King', 'Король Обезьян', 2, true),
('Muerta', 'Мертва', 2, true),
('Nature Prophet', 'Пророк Природы', 2, true),
('Pangolier', 'Панголье', 2, true),
('Primal Beast', 'Первобытный зверь', 2, true),
('Pango Rider', 'Всадник Панго', 2, true),
('Roshan', 'Рошан', 3, true),
('Snapfire Elder', 'Старейший Снэпфайр', 2, true),
('Spirit Breaker Prime', 'Разрушитель Духов Прайм', 2, true),
('Sunray', 'Солнечный луч', 2, true),
('Taiga', 'Тайга', 1, true),
('Tidecaller', 'Зовущий волны', 2, true),
('Tusk Prime', 'Клык Прайм', 2, true),
('Veno Summoner', 'Венозный Призыватель', 2, true),
('Warden', 'Страж', 1, true),
('Water Warden', 'Страж Воды', 2, true),
('Yennefer', 'Йеннифер', 2, true),
('Zilean', 'Зилеан', 1, true),
('Zyx', 'Зикс', 1, true);

DELETE FROM items;
INSERT INTO items (name, localized_name, is_active) VALUES
('Power Treads', 'Боевые Сапоги', true),
('Radiance', 'Сияние', true),
('Battle Fury', 'Ярость Боя', true),
('Blink Dagger', 'Клинок Мига', true),
('Black King Bar', 'Чёрный Посох Королей', true),
('Manta Style', 'Манта Стиль', true),
('Butterfly', 'Бабочка', true),
('Skull Basher', 'Дробилка Черепов', true),
('Pipe of Insight', 'Труба Прозрения', true),
('Shivas Guard', 'Защита Шивы', true),
('Bottle', 'Бутылка', true),
('Urn of Shadows', 'Урна Теней', true),
('Drum of Endurance', 'Барабан Выносливости', true),
('Force Staff', 'Посох Силы', true),
('Euls Scepter', 'Скипетр Эйла', true),
('Rod of Atos', 'Жезл Атоса', true),
('Dagon', 'Дагон', true),
('Desolator', 'Опустошитель', true),
('Assault Cuirass', 'Штурмовой Кираса', true),
('Heart of Tarrasque', 'Сердце Террабластера', true),
('Satanic', 'Сатаник', true),
('Abyssal Blade', 'Чёрный Клинок', true),
('Mjolnir', 'Мьёльнир', true),
('Divine Rapier', 'Божественный Клинок', true),
('Bloodstone', 'Кровавый Камень', true),
('Aghanims Scepter', 'Скипетр Агханима', true),
('Aghanims Shard', 'Обломок Скипетра', true),
('Ethereal Blade', 'Эфирный Клинок', true),
('Eye of Skadi', 'Глаз Скади', true),
('Diffusal Blade', 'Клинок Рассеяния', true),
('Scythe of Vyse', 'Коса Вайса', true),
('Aeon Disk', 'Диск Эона', true),
('Aether Lens', 'Линза Эфира', true),
('Ancient Janggo', 'Древний Джанго', true),
('Arcane Boots', 'Арканные сапоги', true),
('Basilius Ring', 'Кольцо Василиска', true),
('Boots of Travel', 'Сапоги странствий', true),
('Buckler', 'Щиток', true),
('Chainmail', 'Кольчуга', true),
('Circlet', 'Диадема', true),
('Cloak', 'Плащ', true),
('Crown', 'Корона', true),
('Dagger', 'Кинжал', true),
('Dust of Appearance', 'Пыль Явления', true),
('Echo Sabre', 'Сабля Эха', true),
('Executioners Axe', 'Топор Палача', true),
('Gauntlets of Strength', 'Перчатки Силы', true),
('Ghost Scepter', 'Призрачный Скипетр', true),
('Gloves of Haste', 'Перчатки Спешки', true),
('Heaven Halberd', 'Глефа Небес', true),
('Helm of the Dominator', 'Шлем Властелина', true),
('Holy Locket', 'Святой Медальон', true),
('Hyperstone', 'Гиперкамень', true),
('Infused Raindrops', 'Насыщенные капли дождя', true),
('Iron Branch', 'Железная ветвь', true),
('Javelin', 'Копьё', true),
('Kraken Shell', 'Панцирь Кракена', true),
('Leather Armor', 'Кожаная броня', true),
('Linkens Sphere', 'Сфера Линкена', true),
('Living Armor', 'Живая броня', true),
('Longevity Aura', 'Аура долголетия', true),
('Lotus Orb', 'Сфера Лотоса', true),
('Maelstrom', 'Спрут', true),
('Mantle', 'Мантия', true),
('Mask of Madness', 'Маска Безумия', true),
('Meteor Hammer', 'Молот Метеора', true),
('Mirror Shield', 'Зеркальный Щит', true),
('Mithril Hammer', 'Молот Мифрила', true),
('Morbid Mask', 'Мертвенная маска', true),
('Morning Star', 'Утренняя звезда', true),
('Mystic Staff', 'Мистический посох', true),
('Necronomicon', 'Некрономикон', true),
('Nether Wand', 'Палочка Преисподней', true);

DELETE FROM matches;
INSERT INTO matches (profile_id, played_at, duration_seconds, result, side, game_mode, player_rank_at_match, player_mmr_at_match) VALUES
(1, now() - interval '1 day', 2400, 'Win', 'Radiant', 'All Pick', 'Archon', 4800),
(1, now() - interval '2 days', 1800, 'Loss', 'Dire', 'All Pick', 'Archon', 4770),
(1, now() - interval '3 days', 2100, 'Win', 'Radiant', 'All Pick', 'Archon', 4785),
(2, now() - interval '1 day', 2500, 'Win', 'Radiant', 'All Pick', 'Divine', 7250),
(2, now() - interval '2 days', 1700, 'Win', 'Dire', 'All Pick', 'Divine', 7210),
(3, now() - interval '1 day', 1800, 'Win', 'Radiant', 'All Pick', 'Guardian', 1250),
(3, now() - interval '2 days', 2100, 'Loss', 'Dire', 'All Pick', 'Guardian', 1190),
(4, now() - interval '1 day', 2400, 'Win', 'Radiant', 'All Pick', 'Legend', 5850),
(4, now() - interval '2 days', 2200, 'Win', 'Dire', 'All Pick', 'Legend', 5820),
(5, now() - interval '1 day', 1700, 'Win', 'Radiant', 'All Pick', 'Crusader', 2450);

DELETE FROM match_players;
INSERT INTO match_players (match_id, hero_id, role, kills, deaths, assists, gpm, xpm, hero_damage, tower_damage, last_hits, denies, performance_score, is_game_mvp) VALUES
(1, 1, 'Carry', 15, 2, 5, 650, 500, 45000, 2000, 350, 50, 85, true),
(1, 10, 'Mid', 12, 1, 8, 580, 480, 38000, 1500, 280, 30, 80, false),
(2, 5, 'Support', 2, 5, 20, 250, 300, 8000, 0, 50, 10, 45, false),
(2, 25, 'Mid', 8, 6, 4, 400, 350, 25000, 500, 150, 20, 55, false),
(3, 21, 'Carry', 18, 1, 6, 700, 520, 52000, 3000, 420, 60, 92, true),
(3, 9, 'Support', 1, 3, 18, 200, 280, 5000, 200, 40, 5, 50, false),
(4, 64, 'Mid', 14, 2, 10, 620, 500, 41000, 2000, 310, 25, 88, true),
(4, 3, 'Support', 2, 1, 25, 280, 350, 12000, 500, 60, 10, 78, false),
(5, 2, 'Carry', 16, 1, 7, 680, 510, 48000, 2500, 380, 55, 90, true),
(6, 9, 'Support', 1, 2, 22, 210, 270, 4000, 100, 30, 5, 72, false),
(7, 15, 'Offlane', 7, 5, 11, 350, 380, 22000, 3500, 110, 10, 58, false),
(8, 10, 'Mid', 13, 2, 9, 600, 490, 39000, 1800, 290, 28, 82, false),
(9, 1, 'Carry', 17, 1, 5, 720, 530, 50000, 3200, 440, 70, 95, true),
(10, 27, 'Support', 3, 3, 19, 270, 320, 8000, 400, 50, 10, 65, false);

DELETE FROM match_player_items;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS profile_id integer;
INSERT INTO match_player_items (match_player_id, item_id, slot_number) VALUES
(1, 1, 0), (1, 2, 1), (1, 3, 2), (1, 5, 3), (1, 11, 4), (1, 21, 5),
(2, 1, 0), (2, 6, 1), (2, 14, 2), (2, 17, 3), (2, 9, 4),
(3, 1, 0), (3, 9, 1), (3, 10, 2), (3, 15, 3),
(4, 1, 0), (4, 3, 1), (4, 5, 2), (4, 7, 3), (4, 20, 4), (4, 26, 5),
(5, 1, 0), (5, 6, 1), (5, 11, 2), (5, 16, 3),
(6, 1, 0), (6, 4, 1), (6, 13, 2), (6, 24, 3), (6, 25, 4),
(7, 1, 0), (7, 8, 1), (7, 10, 2), (7, 19, 3),
(8, 1, 0), (8, 18, 1), (8, 23, 2), (8, 11, 3),
(9, 1, 0), (9, 14, 1), (9, 21, 2), (9, 26, 3),
(10, 1, 0), (10, 6, 1), (10, 5, 2), (10, 20, 3), (10, 24, 4),
(11, 1, 0), (11, 3, 1), (11, 7, 2), (11, 22, 3), (11, 25, 4),
(12, 1, 0), (12, 4, 1), (12, 18, 2), (12, 23, 3), (12, 24, 4),
(13, 1, 0), (13, 6, 1), (13, 5, 2), (13, 9, 3), (13, 20, 4),
(14, 1, 0), (14, 8, 1), (14, 15, 2), (14, 21, 3);

DELETE FROM player_hero_stats;
INSERT INTO player_hero_stats (profile_id, hero_id, total_matches, wins, losses) VALUES
(1, 1, 25, 18, 7),
(1, 21, 20, 15, 5),
(1, 10, 15, 10, 5),
(2, 21, 40, 28, 12),
(2, 1, 35, 26, 9),
(2, 64, 30, 22, 8),
(3, 5, 15, 8, 7),
(3, 9, 10, 5, 5),
(4, 10, 35, 21, 14),
(4, 3, 30, 18, 12),
(4, 9, 25, 15, 10),
(5, 64, 12, 8, 4),
(5, 2, 8, 5, 3);

DELETE FROM player_role_stats;
INSERT INTO player_role_stats (profile_id, role, total_matches, wins, losses) VALUES
(1, 'Carry', 45, 32, 13),
(1, 'Mid', 30, 21, 9),
(1, 'Support', 15, 10, 5),
(2, 'Carry', 80, 55, 25),
(2, 'Mid', 60, 42, 18),
(2, 'Offlane', 50, 35, 15),
(3, 'Carry', 20, 11, 9),
(3, 'Mid', 15, 8, 7),
(4, 'Mid', 60, 38, 22),
(4, 'Carry', 50, 32, 18),
(4, 'Offlane', 40, 25, 15),
(5, 'Carry', 18, 11, 7),
(5, 'Mid', 2, 1, 1);

SELECT 'Heroes:' as check_type, COUNT(*) as count FROM heroes
UNION ALL
SELECT 'Items:', COUNT(*) FROM items
UNION ALL
SELECT 'Profiles:', COUNT(*) FROM player_profiles
UNION ALL
SELECT 'Matches:', COUNT(*) FROM matches
UNION ALL
SELECT 'Match Players:', COUNT(*) FROM match_players;

SELECT profile_id, player_name, rank, mmr FROM player_profiles ORDER BY mmr DESC;