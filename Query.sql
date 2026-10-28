-- Reset (so the script can be rerun)
DROP TABLE IF EXISTS WISHLIST;
DELETE FROM USER WHERE user_id = 9001;

-- DDL

-- Create
CREATE TABLE WISHLIST (
    user_id    INT,
    game_id    INT,
    priority   INT DEFAULT 3,
    added_date DATE,
    PRIMARY KEY (user_id, game_id),
    FOREIGN KEY (user_id) REFERENCES USER(user_id),
    FOREIGN KEY (game_id) REFERENCES GAME(game_id),
    CONSTRAINT chk_priority CHECK (priority BETWEEN 1 AND 5)
);
DESCRIBE WISHLIST;

-- Alter
ALTER TABLE GAME ADD COLUMN price DECIMAL(6,2) DEFAULT 59.99;
DESCRIBE GAME;
ALTER TABLE GAME DROP COLUMN price;
DESCRIBE GAME;

-- DML

-- Insert
INSERT INTO USER (user_id, username, email, join_date)
VALUES (9001, 'demo_player', 'demo_player@example.com', '2026-10-01');

INSERT INTO WISHLIST (user_id, game_id, priority, added_date)
VALUES (9001, 2, 1, '2026-10-20');

-- Select
SELECT * FROM GAME;
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
