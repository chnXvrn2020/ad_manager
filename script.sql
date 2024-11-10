create table tb_anime
(
    id           integer          not null
        primary key autoincrement,
    name         text             not null,
    storage      integer          not null,
    media        integer          not null,
    studio       text             not null,
    created_date text             not null,
    rip          integer          not null,
    ratio        text             not null,
    episode      integer          not null,
    use_yn       text default 'Y' not null,
    insert_date  text             not null,
    update_date  text,
    delete_date  text
);

create table tb_anime_status
(
    id              integer             not null
        primary key autoincrement,
    anime_id        integer             not null,
    current_episode integer default 1   not null,
    completion_date text,
    status          integer default 2   not null,
    use_yn          text    default 'Y' not null,
    insert_date     text                not null,
    update_date     text,
    delete_date     text
);

create table tb_book
(
    id           integer          not null
        primary key autoincrement,
    type         integer          not null,
    name         text             not null,
    publisher    text             not null,
    created_date text             not null,
    use_yn       text default 'Y' not null,
    insert_date  text             not null,
    update_date  text,
    delete_date  text
);

create table tb_book_status
(
    id              integer          not null
        primary key autoincrement,
    book_id         integer          not null,
    completion_date text,
    status          integer          not null,
    use_yn          text default 'Y' not null,
    insert_date     text             not null,
    update_date     text,
    delete_date     text
);

create table tb_common
(
    id          integer          not null
        primary key autoincrement,
    type        text             not null,
    name        text             not null,
    use_yn      text default 'Y' not null,
    insert_date text             not null,
    update_date text,
    delete_date text
);

create table tb_company
(
    id          integer             not null
        primary key autoincrement,
    type        text                not null,
    name        text                not null,
    parent_id   integer default 0   not null,
    current_yn  text    default 'Y' not null,
    use_yn      text    default 'Y' not null,
    insert_date text                not null,
    update_date text,
    delete_date text
);

create table tb_content
(
    id          integer          not null
        primary key autoincrement,
    name        text             not null,
    use_yn      text default 'Y' not null,
    insert_date text             not null,
    update_date text,
    delete_date text
);

create table tb_files
(
    id          integer          not null
        primary key autoincrement,
    refer_tb    text             not null,
    refer_id    integer          not null,
    file_name   text             not null,
    use_yn      text default 'Y' not null,
    insert_date text             not null,
    update_date text,
    delete_date text
);

create table tb_group
(
    id          integer          not null
        primary key autoincrement,
    original    integer,
    name        text             not null,
    use_yn      text default 'Y' not null,
    insert_date text             not null,
    update_date text,
    delete_date text
);

create table tb_map
(
    id       integer not null
        primary key autoincrement,
    from_tb  text,
    from_id  integer,
    refer_tb text,
    refer_id integer
);


