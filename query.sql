-- Reset (so the script can be rerun)
DROP TABLE IF EXISTS WISHLIST;
DELETE FROM USER WHERE user_id = 9001;

-- DDL
SHOW TABLES;
select * from user;
select * from follows;
select * from game;
select * from review;
select * from platform;
select * from achievement;
select * from genre;
select * from unlocks;
select * from available_on;
select * from belongs_to;

-- Create
CREATE TABLE WISHLIST (
    user_id    int,
    game_id    int,
    priority   int DEFAULT 3,
    added_date DATE,
    primary key (user_id, game_id),
    FOREIGN KEY (user_id) references USER(user_id),
    FOREIGN KEY (game_id) references GAME(game_id)
);
select * from WISHLIST;

-- Alter
ALTER TABLE GAME ADD COLUMN price DECIMAL(6,2) DEFAULT 59.99;
select * from GAME;
ALTER TABLE GAME DROP COLUMN price;
select * from GAME;

-- Insert
INSERT INTO USER (user_id, username, email, join_date)
VALUES (9001, 'demo_player', 'demo_player@example.com', '2026-10-01');

INSERT INTO WISHLIST (user_id, game_id, priority, added_date)
VALUES (9001, 2, 1, '2026-10-20');

-- Select
SELECT * FROM USER WHERE user_id = 9001;
SELECT title, developer FROM GAME WHERE developer = 'Valve Software';
SELECT title, release_date FROM GAME ORDER BY release_date;
SELECT * FROM WISHLIST;

-- Update
UPDATE USER SET email = 'new_demo@example.com' WHERE user_id = 9001;
SELECT * FROM USER WHERE user_id = 9001;

-- Delete 
DELETE FROM WISHLIST WHERE user_id = 9001 AND game_id = 2;
SELECT * FROM WISHLIST;

DELETE FROM USER WHERE user_id = 9001;
SELECT * FROM USER WHERE user_id = 9001;

-- Drop
DROP TABLE WISHLIST;
SHOW TABLES;


-- Users with more achievements than average
SELECT u.username, COUNT(un.achievement_id) AS achievements
FROM USER u
JOIN UNLOCKS un ON u.user_id = un.user_id
GROUP BY u.username
HAVING COUNT(un.achievement_id) > (
    SELECT AVG(user_total)
    FROM (SELECT COUNT(*) AS user_total
          FROM UNLOCKS
          GROUP BY user_id) AS totals
)
ORDER BY achievements DESC;

-- Highest rated genre based on user reviews 
SELECT ge.name AS genre,
       COUNT(r.review_id) AS num_reviews,
       ROUND(AVG(r.rating), 2) AS avg_rating
FROM GENRE ge
JOIN BELONGS_TO b ON ge.genre_id = b.genre_id
JOIN REVIEW r ON b.game_id = r.game_id
GROUP BY ge.name
ORDER BY avg_rating DESC;

-- Games on platform
SELECT p.name as platform,
       COUNT(ao.game_id) as num_games
FROM PLATFORM p
LEFT JOIN AVAILABLE_ON ao on p.platform_id = ao.platform_id
GROUP BY p.platform_id, p.name
ORDER BY num_games desc, p.name;
