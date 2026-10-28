drop database if exists GAME_SERVICE;
create database if not exists GAME_SERVICE;

use GAME_SERVICE;

create table USER (
    user_id int PRIMARY KEY,
    username VARCHAR(20),
    email VARCHAR(40),
    join_date DATE
);

create table FOLLOWS (
    user_id_1 INT,
    user_id_2 INT,
    PRIMARY KEY (user_id_1, user_id_2),
    FOREIGN KEY (user_id_1) references user(user_id),
    FOREIGN KEY (user_id_2) references user(user_id)
);

create table GAME (
    game_id int PRIMARY KEY,
    rawg_id int,
    title varchar(200),
    release_date date,
    developer varchar(50)
);

create table REVIEW (
    review_id int PRIMARY KEY,
    rating int,
    review_date date,
    review_text varchar(1000),
    user_id int,
    game_id int,
    FOREIGN KEY (user_id) references user(user_id),
    FOREIGN KEY (game_id) references game(game_id)
);

create table PLATFORM (
    platform_id int PRIMARY KEY,
    name varchar(30)
);

create table ACHIEVEMENT (
    achievement_id int PRIMARY KEY,
    name varchar(30),
    description varchar(500),
    game_id int,
    FOREIGN KEY (game_id) references game(game_id)
);

create table GENRE (
    genre_id int PRIMARY KEY,
    name varchar(50)
);

create table UNLOCKS (
    user_id int,
    achievement_id int,
    PRIMARY KEY(user_id, achievement_id),
    FOREIGN KEY (user_id) references user(user_id),
    FOREIGN KEY (achievement_id) references achievement(achievement_id)
);

create table BELONGS_TO (
    game_id int,
    genre_id int,
    PRIMARY KEY (game_id, genre_id),
    FOREIGN KEY (game_id) references game(game_id),
    FOREIGN KEY (genre_id) references genre(genre_id)
);

create table AVAILABLE_ON (
    game_id int,
    platform_id int,
    PRIMARY KEY (game_id, platform_id),
    FOREIGN KEY (game_id) references game(game_id),
    FOREIGN KEY (platform_id) REFERENCES platform(platform_id)
);